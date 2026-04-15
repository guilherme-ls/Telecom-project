clear;
close all;
%%%%%%%%%%%%%%%% Fiber Constants

alpha = 0.2; % db/km
dispersion_0 = 10; % ps/nm/km
dispersion_slope = 1;
fiber_length = 1; % km


%%%%%%%%%%%%%%%% Physical Constants

c = physconst("LightSpeed");

%%%%%%%%%% Transmission Constants 

signal_A0 = 1;

f_0 = 193e12; % Hz 
wavelength_0 = (c / f_0) * 1e9; % nm

f = 1e9; % Hz
wavelength = (c / f) * 1e9; % nm
signal_wavewidth = 10; % nm

%%%%%%%%%% Dispersion Transfer Function

dispersion = dispersion_0 + dispersion_slope*wavelength;

beta_2 = - dispersion * (wavelength_0 + wavelength)^2 / (2*pi*c);
beta_3 = dispersion_slope * (wavelength_0 + wavelength)^4 / (2*pi*c)^2;

beta = @(dw) (beta_2*dw^2)/2 + (beta_3*dw^3)/6;
transfer_fun = @(dw) exp((-alpha -1j*beta(dw))*fiber_length);


%%%%%%%%%% Time/Frequency Vector 

%%%%%%%%%%% Pulse Signal Creation
pulse_T0 = 1e-9;

half_width_max = sqrt(-2 * log(1/sqrt(2)) / (pulse_T0^2));
half_width = half_width_max * 2;
analitical_time_dispersion = beta_2 * half_width * fiber_length;

T_min = pulse_T0 + analitical_time_dispersion*1e-12;

assert(0);
N_points = 0;

t_vec = (-N_points:1:N_points);
f_vec = (-N_points:1:N_points)*f_max/N_points;

%%%%%%%%%%% Pulse Signal Creation
pulse = signal_A0*exp(-t_vec.^2/(2*pulse_T0^2));
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

