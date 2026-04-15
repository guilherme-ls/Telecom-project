clear;
close all;

%%% Simulation Params %%%
simulation_config.continuousTimeSamplingRate = 19.968e9;
simulation_config.basebandSamplingRate = 30.72e6;
simulation_config.symbolRate = 15.36e6;

%%% Signal Params %%%
signal_config.test_type = 'onetone';

%%% TX Params %%%
%%%%% DAC %%%%
tx_config.nBitDAC = 10; % Number of bits of the DAC
tx_config.Vref = 1;     % Voltage reference of the DAC
%%%%% Filter %%%%
tx_config.TXBB_Filt_rp = 0.5; % Passband ripple in dB
tx_config.TXBB_Filt_rs = 40; % Stopband ripple in dB
tx_config.TXBB_Filt_f = [10 15]*1e6; % Cutoff frequencies (Hz) 0.5;        
%%%%% Up Mixer %%%%
tx_config.Flo  = 2.4e9;
%%%%% PA %%%%                                             
tx_config.PA_mux = 'ADL5606'; % PA Model 
tx_config.attenuation = -10.9; % -6.4; %  (dB) Preattenuation before PA
                                                    
%%% Channel Params %%%
channel_config.distance = 1.400;

%%% RX Params %%%
%%%%% LNA  %%%%
rx_config.LNA_Gain = 15;  % (dB)
rx_config.LNA_IIP3 = 0; % (dBm)
rx_config.LNA_NF   = 5.4;   % (dB)
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
rx_config.delayADC = perf_tx.TXBB_Filt_n;

SNRs = zeros(1,15);
d = linspace(1.4,1400,15);
for i = 1:15
    channel_config.distance = d(i);
    channel_output = Channel_proj(simulation_config, tx_config, tx_output, channel_config.distance);
    [rx_output, rx_output_truncated, perf_rx] = Rx_proj(simulation_config, rx_config, signal_config, channel_output);
    SNRs(i) = perf_rx.snr;
end

plot(d, SNRs, '-o')
grid()
xlabel('Distance (m)')
ylabel('SNR (dB)')
title('SNR versus Distance')