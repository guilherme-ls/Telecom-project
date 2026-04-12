clear;
close all;

%%% Simulation Params %%%
simulation_config.continuousTimeSamplingRate = 19.968e9; 
simulation_config.basebandSamplingRate = 30.72e6;
simulation_config.symbolRate = 15.36e6;

%%% Signal Params %%%
signal_config.test_type = 'mod';

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
tx_config.attenuation = -6.2; % (dB) pre-attenuation


%%% Transmission Chain %%%

[tx_output, tx_input, tx_qam_input, perf_tx] = Tx_proj(simulation_config, tx_config, signal_config);

basebandSamplingRate  = simulation_config.basebandSamplingRate;

%%% Plotting %%%
Rin = 50;
voltsq2mwatt    = 1e3/Rin; % Conversion factor from V^2 to milliWatt
window_number       = 1;
lineSpec_index      = 1;
fullband_spectrum   = true;

plot_spectrum(tx_input*sqrt(voltsq2mwatt), window_number,...
               basebandSamplingRate,lineSpec_index, fullband_spectrum);
title('TX Digital Complex recombined signal')
xlabel('frequency (Hz)')
ylabel('PSD (dBm/bin)')

window_number       = window_number+1;
fullband_spectrum   = false;
plot_spectrum(tx_output*sqrt(voltsq2mwatt), window_number, ...
              simulation_config.continuousTimeSamplingRate, 1, false);
title('TX Output')
xlabel('frequency (Hz)')
ylabel('PSD (dBm/bin)')

disp(['Total power used by TX: ', num2str(perf_tx.power.P_TX_total), ' W.'])

if strcmp(signal_config.test_type, 'mod')
    disp(['Signal power: ', num2str(perf_tx.signal_power), ' mW or ', num2str(10*log10(perf_tx.signal_power)), ' dBm.'])
    disp(['ACPR: ', num2str(10*log10(perf_tx.acpr)), ' dB.'])
    figure()
    plot(tx_qam_input,'d')
    title('constellation at TX')
end

%%% Performances %%%
