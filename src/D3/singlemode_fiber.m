%%%%%%%%%%%%% SINGLEMODE FIBER %%%%%%%%%%%%%
%% Arguments:
%%  - fiber_config.alpha : db/km
%%  - fiber_config.dispersion_0 : ps/nm/km
%%  - fiber_config.dispersion_slope : ps/nm2/km
%%  - fiber_config.fiber_length : km
%%  - transmission_wavelength : nm
%%  - signal_in : J/ps
%%  - time_vector : ps
%% Return:
%%  - fiber_out.alpha : J/ps
%%  - transfer_fun : J/THz
function [fiber_out, fiber_trans] = singlemode_fiber(fiber_config, ...
    wavelength_0, signal_central_wavelength, ...
    signal_in, f_sampling, plot_en )
%%%%%%%%%%%%%%%% Fiber Constants
alpha = fiber_config.alpha; % db/km
dispersion_0 = fiber_config.dispersion_0; % ps/nm/km
dispersion_slope = fiber_config.dispersion_slope; % ps/nm2/km
fiber_length = fiber_config.fiber_length; % km

%%%%%%%%%%%%%%%% Physical Constants

c = 3e5; % physconst("LightSpeed") / 1000; % nm/ps

%%%%%%%%%% Dispersion Transfer Function

dispersion = dispersion_0 + dispersion_slope*(signal_central_wavelength - wavelength_0);

beta_2 = - dispersion * signal_central_wavelength^2 / (2*pi*c);
beta_3 = dispersion_slope * signal_central_wavelength^4 / (2*pi*c)^2;

beta = @(dw) (beta_2*dw^2)/2 + (beta_3*dw^3)/6;
transfer_fun = @(dw) exp((-alpha -1j*beta(dw))*fiber_length);

%%%%%%%%%%% Simulated Dispersion
N_total = length(signal_in);
N_half = N_total / 2;
frequency_vector = (-N_half + 1:1:N_half) * f_sampling / N_total;
fiber_trans = arrayfun(transfer_fun, frequency_vector * 2 * pi);

signal_fft = fftshift(fft(signal_in));

fiber_out_fft = signal_fft .* fiber_trans;

fiber_out = ifft(ifftshift(fiber_out_fft));

if plot_en
    figure();
    subplot(2,1,1);
    plot(frequency_vector, abs(signal_fft));
    title('Input pulse')
    xlabel('ferquency (THz)')
    ylabel('I(f)')

    subplot(2,1,2);
    plot(frequency_vector, abs(fiber_out_fft));
    title('Output pulse')
    xlabel('frquency (THz)')
    ylabel('I(f)')

    fprintf("Bandwidth Sim In = %.2f GHz\n", pulsewidth(abs(signal_fft), frequency_vector) * 1000);
end
end
