function [h] = impulse_h_calculator(fiber_config, photo_detector, bit_rate, wavelength_0, signal_central_wavelength)
    symbol_rate = bit_rate; % GSymbols/s
    symbol_period = 1000 / symbol_rate; % ps
    symbol_period_seconds = symbol_period / 1e12; % s

    % Define impulse vector
    impulse_length = 31;
    impulse_center = 16;
    tx_impulse = zeros(impulse_length, 1);
    tx_impulse(impulse_center) = 1;
    
    % Create noiseless laser to focus only on h
    laser_config_h = make_emlaser('P_opt_dBm', 0);
    photodetector_config_h = make_photodetector(...
        'sensitivity', photo_detector.sensitivity, ...
        'B_e', photo_detector.electrical_bw, ...
        'B_opt', photo_detector.optical_bw, ...
        'R_load', photo_detector.r_load, ...
        'N_th', 0);

    %%%% TX OPTICAL FIELD %%%%
    [tx_optical_field, ~, ~] = ...
        TX_optical_eml(tx_impulse, symbol_period_seconds, laser_config_h);
    
    %%%% TX PULSE CREATION %%%%
    [tx_pulse, ~, ~, f_sampling, ~] = square_pulse(fiber_config, 1, symbol_period,...
        wavelength_0, signal_central_wavelength);

    %%%% UPSAMPLING OF tx_optical_field and PULSE CREATION
    tx_upsampling_ratio = ceil(symbol_period * f_sampling);
    tx_upsampled_optical_field = upsample(tx_optical_field, tx_upsampling_ratio, floor(tx_upsampling_ratio/2));

    %%%% CONVOLUTION WITH PULSE
    tx_symbol_pulses = conv(tx_upsampled_optical_field, tx_pulse, 'same');

    %%%% FIBER TRANSMISSION %%%%
    [rx_symbol_pulses, ~] = singlemode_fiber(fiber_config, wavelength_0, ...
        signal_central_wavelength, tx_symbol_pulses', f_sampling, false);

    %%%% RX PHOTO CURRENT %%%%
    actual_rx_Ts_seconds = (1 / f_sampling) * 1e-12;
    [rx_photo_current, ~, ~, ~] = ...
        RX_photodetector(rx_symbol_pulses, actual_rx_Ts_seconds, ...
        0, photodetector_config_h);

    %%%% DOWNSAMPLING RX GAUSSIAN 
    h_sampled_photo_current = rx_photo_current(floor(tx_upsampling_ratio/2):tx_upsampling_ratio:end);

    h = h_sampled_photo_current / norm(abs(h_sampled_photo_current));
    disp(h)
end