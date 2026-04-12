clear;
close all;

%%% Simulation Params %%%
simulation_config.continuousTimeSamplingRate = 19.968e9;
simulation_config.basebandSamplingRate = 30.72e6;
simulation_config.symbolRate = 15.36e6;

%%% Signal Params %%%
signal_config.test_type = 'onetone';

%%% RX Params %%%                                         
%%%%% LNA  %%%%
rx_config.LNA_Gain = 15;  % (dB)  
rx_config.LNA_IIP3 = 0; % (dBm)
rx_config.LNA_NF   = 5.8;   % (dB)
%%%%% RXBB %%%%
rx_config.Flo = 2.4e9;
rx_config.RXBB_Filt_rp = 0.5;
rx_config.RXBB_Filt_rs = 40;
rx_config.RXBB_Filt_f = [10 15]*1e6;  
%%%%% BBAmp %%%%
rx_config.BBamp_Gain = 23.5; % (dB)
rx_config.BBamp_IIP3 = 100; % (dBm)
rx_config.BBamp_NF   = 10; % (dB)
rx_config.BBamp_band = 10e6;% (MHz)
%%%%% ADC %%%%
rx_config.nBitADC = 12;
rx_config.delayADC = 0;
rx_config.Vref = 1;

% Input signal
Fs_ADC = 30e6;
Rin = 50;
N_points = 2^13;    % Number of signal points
N_Cont = N_points*simulation_config.continuousTimeSamplingRate/Fs_ADC; % Number of signal points
Ts_Cont = 1/simulation_config.continuousTimeSamplingRate;
t_Cont = (0:(N_Cont-1))*Ts_Cont; % Time vector
K   = 1.38e-23;     % Boltzmann Constant
T   = 290;          % room temperature
fin_or       = 7.12e6;   % Input sine frequency
fin          = round(fin_or/Fs_ADC*N_points)*Fs_ADC/N_points; % Determining the input freq
Pin             = -82.97;  % Pin in dBm
Ain             = sqrt(10.^((Pin-30)/10)*2*Rin);
AntennaNoise    = randn(1,N_Cont)*sqrt(K*T*simulation_config.continuousTimeSamplingRate/2*Rin);
rxSignal        = Ain*sin(2*pi*(rx_config.Flo+fin)*t_Cont+rand()*2*pi)+AntennaNoise; % Input signal

%%% Transmission Chain %%%
[rx_output, rx_output_truncated, perf_rx] = Rx_proj(simulation_config, rx_config, signal_config, rxSignal);

basebandSamplingRate          = simulation_config.basebandSamplingRate;

%%% Plotting %%%
Rin = 50;
voltsq2mwatt    = 1e3/Rin; % Conversion factor from V^2 to milliWatt
window_number       = 2;
lineSpec_index      = 1;
fullband_spectrum   = true;

plot_spectrum(rxSignal*sqrt(voltsq2mwatt), window_number,...
               simulation_config.continuousTimeSamplingRate, lineSpec_index, false);
title('RX Input')
xlabel('frequency (Hz)')
ylabel('PSD (dBm/bin)')

window_number       = window_number+1;
plot_spectrum(rx_output_truncated*sqrt(voltsq2mwatt), window_number,...
               basebandSamplingRate/2,lineSpec_index, fullband_spectrum);
title('RX Output Truncated')
xlabel('frequency (Hz)')
ylabel('PSD (dBm/bin)')

window_number       = window_number+1;
fullband_spectrum   = false;
plot_spectrum(rx_output*sqrt(voltsq2mwatt), window_number, ...
              basebandSamplingRate, 1, true);
title('RX Output')
xlabel('frequency (Hz)')
ylabel('PSD (dBm/bin)')

disp(['Signal power: ', num2str(perf_rx.signal_power), ' mW or ', num2str(10*log10(perf_rx.signal_power)), ' dBm.'])
disp(['SNR: ', num2str(perf_rx.snr), ' dB.'])
disp(['Total power used by RX: ', num2str(perf_rx.power.P_RX_total), ' W.'])

%%% Performances %%%
