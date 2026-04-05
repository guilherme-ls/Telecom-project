close all;
clear;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%          Transmission Configurations                %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%% General Config %%%%%
pluto_configs.general.device_name = "Pluto";
pluto_configs.general.center_freq = 2.4e9; % Hz 
pluto_configs.general.bb_sample_rate = 30.72e6;  % Hz
pluto_configs.general.filt_rf_bw = 20e6; % Hz

%%%%% Sync Config %%%%%
pluto_configs.sync.enable = true;
pluto_configs.sync.samples = 13; % Samples in the frame
pluto_configs.sync.length = 13; % length of the barker sequence 
pluto_configs.sync.coarse.frequency_resolution = 10; 

%%%%% TX Config %%%%% 
pluto_configs.tx.enable = true;  
pluto_configs.tx.automatic_emmision = true;
pluto_configs.tx.gain = -10; % dB 
pluto_configs.tx.dac.scale_factor = 0.75; % [0, 1]

%%%%% RX Config %%%%% 
pluto_configs.rx.enable = true;
pluto_configs.rx.automatic_reception = true;  
pluto_configs.rx.gain.manual = true;
pluto_configs.rx.gain.value = 10;
pluto_configs.rx.bb_rrc.roll_off = 0.25;
pluto_configs.rx.bb_rrc.symbol_span = 25;

%%%%% Signal Config %%%%% 

% Raw Signal Config
pluto_configs.signal.raw.enable = false;
pluto_configs.signal.raw.harmonics.frequencies = [6.12e6];
pluto_configs.signal.raw.harmonics.width = 0.07e6;
pluto_configs.signal.raw.usable_band = 0.15e6;
pluto_configs.signal.raw.harmonics.samples = 1e5; % Samples

% Modulated Message Config
pluto_configs.signal.modulated.enable = true;
pluto_configs.signal.modulated.symbol_rate = 3e6;
pluto_configs.signal.modulated.modulation.mod = "QAM";  
pluto_configs.signal.modulated.modulation.size = 16;  

% Modulated Message Generation
signal_generation_seed = 100;
signal_length = 100e3;

rand_message_range = [0 pluto_configs.signal.modulated.modulation.size-1];

rng(signal_generation_seed);
rand_message = randi(rand_message_range, signal_length, 1);

pluto_configs.signal.modulated.message = rand_message;

%%%%% Plot Config %%%%% 
pluto_configs.plot.spectrum = false;
pluto_configs.plot.sync = false;

%%%%% Perfomances Display Config %%%%% 
pluto_configs.performace.snr = false;
pluto_configs.performace.ser = true;
pluto_configs.performace.ber = true;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%            Call Experiment Script                   %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

num_of_points = 1:10;
gain_max = -10; %dB
gain_min = -80; %dB

scale_factor_max = -10; %dBFS
scale_factor_min = -80; %dBFS

%%%% Fixed DAC Scale Factor

scale_factor_db = -10; % dBFS
pluto_configs.tx.dac.scale_factor = 10^(scale_factor_db/10); % [0, 1]

gain_val = zeros(1, length(num_of_points));
fixed_dac_ser = zeros(1, length(num_of_points));
fixed_dac_ber = zeros(1, length(num_of_points));

for ii = num_of_points
  lerp_coef = (ii - num_of_points(1)) / (num_of_points(end) - num_of_points(1));
  pluto_configs.tx.gain = (gain_max - gain_min) * lerp_coef + gain_min; % dB

  gain_val(ii) = pluto_configs.tx.gain;
  ADALM_Pluto_TxRx

  fixed_dac_ser(ii) = rx_ser;
  fixed_dac_ber(ii) = rx_ber;
end

%%%% Fixed TX Gain

pluto_configs.tx.gain = -10; % dB

dac_scale_val = zeros(1, length(num_of_points));
fixed_gain_ser = zeros(1, length(num_of_points));
fixed_gain_ber = zeros(1, length(num_of_points));

for ii = num_of_points
  lerp_coef = (ii - num_of_points(1)) / (num_of_points(end) - num_of_points(1));
  scale_factor_db = (scale_factor_max - scale_factor_min) * lerp_coef + scale_factor_min; % dBFS
  dac_scale_val(ii) = scale_factor_db;

  pluto_configs.tx.dac.scale_factor = 10^(scale_factor_db/10); % [0, 1]
  ADALM_Pluto_TxRx

  fixed_gain_ser(ii) = rx_ser;
  fixed_gain_ber(ii) = rx_ber;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%            Result Plots                             %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%% Fixed DAC Scale Factor

figure()
subplot(2,1,1);
plot(gain_val, fixed_dac_ser);
title('Fixed DAC Scale Factor - SER');

xlabel('Gain (dB)');
ylabel('SER');

subplot(2,2,1);
plot(gain_val, fixed_dac_ber);
title('Fixed DAC Scale Factor - BER');

xlabel('Gain (dB)');
ylabel('BER');

%%%% Fixed TX Gain
figure()
subplot(2,1,1);
plot(dac_scale_val, fixed_gain_ser);
title('Fixed TX Gain - SER');

xlabel('DAC Scale Factor (dBFS)');
ylabel('SER');

subplot(2,2,1);
plot(dac_scale_val, fixed_gain_ber);
title('Fixed TX Gain - BER');

xlabel('DAC Scale Factor (dBFS)');
ylabel('BER');



