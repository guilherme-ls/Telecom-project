clear;
close all;

%%% Simulation Params %%%
simulation_config.continuousTimeSamplingRate = 19.968e9;
simulation_config.basebandSamplingRate = 30.72e6;
simulation_config.symbolRate = 15.36e6;

%%% Signal Params %%%
signal_config.test_type = 'onetone';

%%% TX Params %%%
%%%%% DAC %%%%
tx_config.nBitDAC = 10; % Number of bits of the DAC
tx_config.Vref = 1;     % Voltage reference of the DAC
%%%%% Filter %%%%
tx_config.TXBB_Filt_rp = 0.5; % Passband ripple in dB
tx_config.TXBB_Filt_rs = 40; % Stopband ripple in dB
tx_config.TXBB_Filt_f = [10 15]*1e6; % Cutoff frequencies (Hz) 0.5;        
%%%%% Up Mixer %%%%
tx_config.Flo  = 2.4e9;
%%%%% PA %%%%                                             
tx_config.PA_mux = 'ADL5606'; % PA Model 
tx_config.attenuation = -10.9; % -6.4; %  (dB) Preattenuation before PA
                                                    
%%% Channel Params %%%
channel_config.distance = 1.400;

%%% RX Params %%%
%%%%% LNA  %%%%
rx_config.LNA_Gain = 15;  % (dB)
rx_config.LNA_IIP3 = 0; % (dBm)
rx_config.LNA_NF   = 5.4;   % (dB)
%%%%% RXBB %%%%
rx_config.Flo  = 2.4e9;
rx_config.RXBB_Filt_rp = 0.5;
rx_config.RXBB_Filt_rs = 40;
rx_config.RXBB_Filt_f = [10 15]*1e6;
%%%%% BBAmp %%%%
rx_config.BBamp_Gain = 23.5; % (dB)
rx_config.BBamp_IIP3 = 100; % (dBm)
rx_config.BBamp_NF   = 10; % (dB)
rx_config.BBamp_band = 10e6; % (MHz)
%%%%% ADC %%%%
rx_config.nBitADC = 12;
rx_config.delayADC = 0;
rx_config.Vref = 1;

%%% Communication Chain %%%

[tx_output, tx_input, tx_qam_input, perf_tx] = Tx_proj(simulation_config, tx_config, signal_config);
rx_config.delayADC = perf_tx.TXBB_Filt_n;
channel_output = Channel_proj(simulation_config, tx_config, tx_output, channel_config.distance);
[rx_output, rx_output_truncated, perf_rx] = Rx_proj(simulation_config, rx_config, signal_config, channel_output);
    
basebandSamplingRate          = simulation_config.basebandSamplingRate;

%%% Plotting %%%
Rin = 50;
voltsq2mwatt    = 1e3/Rin; % Conversion factor from V^2 to milliWatt
window_number       = 1;
lineSpec_index      = 1;
fullband_spectrum   = true;

figure(window_number)
subplot(2,2,1);
plot_spectrum(tx_input*sqrt(voltsq2mwatt), window_number,...
               basebandSamplingRate,lineSpec_index, fullband_spectrum);
title('TX signal')
xlabel('frequency (Hz)')
ylabel('PSD (dBm/bin)')

subplot(2,2,2);
plot_spectrum(tx_output*sqrt(voltsq2mwatt), window_number, ...
              simulation_config.continuousTimeSamplingRate, 1, false);
title('TX Output')
xlabel('frequency (Hz)')
ylabel('PSD (dBm/bin)')

subplot(2,2,3);
plot_spectrum(channel_output*sqrt(voltsq2mwatt), window_number, ...
              simulation_config.continuousTimeSamplingRate, 1, false);
title('RX Input')
xlabel('frequency (Hz)')
ylabel('PSD (dBm/bin)')

subplot(2,2,4);
plot_spectrum(rx_output*sqrt(voltsq2mwatt),window_number,...
               basebandSamplingRate,lineSpec_index, true);
title('Receiver complex recombined output')
xlabel('frequency (Hz)')
ylabel('PSD (dBm/bin)')

disp(['Signal power (digital out): ', num2str(perf_rx.signal_power), ' mW or ', num2str(10*log10(perf_rx.signal_power)), ' dBm.'])
disp(['SNR: ', num2str(perf_rx.snr), ' dB.'])

if strcmp(signal_config.test_type, 'mod')
    disp(['Signal power (sent): ', num2str(perf_tx.signal_power), ' mW or ', num2str(10*log10(perf_tx.signal_power)), ' dBm.'])
    % WARNING : the received constellation has almost no sense until filters
    %           delays have been thoroughly analyzed and compensated

    sync_offset = finddelay(tx_qam_input, rx_output_truncated);
    
    % 2. Shift the arrays to align their starting points
    if sync_offset > 0
        % RX is delayed. Skip the leading samples of RX.
        rx_aligned = rx_output_truncated(sync_offset + 1 : end);
        tx_aligned = tx_qam_input;
    elseif sync_offset < 0
        % RX was over-truncated. Skip the leading samples of TX.
        tx_aligned = tx_qam_input(abs(sync_offset) + 1 : end);
        rx_aligned = rx_output_truncated;
    else
        % Start points are perfectly aligned
        tx_aligned = tx_qam_input;
        rx_aligned = rx_output_truncated;
    end
    
    % 3. Trim the tails so both arrays are exactly the same length
    num_symbols = min(length(tx_aligned), length(rx_aligned));
    tx_aligned  = tx_aligned(1:num_symbols);
    rx_aligned  = rx_aligned(1:num_symbols);
    
    % Demodulate 16-QAM symbols
    if exist('OCTAVE_VERSION', 'builtin') ~= 0
        % Octave: scale back up by the variance before demodulating
        scale_factor = sqrt(mean(abs(tx_qam_input).^2));
        tx_ints = qamdemod(tx_aligned * scale_factor, 16);
        rx_ints = qamdemod(rx_aligned * scale_factor, 16);
    else
        % MATLAB: Use the UnitAveragePower flag to match the TX modulation
        tx_ints = qamdemod(tx_aligned, 16, 'UnitAveragePower', true);
        rx_ints = qamdemod(rx_aligned, 16, 'UnitAveragePower', true);
    end
    
    % Calculates SER
    [num_sym_errors, SER] = symerr(tx_ints, rx_ints);
    
    % de2bi converts column vectors of integers into a matrix of bits
    tx_bits = de2bi(tx_ints, 4);
    rx_bits = de2bi(rx_ints, 4);
    
    % 4. Compare the bit matrices to find errors
    [num_errors, BER] = biterr(tx_bits, rx_bits);
    
    disp(['Total Bits Analyzed: ', num2str(numel(tx_bits))])
    disp(['Bit Errors Found: ', num2str(num_errors)])
    disp(['Bit Error Rate (BER): ', num2str(BER)])
    disp(['Symbol Errors Found: ', num2str(num_sym_errors)])
    disp(['Symbol Error Rate (SER): ', num2str(SER)])

    figure()
    subplot(1,2,1)
    plot(tx_qam_input,'d')
    title('constellation at TX')
    subplot(1,2,2)
    plot(rx_output_truncated,'d')
    title('constellation at RX')
end

%%% Performances %%%
