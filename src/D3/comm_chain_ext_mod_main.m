clear;
close all;
%%%%%%%%%%%%%%%% Fiber Constants

fiber_config.alpha = 0; %0.2; % db/km
fiber_config.dispersion_0 = 17; % ps/nm/km
fiber_config.dispersion_slope = 0.09; % ps/nm2/km
fiber_config.fiber_length = 1; % km

%%%%%%%%%%%%%%%% Physical Constants
  
c = 3e8; % physconst("LightSpeed"); % m/s

%%%%%%%%%% Transmission Constants 

wavelength_0 = 1550; % nm

signal_central_wavelength = 1554; % nm

%%%%%%%%%% TX Chain 

em_laser_config = make_emlaser();
[tx_optical_field, sample_period, ~] = TX_optical_eml(tx_symbols, symbol_period, em_laser_config);

%%%%%%%%%% Fiber Propagation

rx_optical_field = tx_optical_field;

[pulse_out, fiber_trans] = singlemode_fiber(fiber_config, wavelength_0, signal_central_wavelength, ...
                                            pulse, f_vec);

%%%%%%%%%% RX Chain

photodetector_config = make_photodetector();
[rx_symbols, ~, ~, SNR_elec] = RX_photodetector(rx_optical_field, sample_period,...
                                                optical_noise, photodetector_config)

figure();
subplot(2,1,1);
plot(t_vec, abs(pulse));
title('Input pulse')
xlabel('time (ps)') 
ylabel('I(t)') 
subplot(2,1,2);
plot(t_vec, abs(pulse_out));
title('Output pulse')
xlabel('time (ps)') 
ylabel('I(t)') 
