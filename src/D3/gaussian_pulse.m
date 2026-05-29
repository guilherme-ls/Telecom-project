function [gaussian_pulse, time_vec, freq_vec, f_sampling] = gaussian_pulse(fiber_config, ...
                               signal_A0, pulse_FWHM, wavelength_0, pulse_central_wavelength)
%%%%%%%%%%%%%%%% Physical Constants
  
c = 3e5; % physconst("LightSpeed") / 1000; % nm/ps

%%%%%%%%%% Dispersion Transfer Function

dispersion = fiber_config.dispersion_0 + fiber_config.dispersion_slope*(pulse_central_wavelength - wavelength_0);

%%%%%%%%%%% Pulse Signal Creation
pulse_freq_width =  0.44 / pulse_FWHM; % THz 
pulse_delta_lambda = pulse_freq_width * pulse_central_wavelength^2 / c; % nm
analitical_time_dispersion = dispersion * pulse_delta_lambda * fiber_config.fiber_length; % ps

bw_cutoff = 0.001;
pulse_T0_dispersed = pulse_FWHM + analitical_time_dispersion * 3;
pulse_a_dispersed = log(2) / (2 * (pulse_T0_dispersed / 2)^2);
dispersed_pulse_bw = 2 * sqrt(2 * pulse_a_dispersed * log(1 / sqrt(bw_cutoff))); % THz

f_sampling = max(dispersed_pulse_bw, pulse_freq_width * 10) * 2; % THz 

N_total = ceil(2 * max(pulse_T0_dispersed, pulse_FWHM) * f_sampling);
N_total = 2^ceil(log2(N_total));

N_half = N_total / 2;

time_vec = (-N_half + 1:1:N_half) / f_sampling;
freq_vec = (-N_half + 1:1:N_half) * f_sampling / N_total;
gaussian_pulse = signal_A0*exp(-4*log(2)*(time_vec / pulse_FWHM).^2);
end