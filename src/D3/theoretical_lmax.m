function [lmax] = theoretical_lmax(fiber_config, ...
                               Rb, wavelength_0, pulse_central_wavelength)
%%%%%%%%%%%%%%%% Physical Constants
  
c = 3e5; % physconst("LightSpeed") / 1000; % nm/ps
D = fiber_config.dispersion_0 + fiber_config.dispersion_slope*(pulse_central_wavelength - wavelength_0); % ps/nm/km
lambda = pulse_central_wavelength; % nm

spectral_occupation = 2 * Rb * 1e-3; % THz
lmax = c / (2 * D * lambda^2 * spectral_occupation^2);

end