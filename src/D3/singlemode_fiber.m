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
function [fiber_out, fiber_trans] = singlemode_fiber(fiber_config, transmission_wavelength, signal_wavelength, ...
                                            signal_in, frequency_vector)
  %%%%%%%%%%%%%%%% Fiber Constants
  alpha = fiber_config.alpha; % db/km
  dispersion_0 = fiber_config.dispersion_0; % ps/nm/km
  dispersion_slope = fiber_config.dispersion_slope; % ps/nm2/km
  fiber_length = fiber_config.fiber_length; % km
  
  %%%%%%%%%%%%%%%% Physical Constants
  
  c = 3e9; % physconst("LightSpeed");
  
  %%%%%%%%%% Dispersion Transfer Function
  
  dispersion = dispersion_0 + dispersion_slope*(signal_wavelength - transmission_wavelength);
  
  beta_2 = - dispersion * signal_wavelength^2 / (2*pi*c);
  beta_3 = dispersion_slope * signal_wavelength^4 / (2*pi*c)^2;
  
  beta = @(dw) (beta_2*dw^2)/2 + (beta_3*dw^3)/6;
  transfer_fun = @(dw) exp((-alpha -1j*beta(dw))*fiber_length);
  
  %%%%%%%%%%% Simulated Dispersion
  
  fiber_trans = arrayfun(transfer_fun, frequency_vector); 
  
  signal_fft = fft(signal_in);

  fiber_out_fft = signal_fft .* fiber_trans;
  
  fiber_out = ifftshift(fftshift(fiber_out_fft));

end
