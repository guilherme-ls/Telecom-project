clear;
close all;

%%%%%%%%%%%%%%%% Simulation Params
symbols_to_simulate = 10;

%%%%%%%%%%%%%%%% Fiber Constants

fiber_config.alpha = 0; %0.2; % db/km
fiber_config.dispersion_0 = 17; % ps/nm/km
fiber_config.dispersion_slope = 0.056; % ps/nm2/km

%%%%%%%%%%%%%%%% Physical Constants

c_nm = 3e8 * 1e9; % physconst("LightSpeed"); % nm/s

%%%%%%%%%% Transmission Constants

photo_detector.sensitivity = 1;
photo_detector.electrical_bw = 1e10;
photo_detector.optical_bw = 125e9;
photo_detector.r_load = 50;
photo_detector.n_th = 2e-20;

wavelength_0 = 1550; % nm
signal_central_wavelength = 1554; % nm

bit_rates = [1]; % Gb/s
fiber_lengths = [0, 20]; % Km
laser_current = 0.007 * [10, 100, 1000]; % A

laser_config = make_laser_simple('v', c_nm / signal_central_wavelength);

eye_diagram_plot_args = cell(4, length(bit_rates), length(fiber_lengths), length(laser_current));
plot_titles = cell(1, length(bit_rates), length(fiber_lengths), length(laser_current));

for jj = 1:length(bit_rates)
    bit_rate = bit_rates(jj);
    symbol_rate = bit_rate; % GSymbols/s
    symbol_period = 1e-9 / symbol_rate; % s
    fprintf("----------------------\n");
    fprintf("Bit Rate = %d Gb/s\n", bit_rate);
    for kk=1:length(fiber_lengths)
        fiber_length = fiber_lengths(kk);
        fprintf("\tFiber Length = %.2f Km\n", fiber_length);
        bers = zeros(1, length(laser_current));
        last_bit_errors = 1;
        fiber_config.fiber_length = fiber_length;
        %%%% LASER
        for ii = 1:length(laser_current)
            fprintf("\t\tLaser Current = %.2f mA\n", laser_current(ii));

                %%%% PHOTO DETECTOR

                photodetector_config = make_photodetector(...
                    'sensitivity', photo_detector.sensitivity, ...
                    'B_e', photo_detector.electrical_bw, ...
                    'B_opt', photo_detector.optical_bw, ...
                    'R_load', photo_detector.r_load, ...
                    'N_th', photo_detector.n_th ...
                    );

                %%%% INPUT GENERATION %%%%
                tx_symbols = repmat([1, 0, 0, 1, 0 , 1, 1, 0], 1,  ceil(symbols_to_simulate/8));

                tx_symbols = laser_current(ii) * tx_symbols;

                %%%% TX OPTICAL FIELD %%%%

                [tx_optical_field, tx_sampling_period, ~] = ...
                    TX_optical_dml(tx_symbols, symbol_period, laser_config);
                tx_sampling_period_ps = tx_sampling_period * 1e12; % ps

                %%%% FIBER TRANSMISSION %%%%
                [rx_symbol_pulses, ~] = singlemode_fiber(fiber_config, wavelength_0, ...
                    signal_central_wavelength, tx_optical_field, tx_sampling_period_ps, false);

                %%%% RX PHOTO CURRENT %%%%
                [rx_photo_current, rx_sampling_period, ~, rx_eletrical_snr] = ...
                    RX_photodetector(rx_symbol_pulses, tx_sampling_period, ...
                    photo_detector.n_th, photodetector_config);

                rx_photo_current = rx_photo_current';

                %%%% DOWNSAMPLING RX GAUSSIAN
                symbol_period_samples = length(rx_photo_current) / length(tx_symbols);
                eye_diagram_plot_args(:, jj, kk, ii) = {rx_photo_current, round(symbol_period_samples*2), symbol_period_samples, round(symbol_period_samples/2) };
                plot_titles(:, jj, kk, ii) = {sprintf("Rb = %.1f Gb/s, L = %.1f Km, I = %.2f mA", bit_rate, fiber_length, laser_current(ii))};
        end
    end
end

for jj = 1:length(bit_rates)
    for kk=1:length(fiber_lengths)
        for ii = 1:length(laser_current)
          eyediagram(eye_diagram_plot_args{:, jj, kk, ii});
          title(plot_titles{:, jj, kk, ii});
        end 
    end 
end



