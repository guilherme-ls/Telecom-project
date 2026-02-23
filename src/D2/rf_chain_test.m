%%%%% RF Chain Test %%%%%%
clear all;

%%%% System Parameters %%%%
rf_bandwidth     = 20e9;    % Hz
bb_sampling_rate = 30.72e9; % MSps
central_freq     = 2400e9;  % Hz

snr_receiver_out = 10;   % dB 
power_out_tx     = 20;   % dBm
min_distance     = 1.4;  % m  
max_distance     = 1400; % m 
match_resist     = 50;   % Ohms
temperature      = 290;  % K
acpr_tx_output   = 45;   % dB
adc_full_scale   = 1;    % V 
dac_full_scale   = 1;    % V 
