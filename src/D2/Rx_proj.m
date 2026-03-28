function [rx_output, rx_output_truncated, perf_rx] = Rx_proj(simulation_config, rx_config,...
                                                             tx_config, signal_config, channel_output)
Rin = 50; % Ohms
K   = 1.38e-23; % Boltzmann Constant
T   = 290;      % room temperature

continuousTimeSamplingRate    = simulation_config.continuousTimeSamplingRate;     % A sampling rate which is sufficiently high in order to be close to the continous time
basebandSamplingRate_or       = 30e6;     % The sampling rate of the complex baseband signal ; Units : Samples/second
                                          % in this project it MUST BE a multiple of symbolRate

basebandSamplingRate          = continuousTimeSamplingRate/round(continuousTimeSamplingRate/basebandSamplingRate_or);

symbolRate              = 15e6;  % The raw symbol rate : the raw complex QAM symbols are sent at this rate ; Units : Symbols/second
basebandOverSampling    = round(basebandSamplingRate/symbolRate);

%%% Baseband (digital) shaping filter %%%
  rollOff     = 0.25; % (for RRC filter, single sided output BW is (1+beta)*Rsymb/2 )
  symbolSpan  = 25;   % This parameter is related to both the filter length and the attenuation of the stop band
  % Instanciate filter
  basebandRRC = rcosdesign(rollOff,symbolSpan,basebandOverSampling,'sqrt'); 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%                     Receiver                        %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%% LNA %%%
LNA_Gain = rx_config.LNA_Gain;   % (dB)
LNA_IIP3 = rx_config.LNA_IIP3;  % (dBm)
LNA_NF   = rx_config.LNA_NF;    % (dB)
rfLNASignal = rfLNA(channel_output,LNA_Gain,LNA_NF,LNA_IIP3,Rin,continuousTimeSamplingRate/2);

P_LNA = 10e-2 / (10^(LNA_NF / 10) - 1);

%%% Mixing down to BB %%%
Flo = tx_config.Flo;
[basebandAnalog_raw_I,basebandAnalog_raw_Q] = downMixer(rfLNASignal,Flo,continuousTimeSamplingRate);

P_downMixer = 5 * 10e-12 * Flo;
P_downMixer_total = 2 * P_downMixer;

%%% Baseband fake Analog filter %%%
RXBB_Filt_NF    = 0;     %(in dB)

RXBB_Filt_rp    = rx_config.RXBB_Filt_rp;         % Passband ripple in dB
RXBB_Filt_rs    = rx_config.RXBB_Filt_rs;          % Stopband ripple in dB
RXBB_Filt_fs    = continuousTimeSamplingRate; % Sampling frequency (Hz)
RXBB_Filt_f     = rx_config.RXBB_Filt_f;  % Cutoff frequencies (Hz)
RXBB_Filt_a     = [1 0];        % Desired amplitudes
% Convert the deviations to linear units. 
RXBB_Filt_dev   = [(10^(RXBB_Filt_rp/20)-1)/(10^(RXBB_Filt_rp/20)+1) 10^(-RXBB_Filt_rs/20)];
% Design the filter
[RXBB_Filt_n,RXBB_Filt_fo,RXBB_Filt_ao,RXBB_Filt_w] ...
                = firpmord(RXBB_Filt_f,RXBB_Filt_a,RXBB_Filt_dev,RXBB_Filt_fs);
disp('Designing the RX filter - This takes a while...')
RXBB_Filt       = firpm(RXBB_Filt_n,RXBB_Filt_fo,RXBB_Filt_ao,RXBB_Filt_w);

% Perform filtering
disp('Filtering with the RX filter - This takes a while...')
basebandAnalog_filtrx_I = basebandAnalogFiltFake(basebandAnalog_raw_I,RXBB_Filt,RXBB_Filt_NF,Rin,continuousTimeSamplingRate);
basebandAnalog_filtrx_Q = basebandAnalogFiltFake(basebandAnalog_raw_Q,RXBB_Filt,RXBB_Filt_NF,Rin,continuousTimeSamplingRate);


%%% Baseband Gain %%%
BBamp_Gain    = rx_config.BBamp_Gain; % (dB)
BBamp_IIP3    = rx_config.BBamp_IIP3; % (dBm)
BBamp_NF      = rx_config.BBamp_NF; % (dB)
BBamp_band    = rx_config.BBamp_band;% (MHz)
basebandAnalog_amp_I = BBamp(basebandAnalog_filtrx_I,BBamp_Gain,BBamp_NF,BBamp_IIP3,Rin,BBamp_band,continuousTimeSamplingRate);
basebandAnalog_amp_Q = BBamp(basebandAnalog_filtrx_Q,BBamp_Gain,BBamp_NF,BBamp_IIP3,Rin,BBamp_band,continuousTimeSamplingRate);

P_BBamp = 10e-9 * BBamp_band;
P_BBamp_total = 2 * P_BBamp;

%%% Analog to Digital Conversion %%%
nBitADC = rx_config.nBitADC;
Vref = tx_config.Vref;
delay   = rx_config.delayADC; % WARNING : non trivial value !!! to be thoroughly analyzed
adcSamplingRate = basebandSamplingRate;
% Perform conversion
basebandAnalog_adc_I = ADC(basebandAnalog_amp_I,nBitADC,Vref,adcSamplingRate,delay,continuousTimeSamplingRate);
basebandAnalog_adc_Q = ADC(basebandAnalog_amp_Q,nBitADC,Vref,adcSamplingRate,delay,continuousTimeSamplingRate);

P_ADC = 10e-13 * adcSamplingRate * 2^(nBitADC);
P_ADC_total = 2 * P_ADC;

P_RX_total = P_LNA + P_downMixer_total + P_BBamp_total + P_ADC_total;

%%% IQ combination for complex baseband signals %%%
basebandComplexDigital                = complex(basebandAnalog_adc_I,basebandAnalog_adc_Q);

% RX RRC and downsampling (reverse effect of resample(qamSig...) )
% WARNING : this downsampling may create unexpected sampling effects due to butterworth filtering and phase distortion
%           please check signals integrity before and after this step
basebandComplexDigital_fir            = resample(basebandComplexDigital,1,basebandOverSampling,basebandRRC);

% Normalize received symbols to UnitAveragePower (see qammod(inSig)) 
% Trully effective when noise and distortions are not too large compared to the useful signal
basebandComplexDigital_fir            = basebandComplexDigital_fir / sqrt(var(basebandComplexDigital_fir));

% Coarse truncation of the transient parts. 
% This should be optimized with respect to the filters delays. 
basebandComplexDigital_fir_truncated  = basebandComplexDigital_fir(10:end-10);

rx_output = basebandComplexDigital;
rx_output_truncated = basebandComplexDigital_fir_truncated;

perf_rx.power.P_RX_total = P_RX_total;
perf_rx.power.P_LNA = P_LNA;
perf_rx.power.P_BBamp = P_BBamp;
perf_rx.power.P_downMixer = P_downMixer;
perf_rx.power.P_ADC = P_ADC;

function signalPSD = PSD(signal)
  Nsignal = length(signal);
  win     = blackman(Nsignal, 'periodic');
  signalPSD = abs(fft(signal(:).*win(:))).^2;
  signalPSD = signalPSD / Nsignal;
endfunction

%%% Output signal power and SNR 
  if signal_config.test_type == 'mod'
    NBins = length(basebandComplexDigital);
    bin_signal_start = floor(2.385e9/continuousTimeSamplingRate*NBins); 
    bin_signal_end = ceil(2.415e9/continuousTimeSamplingRate*NBins); 
    bin_signal_band = bin_signal_start:bin_signal_end;

    bin_useful_band_start = ceil(2.355e9/continuousTimeSamplingRate*NBins);
    bin_useful_band_end = ceil(2.445e9/continuousTimeSamplingRate*NBins);
    bin_useful_band_band = bin_useful_band_start:bin_useful_band_end;
 
    signal_psd = PSD(basebandComplexDigital);

    signal_power = sum(signal_psd(bin_signal_band));
    noise_power = sum(signal_psd(bin_useful_band_band)) - signal_power;
    SNR = signal_power / noise_power;

    perf_rx.SNR = SNR;
  end;

end;
