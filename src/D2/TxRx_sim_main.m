clear;
close all;

%%% Simulation Params %%%
simulation_config.continuousTimeSamplingRate = 20e9; 

%%% Signal Params %%%
signal_config.test_type = 'mod';

%%% TX Params %%%
%%%%% DAC %%%%
tx_config.nBitDAC = 18; % Number of bits of the DAC
tx_config.Vref = 1;    % Voltage reference of the DAC
%%%%% Filter %%%%
tx_config.TXBB_Filt_rp = 0.5; % Passband ripple in dB
tx_config.TXBB_Filt_rs = 40; % Stopband ripple in dB
tx_config.TXBB_Filt_f = [15 20]*1e6; % Cutoff frequencies (Hz) 0.5;        
%%%%% Up Mixer %%%%                                             
tx_config.Flo  = 2.4e9;
%%%%% PA %%%%                                             
tx_config.PA_mux = 'ADL5606'; % PA Model 
                                                    
%%% Channel Params %%%
channel_config.distance = 1.4;

%%% RX Params %%%                                         
%%%%% LNA  %%%%
rx_config.LNA_Gain = 15;  % (dB)  
rx_config.LNA_IIP3 = 100; % (dBm)
rx_config.LNA_NF   = 0;   % (dB)
%%%%% RXBB %%%%
rx_config.RXBB_Filt_rp = 0.5;
rx_config.RXBB_Filt_rs = 40;
rx_config.RXBB_Filt_f = [10 20]*1e6;  
%%%%% BBAmp %%%%
rx_config.BBamp_Gain = 20; % (dB)
rx_config.BBamp_IIP3 = 100; % (dBm)
rx_config.BBamp_NF   = 10; % (dB)
rx_config.BBamp_band = 10e6;% (MHz)
%%%%% ADC %%%%
rx_config.nBitADC = 18;
rx_config.delayADC = 0;

%%% Communication Chain %%%

[tx_output, tx_input, tx_qam_input, perf_tx] = Tx_proj(simulation_config, tx_config, signal_config);
channel_output = Channel_proj(simulation_config, tx_config, tx_output, channel_config.distance);
[rx_output, rx_output_truncated, perf_rx] = Rx_proj(simulation_config, rx_config, ...
                                                    tx_config, signal_config, channel_output);


basebandSamplingRate_or       = 30e6;     
basebandSamplingRate          = simulation_config.continuousTimeSamplingRate/round(simulation_config.continuousTimeSamplingRate/basebandSamplingRate_or);

window_number       = 1;
lineSpec_index      = 1;
fullband_spectrum   = true;

plot_spectrum(tx_input, window_number,...
               basebandSamplingRate,lineSpec_index, fullband_spectrum);
title('TX Digital Complex recombined signal')

window_number       = window_number+1;
plot_spectrum(rx_output,window_number,...
               basebandSamplingRate,lineSpec_index, fullband_spectrum);
title('Receiver complex recombined output')

window_number       = window_number+1;
fullband_spectrum   = false;
plot_spectrum(tx_output, window_number, ...
              simulation_config.continuousTimeSamplingRate, 1, false);
title('PA spectrum')


if strcmp(signal_config.test_type, 'mod')
   figure()
   subplot(1,2,1)
   plot(tx_qam_input,'d')
   title('constellation at TX')
   subplot(1,2,2)
   plot(rx_output_truncated,'d')
   title('constellation at RX')
   % WARNING : the received constellation has almost no sense until filters
   %           delays have been thoroughly analyzed and compensated
end

%%% Performances %%%
