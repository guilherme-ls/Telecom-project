clear;
close all;

%%%%%%%%%%%%%%%% Simulation Params
bit_errors_min = 20;
symbols_per_sim_step = 1000;
max_symbols_per_sim_step = 10000;
max_sim_step = 10000;

%%%%%%%%%%%%%%%% Fiber Constants

fiber_config.alpha = 0.2; % db/km
fiber_config.dispersion_0 = 17; % ps/nm/km
fiber_config.dispersion_slope = 0.09; % ps/nm2/km
fiber_config.fiber_length = 1; % km

%%%%%%%%%%%%%%%% Physical Constants

c = 3e8; % physconst("LightSpeed"); % m/s

%%%%%%%%%% Transmission Constants

photo_detector.sensitivity = 1;
photo_detector.electrical_bw = 1e10;
photo_detector.optical_bw = 125e9;
photo_detector.r_load = 50;
photo_detector.n_th = 2e-20;

bit_rates = [2.5, 10]; % Gb/s
laser_powers = -20:0.1:-17; % dbm

figure();
semilog_plot_args = cell(2, length(bit_rates));
legend_args = cell(1, length(bit_rates));
title('External modulation back-to-back performance');
xlabel('P_opt (dBm)');
ylabel('BER');


for jj = 1:length(bit_rates)
    bit_rate = bit_rates(jj);
    symbol_rate = bit_rate; % GSymbols/s
    symbol_period = 1000 / symbol_rate; % ps
    fprintf("----------------------\n");
    fprintf("Bit Rate = %d GB/s\n", bit_rate);
    bers = zeros(1, length(laser_powers));
    %%%% LASER
    for ii = 1:length(laser_powers)
        fprintf("\tLaser Power = %.2f dBm\n", laser_powers(ii));
        bit_errors = 0;
        total_sent_bits = 0;
        sim_steps_taken = 0;
        while bit_errors < bit_errors_min && sim_steps_taken < max_sim_step
            laser_config = make_emlaser('P_opt_dBm', laser_powers(ii));

            %%%% PHOTO DETECTOR

            photodetector_config = make_photodetector(...
                'sensitivity', photo_detector.sensitivity, ...
                'B_e', photo_detector.electrical_bw, ...
                'B_opt', photo_detector.optical_bw, ...
                'R_load', photo_detector.r_load, ...
                'N_th', photo_detector.n_th ...
                );

            %%%% INPUT GENERATION %%%%
            symbols_amount = min(2^ii * symbols_per_sim_step, max_symbols_per_sim_step);

            tx_symbols = randi([0, 1], symbols_amount, 1);

            %%%% TX OPTICAL FIELD %%%%

            [tx_optical_field, tx_sampling_period, ~] = ...
                TX_optical_eml(tx_symbols, symbol_period, laser_config);

            %%%% FIBER TRANSMISSION %%%%

            rx_optical_field = tx_optical_field;


            %%%% RX PHOTO CURRENT %%%%
            [rx_photo_current, rx_sampling_period, ~, rx_eletrical_snr] = ...
                RX_photodetector(rx_optical_field, tx_sampling_period, ...
                photo_detector.n_th, photodetector_config);

            %%%% RX SYMBOLS %%%%
            rx_symbols = rx_photo_current > mean(rx_photo_current);

            %%%% CHAIN PERFORMANCE %%%%
            bit_errors = bit_errors + sum(rx_symbols ~= tx_symbols);
            total_sent_bits = total_sent_bits + length(rx_symbols);
            sim_steps_taken = sim_steps_taken + 1;
            fprintf("\t\tBit Errors %d / %d (%d / %d)\n",...
                bit_errors, total_sent_bits,...
                sim_steps_taken, max_sim_step);
        end
        bers(ii) = bit_errors / total_sent_bits;
    end
    semilog_plot_args(:, jj) = {laser_powers; bers};
    legend_args(:, jj) = {sprintf("Rb = %.1f Gb/s", bit_rate)};
end
semilogy(semilog_plot_args{:});
legend(legend_args{:}, 'Location','southwest');



