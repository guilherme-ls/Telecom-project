close all;
clear;

% System properties
Rin = 50;       % Matching impedance chosen equal to 50

%%% Signal Generation %%%
continuousTimeSamplingRate      = 19.968e9; % A sampling rate which is sufficiently high in order to be close to the continous time
basebandSamplingRate            = 30.72e6;     % The sampling rate of the complex baseband signal. In this project it MUST BE a multiple of symbolRate

%%% Signal Generation %%%
symbolRate              = 15.36e6;  % The raw symbol rate : the raw complex QAM symbols are sent at this rate ; Units : Symbols/second
basebandOverSampling    = round(basebandSamplingRate/symbolRate);
NSamples_BB             = 2^13;   % Signal length (after RRC filter)

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
test_type = 'mod';
switch test_type
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
        %rng(0);
        inSig         = randi([0 modSize-1],nQAMSymbols,1);      % generate symbols as integer
        % Perform modulation : convert integer symbols to complex symbols
        qamSig        = qammod(inSig,modSize,'UnitAveragePower',true);
        % Apply filter with upsampling to basebandSamplingRate 
        basebandSig   = resample(qamSig,basebandOverSampling,1,basebandRRC);
        % Resample (compared to upfirdn) generates a signal that is exactly the 
        % length we can predict without having to compensate for the delay introduced by the filter
        % https://groups.google.com/d/msg/comp.soft-sys.matlab/UGLNR9vFqhM/c56ZlfUlhhcJ
        
    otherwise
        %%% one tone signal%%%
        basebandSig = exp(1j*2*pi*freqVin1*t);
end

%%% Digital to Analog Conversion %%%
nBitDAC = 7; % Number of bits of the DAC
Vref    = 1;    % Voltage reference of the DAC
dacType = 'zoh';        % DAC type ; can be 'zoh' or 'impulse'

%%% IQ separation for real baseband signals %%%
[basebandDigital_I_unorm,basebandDigital_Q_unorm] = complx2cart(basebandSig(:));

% Normalize signal for conversion
% Must use same scale factor for both wave (Take max of both)
normalize_factor    = max(max(abs(basebandDigital_I_unorm)), max(abs(basebandDigital_Q_unorm)));
basebandDigital_I   = basebandDigital_I_unorm/normalize_factor*Vref;
basebandDigital_Q   = basebandDigital_Q_unorm/normalize_factor*Vref;

function signalPSD = PSD(signal)
    Nsignal = length(signal);
    win     = blackman(Nsignal);
    U       = (1/length(win))*sum(abs(win).^2);
    win     = sqrt(1/U)*win/length(win);
    signalPSD = fftshift(abs(fft(signal.*win)).^2);
end

% Perform conversion
nbits = 4:14;
ACPRs = zeros(1,length(nbits));
for i = 1:length(nbits)
    nBitDAC = nbits(i);
    basebandAnalog_dac_I = DAC(basebandDigital_I,nBitDAC,Vref,dacType,basebandSamplingRate,continuousTimeSamplingRate);
    basebandAnalog_dac_Q = DAC(basebandDigital_Q,nBitDAC,Vref,dacType,basebandSamplingRate,continuousTimeSamplingRate);
    
    BW = 15e6;
    NBins = length(basebandAnalog_dac_I);
    bin_signal_start = floor(-BW/continuousTimeSamplingRate*NBins); 
    bin_signal_end = ceil(BW/continuousTimeSamplingRate*NBins);
    bin_signal_band = (NBins/2 + bin_signal_start):(NBins/2 + bin_signal_end);
    
    bin_sideband_sup_end = ceil(BW*3/continuousTimeSamplingRate*NBins);
    bin_sideband_sup_band = (NBins/2 + bin_signal_end):(NBins/2 + bin_sideband_sup_end);
    
    bin_sideband_inf_start = floor(-BW*3/continuousTimeSamplingRate*NBins);
    bin_sideband_inf_band = (NBins/2 + bin_sideband_inf_start):(NBins/2 + bin_signal_start);
    
    voltsq2mwatt    = 1e3/Rin;
    signal_psd = PSD(basebandAnalog_dac_I*sqrt(voltsq2mwatt));
    
    signal_power = sum(signal_psd(bin_signal_band)) * 2;
    sideband_sup_power = sum(signal_psd(bin_sideband_sup_band)) * 2;
    sideband_inf_power = sum(signal_psd(bin_sideband_inf_band)) * 2;
    ACPR = ((sideband_sup_power + sideband_inf_power) / 2) / signal_power;
    ACPRs(i) = 10*log10(ACPR);
end

plot(nbits, ACPRs, '-o')
title('DAC ACPR per Number of Bits')
xlabel('Number of bits')
ylabel('ACPR (dB)')
grid()

disp(10*log10(ACPR));

%plot_spectrum(basebandAnalog_dac_I,1,continuousTimeSamplingRate,1,true);




