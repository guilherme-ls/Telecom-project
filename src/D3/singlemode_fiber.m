clear;
close all;
%%%%%%%%%%%%%%%% Fiber Constants

alpha = 0.2; % db/km
dispersion_0 = 17; % ps/nm/km
dispersion_slope = 0.09; % ps/nm2/km
fiber_length = 20; % km


%%%%%%%%%%%%%%%% Physical Constants

c = 3e9; % physconst("LightSpeed");

%%%%%%%%%% Transmission Constants 

signal_A0 = 1;

f_0 = 193e12; % Hz 
wavelength_0 = (c / f_0) * 1e9; % nm

f_sig = 1e9; % Hz
signal_wavelength = (c / (f_sig + f_0)) * 1e9; % nm

%%%%%%%%%% Dispersion Transfer Function

dispersion = dispersion_0 + dispersion_slope*(signal_wavelength - wavelength_0);

beta_2 = - dispersion * signal_wavelength^2 / (2*pi*c);
beta_3 = dispersion_slope * signal_wavelength^4 / (2*pi*c)^2;

beta = @(dw) (beta_2*dw^2)/2 + (beta_3*dw^3)/6;
transfer_fun = @(dw) exp((-alpha -1j*beta(dw))*fiber_length);


%%%%%%%%%% Time/Frequency Vector 

%%%%%%%%%%% Pulse Signal Creation
pulse_T0 = 1000; % ps

half_width_max = sqrt(-2 * log(1/sqrt(2)) / (pulse_T0^2)); % THz
half_width = half_width_max * 2; % THz
analitical_time_dispersion = beta_2 * half_width * fiber_length; % ps

T_min = pulse_T0 + analitical_time_dispersion; % ps

bw_cutoff = 0.01;

band_width_max = sqrt(-2 * log(bw_cutoff) / (pulse_T0^2)); % THz
band_width = band_width_max * 2; % THz


f_min = band_width; % THz 

N_pulse = ceil(pulse_T0 * f_min);
N_dispersion = ceil(analitical_time_dispersion * f_min);
N_total = N_pulse + 2 * N_dispersion;


t_vec = (-N_total:1:N_total) / f_min;
pulse_vec = (-N_pulse:1:N_pulse) / f_min;
f_vec = (0:2*N_total) * f_min / N_total;

%%%%%%%%%%% Pulse Signal Creation
pulse = signal_A0*exp(-pulse_vec.^2/(2*pulse_T0^2));
pulse = [zeros(1, N_dispersion), pulse, zeros(1, N_dispersion)];
pulse_fft = fft(pulse);

%%%%%%%%%%% Simulated Dispersion

fiber_trans = arrayfun(transfer_fun, f_vec); 

pulse_out_fft = pulse .* fiber_trans;

pulse_out = ifftshift(fftshift(pulse_out_fft));

figure();
subplot(2,1,1);
plot(f_vec, abs(fiber_trans));
subplot(2,1,2);
plot(f_vec, angle(fiber_trans));

figure();
subplot(2,1,1);
plot(t_vec, pulse);
subplot(2,1,2);
plot(t_vec, pulse_out);

%%%%%%%%%%% Dispersion Calculation

