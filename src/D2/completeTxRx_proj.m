% completeTxRx_proj - Script that performs the simulation of the complete communication chain
%
%   This file has no equivalent for TELECOM201/ICS905
%
%   The purpose of this script is to demonstrate a complete wireless
%   communication chain.
%   As provided, the chain is not optimized ; ONE OF THE TARGET OF THE
%   PROJECT IS TO OPTIMIZE THE PARAMETERS OF THE SYSTEM SUBBLOCKS IN ORDER
%   TO MEET THE REQUIREMENTS.
%   Please pay attention to the fact that FIR filters in this script cause 
%   transient phenomena that have not been compensated. 
%   IT IS YOUR DUTY TO FIND THE EXPRESSION OF THE TOTAL DELAY IN "THE
%   ANALOG TO DIGITAL CONVERSION" SECTION TO MATCH THE TRANSMIT AND RECEIVE
%   DATA. (no hardcoding please...)
%   
%   Hopefully, the script has been written to be self-explanatory. 
%
%   In this project, we use the Quadriga Channel Model ("QuaDRiGa") for
%   generating realistic radio channel impulse responses.
%   It is an open source project whose license can be found in the
%   directories of the project. In order to reduce the footprint in terms
%   of disk space, we do not distribute the documentation (PDF) of the
%   QuaDRiGa toolbox included in the original archive distributed on the
%   official site. Please consult the download page and download the
%   archive to retrieve the documentation.
%   https://quadriga-channel-model.de/
%
% Other m-files required:   ./subblocks/*.m
% Subfunctions:             ./subblocks/*.m
% MAT-files required: none
%
% Author: Germain PHAM, Chadi JABBOUR
% C2S, COMELEC, Telecom Paris, Palaiseau, France
% email address: dpham@telecom-paris.fr
% Website: https://c2s.telecom-paristech.fr/TODO
% Feb. 2020, Apr. 2020, Mar. 2022, Dec. 2023
%------------- BEGIN CODE --------------

clear;
close all;
isOctave = exist('OCTAVE_VERSION', 'builtin') ~= 0;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%                   Transmitter                        %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
K   = 1.38e-23; % Boltzmann Constant
T   = 290;      % room temperature
%%% Signal Generation %%%
continuousTimeSamplingRate    = 20e9;     % A sampling rate which is sufficiently high in order to be close to the continous time
basebandSamplingRate_or       = 30e6;     % The sampling rate of the complex baseband signal ; Units : Samples/second
                                          % in this project it MUST BE a multiple of symbolRate

basebandSamplingRate          = continuousTimeSamplingRate/round(continuousTimeSamplingRate/basebandSamplingRate_or);


%%% Signal Characteristics %%%
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

test_type='mod';
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
nBitDAC = 18;           % Number of bits of the DAC
Vref    = 1;            % Voltage reference of the DAC
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
TXBB_Filt_rp    = 0.5;         % Passband ripple in dB
TXBB_Filt_rs    = 40;          % Stopband ripple in dB
TXBB_Filt_fs    = continuousTimeSamplingRate; % Sampling frequency (Hz)
TXBB_Filt_f     = [15 20]*1e6;  % Cutoff frequencies (Hz)
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
Flo      = 2.4e9; % Local Oscillator Frequency
rfSignal = upMixer(basebandAnalog_filt_I,basebandAnalog_filt_Q,Flo,continuousTimeSamplingRate);

P_upMixer = 5 * 10e-12 * Flo;
P_upMixer_total = 2 * P_upMixer;

%%% RF Amplification %%%
PA_mux = 'none'; 

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
      P_cons_PA = 0
end
rfPASignal    = rfPA(rfSignal,PA_Gain,PA_NF,PA_IIP3,Rin,continuousTimeSamplingRate/2);

P_TX_total = P_cons_PA + P_upMixer_total + P_DAC_total;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%                      Channel                        %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%% Channel %%%
carrierFreq        = Flo; % Center frequency of the transmission
c                  = 3e8; % speed of light in vacuum
distance           = 1.4; % Distance between Basestation and UE : [1.4,1.4e3] metres
% Amplitude Attenuation in free space
ChannelAttenuation = (c/carrierFreq./(4*pi*distance))^2; % Free space path loss in terms of power
rxSignal           = rfPASignal*sqrt(ChannelAttenuation);
AntennaNoise       = randn(length(rxSignal),1)*sqrt(K*T*continuousTimeSamplingRate/2*Rin);
rxSignal_WAT       = rxSignal+AntennaNoise;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%                     Receiver                        %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%% LNA %%%
LNA_Gain = 15;   % (dB)
LNA_IIP3 = 100;  % (dBm)
LNA_NF   = 0;    % (dB)
rfLNASignal = rfLNA(rxSignal_WAT,LNA_Gain,LNA_NF,LNA_IIP3,Rin,continuousTimeSamplingRate/2);

P_LNA = 10e-2 / (10^(LNA_NF / 10) - 1);

%%% Mixing down to BB %%%
[basebandAnalog_raw_I,basebandAnalog_raw_Q] = downMixer(rfLNASignal,Flo,continuousTimeSamplingRate);

P_downMixer = 5 * 10e-12 * Flo;
P_downMixer_total = 2 * P_downMixer;

%%% Baseband fake Analog filter %%%
RXBB_Filt_NF    = 0;     %(in dB)

RXBB_Filt_rp    = 0.5;         % Passband ripple in dB
RXBB_Filt_rs    = 40;          % Stopband ripple in dB
RXBB_Filt_fs    = continuousTimeSamplingRate; % Sampling frequency (Hz)
RXBB_Filt_f     = [10 20]*1e6;  % Cutoff frequencies (Hz)
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
BBamp_Gain    = 20; % (dB)
BBamp_IIP3    = 100; % (dBm)
BBamp_NF      = 10; % (dB)
BBamp_band    = 10e6;% (MHz)
basebandAnalog_amp_I = BBamp(basebandAnalog_filtrx_I,BBamp_Gain,BBamp_NF,BBamp_IIP3,Rin,BBamp_band,continuousTimeSamplingRate);
basebandAnalog_amp_Q = BBamp(basebandAnalog_filtrx_Q,BBamp_Gain,BBamp_NF,BBamp_IIP3,Rin,BBamp_band,continuousTimeSamplingRate);

P_BBamp = 10e-9 * BBamp_band;
P_BBamp_total = 2 * P_BBamp;

%%% Analog to Digital Conversion %%%
nBitADC = 18;
delay   = 0; % WARNING : non trivial value !!! to be thoroughly analyzed
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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%            Plot section            %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

window_number       = 1;
lineSpec_index      = 1;
fullband_spectrum   = true;

plot_spectrum(basebandSig,window_number,...
               adcSamplingRate,lineSpec_index,fullband_spectrum);
title('TX Digital Complex recombined signal')

window_number       = window_number+1;
plot_spectrum(basebandComplexDigital,window_number,...
               adcSamplingRate,lineSpec_index,fullband_spectrum);
title('Receiver complex recombined output')

window_number       = window_number+1;
fullband_spectrum   = false;
plot_spectrum(rfPASignal,window_number,...
               continuousTimeSamplingRate,lineSpec_index,fullband_spectrum);
title('PA spectrum')


if strcmp(test_type, 'mod')
   figure()
   subplot(1,2,1)
   plot(qamSig,'d')
   title('constellation at TX')
   subplot(1,2,2)
   plot(basebandComplexDigital_fir_truncated,'d')
   title('constellation at RX')
   % WARNING : the received constellation has almost no sense until filters
   %           delays have been thoroughly analyzed and compensated
end

%------------- END OF CODE --------------
    
