close all;
clear;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%          Transmission Configurations                %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%% General Config %%%%%
pluto_configs.general.device_name = "Pluto";
pluto_configs.general.center_freq = 2.4e9; % Hz 
pluto_configs.general.bb_sample_rate = 30.72e6;  % Hz
pluto_configs.general.filt_rf_bw = 20e6; % Hz

%%%%% Sync Config %%%%%
pluto_configs.sync.enable = true;
pluto_configs.sync.size = 1000;
pluto_configs.sync.tolerance = 0.5;
pluto_configs.sync.preamble.size = 1000;
pluto_configs.sync.epilogue.size = 1000;

%%%%% TX Config %%%%% 
pluto_configs.tx.enable = true;  
pluto_configs.tx.automatic_emmision = true;
pluto_configs.tx.gain = -10; % dB 
pluto_configs.tx.dac.scale_factor = 0.75; % [0, 1]

%%%%% RX Config %%%%% 
pluto_configs.rx.enable = false;
pluto_configs.rx.automatic_reception = true;  
pluto_configs.rx.gain.manual = true;
pluto_configs.rx.gain.value = 40;
pluto_configs.rx.bb_rrc.roll_off = 0.25;
pluto_configs.rx.bb_rrc.symbol_span = 25;

%%%%% Signal Config %%%%% 

% Raw Signal Config
pluto_configs.signal.raw.enable = true;
pluto_configs.signal.raw.harmonics.frequencies = [6.12e6];
pluto_configs.signal.raw.harmonics.width = 0.07e6;
pluto_configs.signal.raw.usable_band = 0.15e6;
pluto_configs.signal.raw.harmonics.samples = 1e5; % Samples

% Modulated Message Config
pluto_configs.signal.modulated.enable = false;
pluto_configs.signal.modulated.symbol_rate = 3e6;
pluto_configs.signal.modulated.modulation.mod = "QAM";  
pluto_configs.signal.modulated.modulation.size = 16;  

% Modulated Message Generation
signal_generation_seed = 100;
signal_length = 100e3;

rand_message_range = [0 pluto_configs.signal.modulated.modulation.size-1];

rng(signal_generation_seed);
rand_message = randi(rand_message_range, signal_length, 1);

pluto_configs.signal.modulated.message = rand_message;

%%%%% Plot Config %%%%% 
pluto_configs.plot.spectrum = true;
pluto_configs.plot.sync = false;

%%%%% Perfomances Display Config %%%%% 
pluto_configs.performace.snr = true;
pluto_configs.performace.ser = false;
pluto_configs.performace.ber = false;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%                SDR Configuration                    %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if pluto_configs.tx.enable 
  tx_sdr = sdrtx(pluto_configs.general.device_name);
  %%%% General SDR Configuration %%%%
  tx_sdr.BasebandSampleRate = pluto_configs.general.bb_sample_rate;
  tx_sdr.CenterFrequency = pluto_configs.general.center_freq;
  tx_sdr.filtRFBandwidth = pluto_configs.general.filt_rf_bw;
  %%%% TX SDR Configuration %%%%
  tx_sdr.Gain = pluto_configs.tx.gain;
end

if pluto_configs.rx.enable 
  rx_sdr = sdrrx(pluto_configs.general.device_name);
  %%%% General SDR Configuration %%%%
  rx_sdr.BasebandSampleRate = pluto_configs.general.bb_sample_rate;
  rx_sdr.CenterFrequency = pluto_configs.general.center_freq;
  rx_sdr.filtRFBandwidth = pluto_configs.general.filt_rf_bw;
  %%%% RX SDR Configuration %%%%
  if pluto_configs.rx.gain.manual
    rx_sdr.GainSource = "manual";
    rx_sdr.Gain = pluto_configs.rx.gain.value;
  end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%                Transmission Chain Setup             %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if pluto_configs.tx.enable 
  disp("TX Enabled! Setting up signal to send...");
  %%%% Signal Preparation
  if pluto_configs.signal.raw.enable
    disp("Sending Harmonics Signal...");
    time_vec = 0:1/pluto_configs.general.bb_sample_rate:(pluto_configs.signal.raw.harmonics.samples-1)/pluto_configs.general.bb_sample_rate;
    harmonics = pluto_configs.signal.raw.harmonics.frequencies;
    bined_harmonics = round((harmonics/pluto_configs.general.bb_sample_rate) * pluto_configs.signal.raw.harmonics.samples)...
                             *pluto_configs.general.bb_sample_rate / pluto_configs.signal.raw.harmonics.samples;
    tx_signal = sum(exp(1j*2*pi*bined_harmonics.*time_vec(:)), 2); 

  elseif pluto_configs.signal.modulated.enable
    disp("Sending Modulated Signal...");
    if strcmpi(pluto_configs.signal.modulated.modulation.mod, "QAM")
      disp("QAM Modulation Selected...");
      qam_symbols = qammod(pluto_configs.signal.modulated.message, ...
                           pluto_configs.signal.modulated.modulation.size, ...
                           "UnitAveragePower", true);
      bb_over_sampling = round(pluto_configs.general.bb_sample_rate ...
                               / pluto_configs.signal.modulated.symbol_rate);
      %%% Oversampling with the RRC filter
      bb_rrc = rcosdesign(pluto_configs.rx.bb_rrc.roll_off, ...
                          pluto_configs.rx.bb_rrc.symbol_span, ...
                          bb_over_sampling, "sqrt");

      tx_signal = resample(qam_symbols, bb_over_sampling, 1, bb_rrc);
    else
      disp("No valid modulation selected! Releasing tx_sdr early!");
      disp("Make sure you have correctly configured the Signal!");
      release(tx_sdr);
      disp("Aborting...");
      assert(0);
    end
  else
    disp("No signal selected! Releasing tx_sdr early!");
    disp("Make sure you have correctly configured the TX!");
    release(tx_sdr);
    disp("Aborting...");
    assert(0);
  end
  %%%% Clock Synchronization Section
  if pluto_configs.sync.enable 
    disp("Syncing enabled, configuring TX side...");
    sync_section = [zeros(pluto_configs.sync.preamble.size, 1);...
                     ones(pluto_configs.sync.size, 1);...
                    zeros(pluto_configs.sync.epilogue.size, 1)];
    %%%% Synchronization infront of the tx signal
    tx_signal = [sync_section; tx_signal];
  end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%                Reception Chain Setup                %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if pluto_configs.rx.enable 
  disp("RX Enabled! Setting up for signal reception...");
  %%%% Signal Preparation
  if pluto_configs.signal.raw.enable
    disp("Harmonic signal...");
    disp("Setting up amount of samples to collect...");
    rx_n_samples = 2 * pluto_configs.signal.raw.harmonics.samples;
  elseif pluto_configs.signal.modulated.enable
    disp("Sending Modulated Signal...");
    if strcmpi(pluto_configs.signal.modulated.modulation.mod, "QAM")
      disp("QAM Modulation Selected...");
      bb_over_sampling = round(pluto_configs.general.bb_sample_rate ...
                               / pluto_configs.signal.modulated.symbol_rate);
      disp("Setting up amount of samples to collect...");
      rx_n_samples = 2 * bb_over_sampling * length(pluto_configs.signal.modulated.message);

      disp("Preparing RRC Filter...");
      rx_bb_rrc = rcosdesign(pluto_configs.rx.bb_rrc.roll_off, ...
                             pluto_configs.rx.bb_rrc.symbol_span, ...
                             bb_over_sampling, "sqrt");
    else
      disp("No valid modulation selected! Releasing rx_sdr early!");
      disp("Make sure you have correctly configured the Signal!");
      release(rx_sdr);
      if pluto_configs.tx.enable 
        release(tx_sdr);
      end
      disp("Aborting...");
      assert(0);
    end
  else
    disp("No signal selected! Releasing rx_sdr early!");
    disp("Make sure you have correctly configured the RX!");
    release(rx_sdr);
    if pluto_configs.tx.enable 
      release(tx_sdr);
    end
    disp("Aborting...");
    assert(0);
  end
  %%%% Clock Synchronization Section
  if pluto_configs.sync.enable 
    disp("Syncing enabled, adding the synchronization section samples to collect...");
    rx_n_samples = rx_n_samples + 2 * (pluto_configs.sync.preamble.size ...
                                    +  pluto_configs.sync.size ...
                                    +  pluto_configs.sync.epilogue.size);
  end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%                Transmission and Reception           %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if pluto_configs.tx.enable 
  %%%% Wait for User Input
  if ~pluto_configs.tx.automatic_emmision
    while true
      input_str = input("Start Transmission? (y/n): ", 's');
      if strcmpi(input_str, 'y')
        break;
      end
    end
  end

  %%%%% Send on repeat the signal
  disp("Transmitting message on loop...");
  tx_sdr.transmitRepeat(tx_signal*pluto_configs.tx.dac.scale_factor);
end

if pluto_configs.rx.enable 
  %%%% Wait for User Input
  if ~pluto_configs.rx.automatic_reception
    while true
      input_str = input("Start Reception? (y/n): ", 's');
      if strcmpi(input_str, 'y')
        break;
      end
    end
  end

  %%%%% Receive the message 
  disp("Receiving message...");
  rx_signal = double(rx_sdr.capture(rx_n_samples));
  disp("Message received!");
  %% Normalizing the received signal for better treatment
  rx_signal_rsm_norm =  rx_signal / sqrt(var(rx_signal));
  %% Truncating so it matches the sent signal in size
  rx_signal_truncated = rx_signal_rsm_norm(1:rx_n_samples/2);

  %%%% RX Signal Synchronization
  if pluto_configs.sync.enable
    disp("Synchronizing samples...");
    sync_section = [zeros(pluto_configs.sync.preamble.size, 1);...
                     ones(pluto_configs.sync.size, 1);...
                    zeros(pluto_configs.sync.epilogue.size, 1)];
    %%%% Alignment based on the synchronization section
    [sync_start, sync_end, ~] = findsignal(abs(rx_signal_rsm_norm(1:length(rx_signal_rsm_norm)/2)), ...
                                             sync_section, ...
                                             "Normalization", "power", ...
                                             "Metric", "symmkl");
    if pluto_configs.plot.sync
        figure();
        findsignal(abs(rx_signal_rsm_norm(1:length(rx_signal_rsm_norm)/2)), ...
                                          sync_section, ...
                                          "Normalization", "power", ...
                                          "Metric", "symmkl");
    end
    disp("Found synchronization section, alligning...");
    %%%% Get the first sync_section and use its end as the start of the sent message 
    sync_start = sync_start(1);
    sync_end = sync_end(1);    
    rx_signal_synced = rx_signal_rsm_norm(sync_end:end);
    %%%% From the sync_section, get the part where it is all ones, and see how much of the phase 
    %%%% has changed
    disp("Getting phase shift in synchronization section for correction...");
    phase_sync_section = rx_signal_rsm_norm(sync_start:sync_end);
    phase_sync_section = phase_sync_section(abs(phase_sync_section) > pluto_configs.sync.tolerance);
    phase_sync = mean(angle(phase_sync_section));
    %%%% Truncate the aligned version of the rx signal, removing the synchronization section 
    %%%% and adjusting the phase based on the sync section
    disp("Truncating and fixing phase shift...");
    samples_in_message = rx_n_samples/2 - length(sync_section);
    rx_signal_truncated = rx_signal_synced(1:samples_in_message)*exp(-1j*phase_sync);
  end

  %%%% RX Demodulation 
  if pluto_configs.signal.modulated.enable 
    disp("Finding best delay on samples for demodulation...");

    %%%% Generation of the  constellation_points of the modulation for
    %%%% optimisation metrics
    if strcmpi(pluto_configs.signal.modulated.modulation.mod, "QAM")
      constellation_points = qammod(0:pluto_configs.signal.modulated.modulation.size-1, ...
                                    pluto_configs.signal.modulated.modulation.size, ...
                                    "UnitAveragePower", true)';
      constellation_points_vec = [real(constellation_points), imag(constellation_points)];
    end
    %%%%% Attempts to fix the delay for the symbols
    distance_metrics = zeros(bb_over_sampling-1, 1);
    rx_signals_downsampled = zeros(bb_over_sampling-1, round(length(rx_signal_truncated)/bb_over_sampling));
    %%%%% Create the symbol synchronizer object 
    symbolSyncer = comm.SymbolSynchronizer( ...
                   SamplesPerSymbol=bb_over_sampling, ...
                   NormalizedLoopBandwidth=0.01, ...
                   DampingFactor=1.0, ...
                   TimingErrorDetector='Early-Late (non-data-aided)');
    for downsamp_begin = 1:bb_over_sampling-1
      
      %%%% Downsampling with RRC Filter
      rx_signal_downsampled = resample(rx_signal_truncated(downsamp_begin:end), 1, ...
                                                        bb_over_sampling, rx_bb_rrc); 
      %%%% Sample normalization after filter
      rx_signal_downsampled = rx_signal_downsampled / sqrt(var(rx_signal_downsampled));
    
      %%%% Account for symbol timing clock skewing
      rx_signal_downsampled_synced = symbolSyncer(rx_signal_downsampled);

      disp("Finding best delay on samples for demodulation...");
      %%% From the constellation_points, find the closest position of each
      %%% constellation point, and get the variance of the distances
      rx_signal_downsampled_vec = [real(rx_signal_downsampled_synced), ...
                                   imag(rx_signal_downsampled_synced)];
      [~, distances_from_constellation_point] = knnsearch(constellation_points_vec, ...
                                                          rx_signal_downsampled_vec);
      rx_signals_downsampled(downsamp_begin, :) = rx_signal_downsampled_synced;
      distance_metrics(downsamp_begin) = var(distances_from_constellation_point);      
    end
    %%% Get the best delay downsampled signal based on the kmeans metric
    [~, best_delay] = min(distance_metrics);
    rx_signal_downsampled = rx_signals_downsampled(best_delay, :);
    %%%% Message Demodulation
    disp("Constelation demodulation...");
    if strcmpi(pluto_configs.signal.modulated.modulation.mod, "QAM")
      disp("QAM Demodulation...");
      rx_message = qamdemod(rx_signal_downsampled, ...
                            pluto_configs.signal.modulated.modulation.size, ...
                            "UnitAveragePower", true);
    else
      disp("What?! How did the modulation become invalid?");
      assert(0);
    end
  end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%                Data Plots                           %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if pluto_configs.plot.spectrum
  window_number       = 1;
  lineSpec_index      = 1;
  fullband_spectrum   = true;

  if pluto_configs.tx.enable 
    tx_signal_plot = tx_signal;
    if pluto_configs.sync.enable
        tx_signal_plot = tx_signal_plot(length(sync_section):end);
    end
    plot_spectrum(tx_signal_plot, window_number,...
               pluto_configs.general.bb_sample_rate, lineSpec_index, fullband_spectrum);
    title('TX Digital Complex recombined signal')

    window_number       = window_number+1;
  end

  if pluto_configs.rx.enable 
    plot_spectrum(rx_signal_truncated, window_number,...
               pluto_configs.general.bb_sample_rate, lineSpec_index, fullband_spectrum);
    title('Receiver complex recombined output')
  end
elseif pluto_configs.tx.enable || pluto_configs.rx.enable 
  figure();
  if pluto_configs.tx.enable 
    subplot(3,1,1);
    tx_signal_plot = tx_signal;
    if pluto_configs.sync.enable
        tx_signal_plot = tx_signal_plot(length(sync_section):end);
    end
    plot(abs(tx_signal_plot));
  end
  if pluto_configs.rx.enable
    subplot(3,1,2);
    plot(abs(rx_signal_rsm_norm));
    subplot(3,1,3);
    plot(abs(rx_signal_truncated));
  end
  title('Aligned signals');
  xlabel('Sample index');
  ylabel('Signal envelope');
end


if pluto_configs.rx.enable 
  if pluto_configs.signal.modulated.enable
    figure();
    if pluto_configs.tx.enable
      subplot(1,2,1);
      plot(qam_symbols,'d');
      title("Constellation at TX");
    end
    subplot(1,2,2);
    plot(rx_signal_downsampled, 'd');
    title("Constellation at RX");
  end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%                Performances                         %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if pluto_configs.performace.snr && pluto_configs.rx.enable
  if pluto_configs.signal.raw.enable
    
    harmonics = pluto_configs.signal.raw.harmonics.frequencies;
    bined_harmonics = round((harmonics/pluto_configs.general.bb_sample_rate) * pluto_configs.signal.raw.harmonics.samples)...
                             *pluto_configs.general.bb_sample_rate / pluto_configs.signal.raw.harmonics.samples;
    if length(bined_harmonics) > 1
        disp("SNR for raw signal is only supported for a single harmonic");
        assert(0);
    end
    rx_signal_bin = round((bined_harmonics/pluto_configs.general.bb_sample_rate) * pluto_configs.signal.raw.harmonics.samples);
    rx_signal_bandwidth = round((pluto_configs.signal.raw.harmonics.width/pluto_configs.general.bb_sample_rate) * pluto_configs.signal.raw.harmonics.samples);
    rx_usable_bandwidth = round((pluto_configs.signal.raw.usable_band/pluto_configs.general.bb_sample_rate) * pluto_configs.signal.raw.harmonics.samples);
    
    rx_signal_band = rx_signal_bin-rx_signal_bandwidth/2:rx_signal_bin+rx_signal_bandwidth/2;
    rx_usable_band = rx_signal_bin-rx_usable_bandwidth/2:rx_signal_bin+rx_usable_bandwidth/2;
    rx_signal_psd = PSD(rx_signal_truncated);
    rx_signal_power = sum(rx_signal_psd(rx_signal_band));
    rx_noise_power = sum(rx_signal_psd(rx_usable_band)) - rx_signal_power;
    rx_snr = rx_signal_power / rx_noise_power;
    rx_snr_db = 10*log10(rx_snr);
    fprintf("SNR = %.2f (dB)\n", rx_snr_db);
  end
end

if (pluto_configs.performace.ser || pluto_configs.performace.ber) ...
   && pluto_configs.rx.enable && pluto_configs.tx.enable
  if pluto_configs.signal.modulated.enable
      symbol_diff = sum(rx_message ~= pluto_configs.signal.modulated.message');
      rx_ser = symbol_diff / length(rx_message);
      if pluto_configs.performace.ser
        fprintf("SER = %.2f\n", rx_ser);
      end
      bits_per_symbol = log2(pluto_configs.signal.modulated.modulation.size);
      rx_message_bin = dec2bin(rx_message, bits_per_symbol);
      tx_message_bin = dec2bin(pluto_configs.signal.modulated.message', bits_per_symbol);

      bit_diff = sum(rx_message_bin ~= tx_message_bin, "all");
      rx_ber = bit_diff / (length(rx_message_bin) * bits_per_symbol);
      if pluto_configs.performace.ber
        fprintf("BER = %.2f\n", rx_ber);
      end

  end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%                     Cleanup                         %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if pluto_configs.tx.enable 
  %%%% Wait for User Input
  if ~pluto_configs.rx.enable
    while true
      input_str = input("Stop Transmission? (y/n): ", 's');
      if strcmpi(input_str, 'y') 
        break;
      end
    end
  end
end

if pluto_configs.tx.enable 
  disp("Stopping Transmission...");
  disp("Releasing TX...");
  release(tx_sdr);
end

if pluto_configs.rx.enable 
  disp("Releasing RX...");
  release(rx_sdr);
end

function signalPSD = PSD(signal)
  Nsignal = length(signal);
  win     = blackman(Nsignal);
  U = (1/length(win))*sum(abs(win).^2);
  win = sqrt(1/U)*win/length(win);
  signalPSD = abs(fft(signal(:).*win(:))).^2;
end
