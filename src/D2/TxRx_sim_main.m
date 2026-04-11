clear;
close all;

%%% Simulation Params %%%
simulation_config.continuousTimeSamplingRate = 19.98e9; 

%%% Signal Params %%%
signal_config.test_type = 'onetone';

%%% TX Params %%%
%%%%% DAC %%%%
tx_config.nBitDAC = 4; % Number of bits of the DAC
tx_config.Vref = 1;    % Voltage reference of the DAC
%%%%% Filter %%%%
tx_config.TXBB_Filt_rp = 0.5; % Passband ripple in dB
tx_config.TXBB_Filt_rs = 40; % Stopband ripple in dB
tx_config.TXBB_Filt_f = [10 15]*1e6; % Cutoff frequencies (Hz) 0.5;        
%%%%% Up Mixer %%%%
tx_config.Flo  = 2.4e9;
%%%%% PA %%%%                                             
tx_config.PA_mux = 'ADL5606'; % PA Model 
tx_config.attenuation = -10.4; %-7; % (dB) Preattenuation before PA
                                                    
%%% Channel Params %%%
channel_config.distance = 1400;

%%% RX Params %%%
%%%%% LNA  %%%%
rx_config.LNA_Gain = 15;  % (dB)  
rx_config.LNA_IIP3 = 0; % (dBm)
rx_config.LNA_NF   = 5.8;   % (dB)
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
channel_output = Channel_proj(simulation_config, tx_config, tx_output, channel_config.distance);
[rx_output, rx_output_truncated, perf_rx] = Rx_proj(simulation_config, rx_config, signal_config, channel_output);

basebandSamplingRate_or       = 30e6;     
basebandSamplingRate          = simulation_config.continuousTimeSamplingRate/round(simulation_config.continuousTimeSamplingRate/basebandSamplingRate_or);

%%% Plotting %%%
Rin = 50;
voltsq2mwatt    = 1e3/Rin; % Conversion factor from V^2 to milliWatt
window_number       = 1;
lineSpec_index      = 1;
fullband_spectrum   = true;

plot_spectrum(tx_input*sqrt(voltsq2mwatt), window_number,...
               basebandSamplingRate,lineSpec_index, fullband_spectrum);
title('TX signal')
xlabel('frequency (Hz)')
ylabel('PSD (dBm/bin)')

window_number       = window_number+1;
plot_spectrum(tx_output*sqrt(voltsq2mwatt), window_number, ...
              simulation_config.continuousTimeSamplingRate, 1, false);
title('TX Output')
xlabel('frequency (Hz)')
ylabel('PSD (dBm/bin)')

window_number       = window_number+1;
plot_spectrum(channel_output*sqrt(voltsq2mwatt), window_number, ...
              simulation_config.continuousTimeSamplingRate, 1, false);
title('RX Input')
xlabel('frequency (Hz)')
ylabel('PSD (dBm/bin)')

window_number       = window_number+1;
plot_spectrum(rx_output*sqrt(voltsq2mwatt),window_number,...
               basebandSamplingRate,lineSpec_index, true);
title('Receiver complex recombined output')
xlabel('frequency (Hz)')
ylabel('PSD (dBm/bin)')


%disp(['Signal power (sent): ', num2str(perf_tx.signal_power), ' mW or ', num2str(10*log10(perf_tx.signal_power)), ' dBm.'])
disp(['Signal power (digital out): ', num2str(perf_rx.signal_power), ' mW or ', num2str(10*log10(perf_rx.signal_power)), ' dBm.'])
disp(['SNR: ', num2str(perf_rx.snr), ' dB.'])

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
