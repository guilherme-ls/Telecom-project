% ADALM_Pluto_Rx - Script that performs a RX wireless communication chain
%
% [Note to instructors] This file has no equivalent for TELECOM201/ICS905
%
% Purpose:
%   Small, self-contained receiver chain demonstrating baseband signal
%   acquisition, filtering and demodulation via the ADALM‑Pluto SDR.
% 
% Usage:
%   Configure signal parameters according to the transmitted signal.
%   Execute the script to acquire samples from the ADALM‑Pluto SDR. 
% 
% Requirements:
%   - MATLAB with Communications System Toolbox
%   - ADALM‑Pluto Support Package
% 
% Notes:
%   As provided, the chain is not optimized ; ONE OF THE TARGET OF THE
%   PROJECT IS TO EXPLORE THE PARAMETERS OF THE SYSTEM IN ORDER
%   TO MAXIMIZE THE PERFORMANCE OF THE RECEIVING.
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

addpath(genpath('subblocks/'))

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%                  Transmitter                        %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Set to true to keep the TX SDR object active after transmission
disable_tx_release = true; 
% Run the transmitter script to generate and transmit the signal
ADALM_Pluto_Tx

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%                   Receiver                          %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

rx = sdrrx('Pluto'); 
rx.BasebandSampleRate = basebandSamplingRate;
%rx.GainSource     = 'manual';
%rx.Gain           = 10;
rx.filtRFBandwidth = 20e6; % Set the RF filter bandwidth

NSamples_RX = 2*NSamples_BB; % Number of samples to acquire

% Acquire samples from the SDR
disp('Acquiring samples from the ADALM-Pluto SDR...');
baseband_rx = double(rx.capture(NSamples_BB)); % Capture returns int16, convert to double for processing
disp('Acquisition complete.');

% Normalize signals to UnitAveragePower for improve alignment
baseband_rx_rms_norm = baseband_rx/sqrt(var(baseband_rx));
basebandSig_rms_norm = basebandSig/sqrt(var(basebandSig));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%                   Post-process                      %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Aligns signals by delaying the "earliest" signal. 
% This part of the code has not been thoroughly tested and may not work properly in all cases.
% It is provided as a starting point for the project, but you need to check the integrity of the signals before and after this step, and optimize it with respect to the filters delays.
[Xa,Ya,D] = alignsignals(basebandSig_rms_norm,baseband_rx_rms_norm);
if D>0
    baseband_rx_trunc = Ya(D+1:end);
    baseband_ref_trunc = Xa(D+1:length(baseband_rx_trunc));
else
    baseband_ref_trunc = Xa(abs(D)+1:end);
    baseband_rx_trunc = Ya(abs(D)+1:length(baseband_ref_trunc));
end


figure
plot(abs(baseband_ref_trunc))
hold all
plot(abs(baseband_rx_trunc))
hold off
legend('Reference signal','Received signal')
title('Aligned signals')
xlabel('Sample index')
ylabel('Signal envelope')

% RX RRC and downsampling (reverse effect of resample(qamSig...) )
% WARNING : this downsampling may create unexpected sampling effects
%           please check signals integrity before and after this step
basebandComplexDigital_fir            = resample(baseband_rx_trunc,1,basebandOverSampling,basebandRRC);

% Normalize received symbols to UnitAveragePower (see qammod(inSig)) 
% Trully effective when noise and distortions are not too large compared to the useful signal
basebandComplexDigital_fir            = basebandComplexDigital_fir / sqrt(var(basebandComplexDigital_fir));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%            Plot section            %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

window_number       = 1;
lineSpec_index      = 1;
fullband_spectrum   = true;

plot_spectrum(basebandSig,window_number,...
               basebandSamplingRate,lineSpec_index,fullband_spectrum);
title('TX Digital Complex recombined signal')

window_number       = window_number+1;
plot_spectrum(baseband_rx,window_number,...
               basebandSamplingRate,lineSpec_index,fullband_spectrum);
title('Receiver complex recombined output')



if strcmp(test_type, 'mod')
   figure()
   subplot(1,2,1)
   plot(qamSig,'d')
   title('constellation at TX')
   subplot(1,2,2)
   plot(basebandComplexDigital_fir,'d')
   title('constellation at RX')
   % WARNING : the received constellation has almost no sense until filters
   %           delays and phase have been thoroughly analyzed and compensated
end


release(rx); % Release the SDR object to free the hardware resource
release(tx); % Release the SDR object to free the hardware resource


%------------- END OF CODE --------------
