clear;
close all;
%%%%%%%%%%%%%%%% Fiber Constants

fiber_config.alpha = 0.2; % db/km
fiber_config.dispersion_0 = 17; % ps/nm/km
fiber_config.dispersion_slope = 0; %0.09; % ps/nm2/km
fiber_config.fiber_length = 1; % km

%%%%%%%%%%%%%%%% Physical Constants
  
c = 3e9; % physconst("LightSpeed");

%%%%%%%%%% Transmission Constants 

signal_A0 = 1;

f_0 = 193e12; % Hz 
wavelength_0 = (c / f_0) * 1e9; % nm

f_sig = 1e9; % Hz
signal_wavelength = (c / (f_sig + f_0)) * 1e9; % nm

%%%%%%%%%% Dispersion Transfer Function

dispersion = fiber_config.dispersion_0 + fiber_config.dispersion_0*(signal_wavelength - wavelength_0);

beta_2 = - dispersion * signal_wavelength^2 / (2*pi*c);

%%%%%%%%%%% Pulse Signal Creation
pulse_T0 = 10; % ps
pulse_a = log(2) / (2 * (pulse_T0 / 2)^2);

pulse_freq_width = 2 * sqrt(2 * pulse_a * log(2)); % THz 
analitical_time_dispersion = beta_2 * pulse_freq_width * fiber_config.fiber_length; % ps

T_min = pulse_T0 * 5 + abs(analitical_time_dispersion); % ps

bw_cutoff = 0.00001;

band_width = 2 * sqrt(2 * pulse_a * log(1 / sqrt(bw_cutoff))); % THz

f_min = 10 ; %band_width; % THz 

N_pulse = ceil(pulse_T0 * 5 * f_min);
N_dispersion = ceil(abs(analitical_time_dispersion * f_min));
N_total = N_pulse + N_dispersion;

t_vec = (-N_total:1:N_total) / f_min;
pulse_vec = (-N_pulse:1:N_pulse) / f_min;
f_vec = (-N_total:1:N_total) * f_min / 2;

%%%%%%%%%%% Pulse Signal Creation
pulse = signal_A0*exp(-pulse_vec.^2 / (2 * pulse_T0^2));
pulse = [zeros(1, N_dispersion), pulse, zeros(1, N_dispersion)];

%%%%%%%%%%% Simulated Dispersion

[pulse_out, fiber_trans] = singlemode_fiber(fiber_config, wavelength_0, signal_wavelength, ...
                                            pulse, f_vec);

%figure();
%subplot(2,1,1);
%plot(f_vec, abs(fiber_trans));
%subplot(2,1,2);
%plot(f_vec, angle(fiber_trans));

figure();
subplot(2,1,1);
plot(t_vec, pulse);
subplot(2,1,2);
plot(t_vec, pulse_out);
