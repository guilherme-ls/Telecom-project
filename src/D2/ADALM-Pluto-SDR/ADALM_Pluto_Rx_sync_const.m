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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%                  Transmitter                        %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Set to true to keep the TX SDR object active after transmission
addpath("../../../ref/D1-D4/")

print_plot = false;

num_of_points = 1:10;
tx_gains = num_of_points * -5 -10;
dac_scale_factors = num_of_points * -5 -10;

SER_per_gain = zeros(1, length(num_of_points));
BER_per_gain = zeros(1, length(num_of_points));

mode = "tx_gain"; % or dac_scale_factor

for ii = num_of_points

if mode == "tx_gain"
    tx_gain = tx_gains(ii);
    dac_scale_factor = -10;
else
    tx_gain = -10;
    dac_scale_factor = dac_scale_factors(ii);
end
disable_tx_release = true; 
% Run the transmitter script to generate and transmit the signal
ADALM_Pluto_Tx
%close all
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
    baseband_ref_trunc = Xa(D+1:length(baseband_rx_trunc) + abs(D));
else
    baseband_ref_trunc = Xa(abs(D)+1:end);
    baseband_rx_trunc = Ya(abs(D)+1:length(baseband_ref_trunc) + abs(D));
end

len = length(baseband_ref_trunc);

sync_phase = mean(mod(2*pi + mod(angle(baseband_rx_trunc(1:len)) + 2*pi, 2*pi) - mod(angle(baseband_ref_trunc(1:len)), 2*pi), 2*pi));
baseband_ref_sync = baseband_rx_trunc(1:len).*exp(-1i*sync_phase);

%baseband_ref_sync = baseband_ref_sync(round(len/20):end-round(len/20));

if print_plot
    plot(abs(baseband_ref_trunc))
    hold all
    plot(abs(baseband_rx_trunc))
    hold off
    legend('Reference signal','Received signal')
    title('Aligned signals')
    xlabel('Sample index')
    ylabel('Signal envelope')
end

% RX RRC and downsampling (reverse effect of resample(qamSig...) )
% WARNING : this downsampling may create unexpected sampling effects
%           please check signals integrity before and after this step
SERs_min = zeros(1, 10);
BERs_min = zeros(1, 10);

basebandComplexDigital_firs = {};

for begin = 1:10
    basebandComplexDigital_fir            = resample(baseband_ref_sync(begin:end), 1, basebandOverSampling, basebandRRC);
    basebandComplexDigital_firs{begin} = basebandComplexDigital_fir;
    % Normalize received symbols to UnitAveragePower (see qammod(inSig)) 
    % Trully effective when noise and distortions are not too large compared to the useful signal
    basebandComplexDigital_fir            = basebandComplexDigital_fir / sqrt(var(basebandComplexDigital_fir));
    
    
    
    if print_plot
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
    end
    
    release(rx); % Release the SDR object to free the hardware resource
    release(tx); % Release the SDR object to free the hardware resource
    
    rx_symbols = threshold_detector(2*basebandComplexDigital_fir(:), 'QAM', modSize);
    tx_symbols = resample(baseband_ref_trunc, 1, basebandOverSampling, basebandRRC);
    tx_symbols = tx_symbols / sqrt(var(tx_symbols));
    len = length(rx_symbols);
    tx_symbols = threshold_detector(2*tx_symbols(:), 'QAM', modSize);
    tx_symbols = tx_symbols(1:len);
    rx_symbols = rx_symbols(1:len);
    
    symbol_errors =  length(rx_symbols) - sum(abs(rx_symbols - tx_symbols) <= 0.01);
    
    rx_bits = symbols2bits(rx_symbols(:), 'QAM', modSize)';
    tx_bits = symbols2bits(tx_symbols(:), 'QAM', modSize)';
    
    bit_errors =  length(rx_bits) - sum(abs(rx_bits - tx_bits) <= 0.01);
    
    disp(["tx_gain: ", num2str(tx_gain) ]);
    disp(["dac_scale_factor: ", num2str(dac_scale_factor) ]);
    disp(["SER: ", num2str(symbol_errors / length(rx_symbols)) ]);
    disp(["BER: ", num2str(bit_errors / length(rx_bits))]);
    
    SERs_min(begin) = symbol_errors / length(rx_symbols);
    BERs_min(begin) = bit_errors / length(rx_bits);
end
    
    [SER_per_gain(ii), id] = min(SERs_min);
    BER_per_gain(ii) = min(BERs_min);
    
    %for ii = 1:length(SERs_min)
        if strcmp(test_type, 'mod')
           figure()
           subplot(1,2,1)
           plot(qamSig,'d')
           title('constellation at TX')
           subplot(1,2,2)
           plot(basebandComplexDigital_firs{id},'d')
           title('constellation at RX')
           % WARNING : the received constellation has almost no sense until filters
           %           delays and phase have been thoroughly analyzed and compensated
        end
    %end
    
end
mkdir("out/cont-phase/");
file_name = sprintf("out/cont-phase/%s.csv", mode);
if mode == "tx_gain"
   dlmwrite(file_name, [tx_gains', SER_per_gain', BER_per_gain']);
else
   dlmwrite(file_name, [dac_scale_factors', SER_per_gain', BER_per_gain']);
end

%------------- END OF CODE --------------
