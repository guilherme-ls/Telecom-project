%%%%% RF Chain Test %%%%%%
clear all;

%%%% System Parameters %%%%
rf_bandwidth     = 30e9;    % Hz
useful_bandwidth = 20e9;    % Hz
bb_sampling_rate = 30.72e9; % MSps
central_freq     = 2400e9;  % Hz

min_distance     = 1.4;  % m  
max_distance     = 1400; % m 
temperature      = 290;  % K
match_resist     = 50;   % Ohms

%%%% RX Parameters %%%%
snr_receiver_out = 10; % dB
in_band_ripple   = 1;  % dB 
adc_full_scale   = 1;  % V 

%%%% TX Parameters %%%%
power_out_tx     = 20; % dBm
acpr_tx_output   = 45; % dB
dac_full_scale   = 1;  % V 
