clear;
close all;
%%%%%%%%%%%%%%%% Fiber Constants

fiber_config.alpha = 0.2; % db/km
fiber_config.dispersion_0 = 17; % ps/nm/km
fiber_config.dispersion_slope = 0.09; % ps/nm2/km
fiber_config.fiber_length = 1; % km

%%%%%%%%%%%%%%%% Physical Constants
  
c = 3e5; % physconst("LightSpeed") / 1000; % nm/ps

%%%%%%%%%% Transmission Constants 

signal_A0 = 1;

wavelength_0 = 1550; % nm

signal_central_wavelength = 1554; % nm

%%%%%%%%%% Dispersion Transfer Function

dispersion = fiber_config.dispersion_0 + fiber_config.dispersion_slope*(signal_central_wavelength - wavelength_0);

%%%%%%%%%%% Pulse Signal Creation
pulse_T0 = 1; % ps
pulse_a = log(2) / (2 * (pulse_T0 / 2)^2);
pulse_FWHM = 2 * sqrt(2 * log(2)) * pulse_T0;

pulse_freq_width =  0.44 / pulse_T0; % 0.44 / pulse_FWHM; % THz ; % sqrt(2 * log(2)) / pulse_T0; % THz 
pulse_delta_lambda = pulse_freq_width * signal_central_wavelength^2 / c; % nm
analitical_time_dispersion = dispersion * pulse_delta_lambda * fiber_config.fiber_length; % ps

fprintf("DeltaTau Ana = %.2f ps\n", analitical_time_dispersion);

%%%%%%%%%%% Pulse Signal Creation
[pulse, t_vec, f_vec, f_sampling] = gaussian_pulse(fiber_config, signal_A0, pulse_T0,...
                                       wavelength_0, signal_central_wavelength);

%%%%%%%%%%% Simulated Dispersion

[pulse_out, fiber_trans] = singlemode_fiber(fiber_config, wavelength_0, signal_central_wavelength, ...
                                            pulse, f_sampling);

input_pulse_width = pulsewidth(abs(pulse), t_vec);
exit_pulse_width = pulsewidth(abs(pulse_out), t_vec);


figure();
pulsewidth(abs(pulse), t_vec);
figure();
pulsewidth(abs(pulse_out), t_vec);

fprintf("DeltaTau Sim In = %.2f ps\n", input_pulse_width);
fprintf("DeltaTau Sim Out= %.2f ps\n", exit_pulse_width);

figure();
subplot(2,1,1);
plot(f_vec, abs(fiber_trans));
xlabel('ferquency (THz)') 
ylabel('abs(T(f))') 
subplot(2,1,2);
plot(f_vec, unwrap(angle(fiber_trans)));
xlabel('ferquency (THz)') 
ylabel('angle(T(f))') 

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
