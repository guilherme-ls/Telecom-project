clear;
close all;

%%%%%%%%%%%%%%%% Simulation Params
symbols_to_simulate = 10;

%%%%%%%%%%%%%%%% Fiber Constants

fiber_config.alpha = 0; %0.2; % db/km
fiber_config.dispersion_0 = 17; % ps/nm/km
fiber_config.dispersion_slope = 0.09; % ps/nm2/km

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
fiber_lengths = [20]; % Km
laser_current = [0.0070*10]; % A

laser_config = make_laser_simple('v', c_nm / signal_central_wavelength);

%figure();
semilog_plot_args = cell(2, length(bit_rates), length(fiber_lengths));
legend_args = cell(1, length(bit_rates), length(fiber_lengths));
%title('Direct modulation performance');
%xlabel('P_opt (dBm)');
%ylabel('BER');


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
                tx_symbols = [0, 1, 0, 0, 0, 0, 0] ; %randi([0, 1], symbols_to_simulate, 1);

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
                figure()
                plot(abs(tx_optical_field));
                hold on;
                plot(abs(rx_symbol_pulses));
        end
        semilog_plot_args(:, jj, kk) = {laser_current; bers};
        legend_args(:, jj, kk) = {sprintf("Rb = %.1f Gb/s, L %.1f Km", bit_rate, fiber_length)};
    end
end
%semilogy(semilog_plot_args{:});
%title('BER for different rates');
%xlabel('Laser Mean Current (mA)');
%ylabel('BER');
%ax = gca;
%ax.LineStyleOrder = ["-"; "--"; "-o"];
%legend(legend_args{:}, 'Location','southwest');



