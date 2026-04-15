% ADALM_Pluto_Tx - Script that performs a TX wireless communication chain
%
% [Note to instructors] This file has no equivalent for TELECOM201/ICS905
%
% Purpose:
%   Small, self-contained transmitter chain demonstrating baseband signal
%   generation, pulse shaping and transmission via the ADALM‑Pluto SDR.
% 
% Usage:
%   Configure test_type and signal parameters below to generate a one‑tone,
%   two‑tone or QAM modulated waveform and transmit it with sdrtx('Pluto').
%   Use a TinySA or similar spectrum analyzer to observe the transmitted signal
%   and verify its characteristics.
% 
% Requirements:
%   - MATLAB with Communications System Toolbox
%   - ADALM‑Pluto Support Package
% 
% Notes:
%   As provided, the chain is not optimized ; ONE OF THE TARGET OF THE
%   PROJECT IS TO EXPLORE THE PARAMETERS OF THE SYSTEM IN ORDER
%   TO MAXIMIZE THE PERFORMANCE OF THE TRANSMISSION.
%
%
% Other m-files required:   ./subblocks/*.m
% Subfunctions:             ./subblocks/*.m
% MAT-files required: none
%
% Author: Germain PHAM, Chadi JABBOUR
% C2S, COMELEC, Telecom Paris, Palaiseau, France
% email address: dpham@telecom-paris.fr
% Website: https://c2s.telecom-paristech.fr/TODO
% Fev. 2026
%------------- BEGIN CODE --------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%                  Transmitter                        %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%% Signal Generation %%%
basebandSamplingRate    = 30.72e6;

%%% Signal Characteristics %%%
symbolRate              = 3e6;  % The raw symbol rate : the raw complex QAM symbols are sent at this rate ; Units : Symbols/second
basebandOverSampling    = round(basebandSamplingRate/symbolRate);
NSamples_BB             = 100e3;   % Signal length (after RRC filter)

% Signal frequencies
freqVin_or1   = 7.12e6;
freqVin_or2   = 6.12e6;
% Place the sine waves in an FFT bin
freqVin1      = round(freqVin_or1/basebandSamplingRate*NSamples_BB)...
                  *basebandSamplingRate/NSamples_BB; 
freqVin2      = round(freqVin_or2/basebandSamplingRate*NSamples_BB)...
                  *basebandSamplingRate/NSamples_BB; 

% Time vector of the baseband signal
t = 0:1/basebandSamplingRate:(NSamples_BB-1)/basebandSamplingRate;

%%% Baseband (digital) shaping filter %%%
rollOff     = 0.25; % (for RRC filter, single sided output BW is (1+beta)*Rsymb/2 )
symbolSpan  = 25;   % This parameter is related to both the filter length and the attenuation of the stop band
% Instanciate filter
basebandRRC = rcosdesign(rollOff,symbolSpan,basebandOverSampling,'sqrt'); 


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Possible values of test_type are:
%%%%%     'onetone' for a one-tone sine 
%%%%%     'twotone' for a two-tone sine 
%%%%%     'mod'     for a modulated QAM 16 signal
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%                              

test_type='mod';
switch test_type
   case 'onetone'
      %%% one tone signal%%%
      basebandSig = exp(1j*2*pi*freqVin1*t(:));
   case 'twotone'
      %%% two tone signal%%%
      basebandSig = exp(1j*2*pi*freqVin1*t(:))+exp(1j*2*pi*freqVin2*t(:));
   case 'mod'
      %%% Modulated signal
      modSize       = 16; % Modulation order for 16QAM
      nQAMSymbols   = round(NSamples_BB/basebandOverSampling); % Number of QAM symbols to be generated
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
      basebandSig = exp(1j*2*pi*freqVin1*t(:));
end

% Force the peak of the signal to be 1. 
% Mind the avg power of the signal. 
basebandSig = basebandSig/max(abs(basebandSig));


% Instantiate the SDR objects for transmission
tx = sdrtx('Pluto');

% Configure the SDR parameters for transmission
tx.BasebandSampleRate = basebandSamplingRate;
tx.CenterFrequency    = 2.4e9;% (Hz)
tx.filtRFBandwidth    = 20e6; % (Hz), the bandwidth of the RF filter in the SDR
tx.Gain               = -10;  % (dB), adjust as needed to avoid saturation of the RF front end.

% Transmit the signal ; always scale the signal down to avoid saturation of the DAC. 
DAC_scale_factor = 0.75 % Adjust this factor to ensure the signal does not saturate the DAC.
tx.transmitRepeat(DAC_scale_factor*basebandSig)



% Release the SDR object to free system resources.
if exist('disable_tx_release','var')
    if disable_tx_release
        disp('TX SDR object is still active. Perform release(tx) when you are done.');
    else
        release(tx);
    end
else
    % ask user input wether to release the SDR object or continue transmitting
    input_str = input('Release TX SDR object? (y/n): ', 's');
    if strcmpi(input_str, 'y')
        release(tx);
    else
        disp('SDR object still active. Perform release(tx) when you are done.');
    end
end


%------------- END OF CODE --------------