clear;
close all;
%%%%%%%%%%%%%%%% Fiber Constants

fiber_config.alpha = 0.2; % db/km
fiber_config.dispersion_0 = 17; % ps/nm/km
fiber_config.dispersion_slope = 0.09; % ps/nm2/km
fiber_config.fiber_length = 1; % km

%%%%%%%%%%%%%%%% Physical Constants
  
c = 3e8; % physconst("LightSpeed"); % m/s

%%%%%%%%%% Transmission Constants 

wavelength_0 = 1550; % nm

symbol_period = 20; % ps

photo_detector.sensitivity = 1;
photo_detector.electrical_bw = 1e10;
photo_detector.optical_bw = 125e9;
photo_detector.r_load = 50;
photo_detector.n_th = 2e-20;

%%%% LASER

laser_config = make_emlaser('P_opt_dBm', 0);

%%%% PHOTO DETECTOR

photodetector_config = make_photodetector(...
    'sensitivity', photo_detector.sensitivity, ...
    'B_e', photo_detector.electrical_bw, ...
    'B_opt', photo_detector.optical_bw, ...
    'R_load', photo_detector.r_load, ...
    'N_th', photo_detector.n_th ...
    );

%%%% INPUT GENERATION %%%%

symbols_amount = 100;

tx_symbols = randi([0, 1], symbols_amount, 1);

%%%% TX OPTICAL FIELD %%%%

[tx_optical_field, tx_sampling_period, ~] = ... 
    TX_optical_eml(tx_symbols, symbol_period, laser_config);

%%%% FIBER TRANSMISSION %%%%

%rx_optical_field = tx_optical_field;

[rx_optical_field, ~] = singlemode_fiber(fiber_config, wavelength_0, wavelength_0, ...
                                            tx_optical_field', 2/symbol_period);
rx_optical_field = rx_optical_field';


%%%% RX PHOTO CURRENT %%%%
[rx_photo_current, rx_sampling_period, ~, rx_eletrical_snr] = ...
    RX_photodetector(rx_optical_field, tx_sampling_period, ...
                     photo_detector.n_th, photodetector_config);

%%%% RX SYMBOLS %%%%
rx_symbols = rx_photo_current > mean(rx_photo_current);


%%%% CHAIN PERFORMANCE %%%%

ser = mean(rx_symbols ~= tx_symbols);

fprintf("SER = %.2f\n", ser);



