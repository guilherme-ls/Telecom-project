function [pulse, time_vec, freq_vec, f_sampling, pulse_freq_width] = square_pulse(fiber_config, ...
                               signal_A0, pulse_T0, wavelength_0, pulse_central_wavelength)
%%%%%%%%%%%%%%%% Physical Constants
  
c = 3e5; % physconst("LightSpeed") / 1000; % nm/ps

%%%%%%%%%% Dispersion Transfer Function

dispersion = fiber_config.dispersion_0 + fiber_config.dispersion_slope*(pulse_central_wavelength - wavelength_0);

%%%%%%%%%%% Pulse Signal Creation
pulse_freq_width =  2 / pulse_T0; % THz 
pulse_delta_lambda = pulse_freq_width * pulse_central_wavelength^2 / c; % nm
analitical_time_dispersion = dispersion * pulse_delta_lambda * fiber_config.fiber_length; % ps

pulse_T0_dispersed = pulse_T0 * 2 + analitical_time_dispersion * 3;

f_sampling = pulse_freq_width * 10; % THz 

N_total = ceil(2 * pulse_T0_dispersed * f_sampling);
N_total = 2^ceil(log2(N_total));

N_half = N_total / 2;

time_vec = (-N_half + 1:1:N_half) / f_sampling;
freq_vec = (-N_half + 1:1:N_half) * f_sampling / N_total;

pulse = zeros(1, N_total);
pulse(time_vec < pulse_T0 / 2) = signal_A0;
pulse(time_vec < -pulse_T0 / 2) = 0;

F_tx = (-N_total/2 : N_total/2 - 1) * (f_sampling / N_total);
tx_cutoff_THz = 1 * (1 / (pulse_T0 * 1e-12)) / 1e12;
tx_filter = exp(-0.5 * (F_tx / tx_cutoff_THz).^2);
pulse = ifft(ifftshift( fftshift(fft(pulse)) .* tx_filter ));
end