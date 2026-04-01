function [signal_out, basebandSig, qamSig, perf_tx] = Tx_proj(simulation_config, tx_config, signal_config)

  isOctave = exist('OCTAVE_VERSION', 'builtin') ~= 0;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%                   Transmitter                        %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  K   = 1.38e-23; % Boltzmann Constant
  T   = 290;      % room temperature

%%% Signal Generation %%%
continuousTimeSamplingRate    = simulation_config.continuousTimeSamplingRate;     % A sampling rate which is sufficiently high in order to be close to the continous time
basebandSamplingRate_or       = 30e6;     % The sampling rate of the complex baseband signal ; Units : Samples/second
                                          % in this project it MUST BE a multiple of symbolRate

basebandSamplingRate          = continuousTimeSamplingRate/round(continuousTimeSamplingRate/basebandSamplingRate_or);

%%% Signal Generation %%%
  symbolRate              = 15e6;  % The raw symbol rate : the raw complex QAM symbols are sent at this rate ; Units : Symbols/second
  basebandOverSampling    = round(basebandSamplingRate/symbolRate);
  NSamples_BB             = 1e3;   % Signal length (after RRC filter)
  
  % Signal frequencies
  freqVin_or1   = 7.12e6;
  freqVin_or2   = 6.12e6;
  % Place the sine waves in an FFT bin
  freqVin1      = round(freqVin_or1/basebandSamplingRate*NSamples_BB)...
                    *basebandSamplingRate/NSamples_BB; 
  freqVin2      = round(freqVin_or2/basebandSamplingRate*NSamples_BB)...
                    *basebandSamplingRate/NSamples_BB; 
  
  % Time vector of the simulation
  t = 0:1/basebandSamplingRate:(NSamples_BB-1)/basebandSamplingRate;

%%% Baseband (digital) shaping filter %%%
  rollOff     = 0.25; % (for RRC filter, single sided output BW is (1+beta)*Rsymb/2 )
  symbolSpan  = 25;   % This parameter is related to both the filter length and the attenuation of the stop band
  % Instanciate filter
  basebandRRC = rcosdesign(rollOff,symbolSpan,basebandOverSampling,'sqrt'); 


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Possible values of test_type are:
%%%%%                               'onetone' for a one-tone sine 
%%%%%                               'twotone' for a two-tone sine 
%%%%%                               'mod'     for a modulated QAM 16 signal
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
qamSig = 0;
  switch signal_config.test_type
     case 'onetone'
        %%% one tone signal%%%
        basebandSig = exp(1j*2*pi*freqVin1*t);
     case 'twotone'
        %%% two tone signal%%%
        basebandSig = exp(1j*2*pi*freqVin1*t)+exp(1j*2*pi*freqVin2*t);
     case 'mod'
        %%% Modulated signal
        modSize       = 16; % Modulation order for 16QAM
        nQAMSymbols   = round(NSamples_BB/basebandOverSampling); % Number of QAM symbols to be generated
        inSig         = randi([0 modSize-1],nQAMSymbols,1);      % generate symbols as integer
        % Perform modulation : convert integer symbols to complex symbols
        if isOctave
           qamSig        = qammod(inSig,modSize);
           qamSig        = qamSig/sqrt(mean(abs(qamSig).^2));
        else % Matlab
           qamSig        = qammod(inSig,modSize,'UnitAveragePower',true);
        end
        

        % Apply filter with upsampling to basebandSamplingRate 
        basebandSig   = resample(qamSig,basebandOverSampling,1,basebandRRC);
        % Resample (compared to upfirdn) generates a signal that is exactly the 
        % length we can predict without having to compensate for the delay introduced by the filter
        % https://groups.google.com/d/msg/comp.soft-sys.matlab/UGLNR9vFqhM/c56ZlfUlhhcJ

     otherwise
        %%% one tone signal%%%
        basebandSig = exp(1j*2*pi*freqVin1*t);
  end

%%% IQ separation for real baseband signals %%%
  [basebandDigital_I_unorm,basebandDigital_Q_unorm] = complx2cart(basebandSig(:));
  %%% Digital to Analog Conversion %%%
  nBitDAC = tx_config.nBitDAC; % Number of bits of the DAC
  Vref    = tx_config.Vref;    % Voltage reference of the DAC
  dacType = 'zoh';        % DAC type ; can be 'zoh' or 'impulse'

  % Normalize signal for conversion
  % Must use same scale factor for both wave (Take max of both)
  normalize_factor    = max( max(abs(basebandDigital_I_unorm)),...
                             max(abs(basebandDigital_Q_unorm)));
  basebandDigital_I   = basebandDigital_I_unorm/normalize_factor*Vref;
  basebandDigital_Q   = basebandDigital_Q_unorm/normalize_factor*Vref;

  % Perform conversion
  basebandAnalog_dac_I = DAC(basebandDigital_I,nBitDAC,Vref,dacType,basebandSamplingRate,continuousTimeSamplingRate);
  basebandAnalog_dac_Q = DAC(basebandDigital_Q,nBitDAC,Vref,dacType,basebandSamplingRate,continuousTimeSamplingRate);

  P_DAC = 10e-13 * basebandSamplingRate * 2^(nBitDAC);
  P_DAC_total = 2 * P_DAC;

%%% Baseband FAKE Analog filter %%%
  Rin             = 50;    % Input impedance of the filter
  TXBB_Filt_NF    = 00;    %(in dB)

  % https://fr.mathworks.com/help/signal/ref/firpmord.html
  TXBB_Filt_rp    = tx_config.TXBB_Filt_rp; % Passband ripple in dB
  TXBB_Filt_rs    = tx_config.TXBB_Filt_rs; % Stopband ripple in dB
  TXBB_Filt_fs    = continuousTimeSamplingRate; % Sampling frequency (Hz)
  TXBB_Filt_f     = tx_config.TXBB_Filt_f; % Cutoff frequencies (Hz)
  TXBB_Filt_a     = [1 0];        % Desired amplitudes
  % Convert the deviations to linear units. 
  TXBB_Filt_dev   = [(10^(TXBB_Filt_rp/20)-1)/(10^(TXBB_Filt_rp/20)+1) 10^(-TXBB_Filt_rs/20)];
  % Design the filter
  [TXBB_Filt_n,TXBB_Filt_fo,TXBB_Filt_ao,TXBB_Filt_w] ...
                  = firpmord(TXBB_Filt_f,TXBB_Filt_a,TXBB_Filt_dev,TXBB_Filt_fs);
  if isOctave
    TXBB_Filt_n = 6511;
  end;
  disp('Designing the TX filter - This takes a while...')
  TXBB_Filt       = firpm(TXBB_Filt_n,TXBB_Filt_fo,TXBB_Filt_ao,TXBB_Filt_w);

  % Perform filtering
  disp('Filtering with the TX filter - This takes a while...')
  basebandAnalog_filt_I = basebandAnalogFiltFake(basebandAnalog_dac_I,TXBB_Filt,TXBB_Filt_NF,Rin,continuousTimeSamplingRate);
  basebandAnalog_filt_Q = basebandAnalogFiltFake(basebandAnalog_dac_Q,TXBB_Filt,TXBB_Filt_NF,Rin,continuousTimeSamplingRate);

%%% Mixing up to RF %%%
  Flo      = tx_config.Flo; % Local Oscillator Frequency
  rfSignal = upMixer(basebandAnalog_filt_I,basebandAnalog_filt_Q,Flo,continuousTimeSamplingRate);

  P_upMixer = 5 * 10e-12 * Flo;
  P_upMixer_total = 2 * P_upMixer;

%%% RF Amplification %%%
  PA_mux = tx_config.PA_mux; 

  switch PA_mux
      case 'ZX60_V63+'
        PA_IIP3       = 30-19.7;      % OIP3 = 31.2 dBm à 2GHz et 28.8 dBm à 3GHz
        PA_NF         = 5.1;      % PA Noise figure ; in dB
        PA_Gain       = 19.7;     % 20.3 dB à 2GHz et 19.2 dB à 3 GHz
        P_cons_PA = 5*69*10^(-3);
      case 'ZX60_V62+'
        PA_IIP3       = 31.9-15.5;      % OIP3 = 33.4 dBm à 2GHz et 30.4 dBm à 3GHz
        PA_NF         = 5.1;      % PA Noise figure ; in dB
        PA_Gain       = 15.5;     % 
        P_cons_PA = 5*82*10^(-3);
      case 'ZHL42'
        PA_IIP3       = 44.85-39.46;      % 
        PA_NF         = 8.07;      % PA Noise figure ; in dB
        PA_Gain       = 39.46;     %
        P_cons_PA = 15*1;
      case 'ADL5606'
        PA_IIP3       = 44.3-21.45;      % 45.5 dBm à 2140MHz et 43.2 dBm à 2630MHz
        PA_NF         = 4.9;      % 4.7dB à 2140MHz et 5.1dB à 2630MHz
        PA_Gain       = 21.45;     % 24.3 dB à 2140MHz et 20.6dB à 2630 MHz
        P_cons_PA = 380*10^(-3) * 5;
      case 'RFLUPA05M06G'
        PA_IIP3       = 43-33;      % 45.5 dBm à 2140MHz et 43.2 dBm à 2630MHz
        PA_NF         = 3;      % 4.7dB à 2140MHz et 5.1dB à 2630MHz
        PA_Gain       = 33;     % 24.3 dB à 2140MHz et 20.6dB à 2630 MHz
        P_cons_PA = 12 * 350 * 10^(-3)
      case 'none'
        PA_IIP3       = 150;      % 45.5 dBm à 2140MHz et 43.2 dBm à 2630MHz
        PA_NF         = 0;      % 4.7dB à 2140MHz et 5.1dB à 2630MHz
        PA_Gain       = 0;     % 24.3 dB à 2140MHz et 20.6dB à 2630 MHz
        P_cons_PA = 0;
  end
  rfPASignal    = rfPA(rfSignal,PA_Gain,PA_NF,PA_IIP3,Rin,continuousTimeSamplingRate/2);

  signal_out = rfPASignal;

  P_TX_total = P_cons_PA + P_upMixer_total + P_DAC_total;

%%% Power Performances
  perf_tx.power.P_TX_total = P_TX_total;
  perf_tx.power.P_cons_PA = P_cons_PA;
  perf_tx.power.P_upMixer = P_upMixer;
  perf_tx.power.P_DAC = P_DAC;

function signalPSD = PSD(signal)
  Nsignal = length(signal);
  win     = blackman(Nsignal);
  U = (1/length(win))*sum(abs(win).^2);
  win = sqrt(1/U)*win/length(win);
  signalPSD = abs(fft(signal(:).*win(:))).^2;
end

%%% Output signal power and ACPR
  if signal_config.test_type == 'mod'
    NBins = length(rfPASignal);
    bin_signal_start = floor(2.385e9/continuousTimeSamplingRate*NBins); 
    bin_signal_end = ceil(2.415e9/continuousTimeSamplingRate*NBins);
    bin_signal_band = bin_signal_start:bin_signal_end;

    bin_sideband_sup_end = ceil(2.445e9/continuousTimeSamplingRate*NBins);
    bin_sideband_sup_band = bin_signal_start:bin_sideband_sup_end;
 
    signal_psd = PSD(rfPASignal) * 2 * (continuousTimeSamplingRate/NBins);

    signal_psd(round((bin_signal_start + bin_signal_end)/2))

    signal_power = sum(signal_psd(bin_signal_band));
    sideband_sup_power = sum(signal_psd(bin_sideband_sup_band)) - signal_power;
    ACPR = signal_power / sideband_sup_power;

    perf_tx.acpr = ACPR;
    perf_tx.signal_power = signal_power;
  end

end
