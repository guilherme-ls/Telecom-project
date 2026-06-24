clear;
close all;

%%%%%%%%%%%%%%%% Simulation Params
bit_errors_min = 100;
symbols_per_sim_step = 5000;
max_symbols_per_sim_step = 10000;
max_sim_step = 500;
BER_threshold = 1e-3;

%%%%%%%%%%%%%%%% Fiber Constants

fiber_config.alpha = 0; %0.2; % db/km
fiber_config.dispersion_0 = 17; % ps/nm/km
fiber_config.dispersion_slope = 0.056; % ps/nm2/km

%%%%%%%%%%%%%%%% Physical Constants

c = 3e8; % physconst("LightSpeed"); % m/s

%%%%%%%%%% Transmission Constants

photo_detector.sensitivity = 1;
photo_detector.electrical_bw = 1e10;
photo_detector.optical_bw = 125e9;
photo_detector.r_load = 50;
photo_detector.n_th = 4 * 1.38 * 1e-23 * 290;

wavelength_0 = 1550; % nm
signal_central_wavelength = 1554; % nm

bit_rates = 9:1:19; % Gb/s
fiber_lengths = 0:2:100; % Km

L_sim = zeros(1, length(bit_rates));
L_theo = zeros(1, length(bit_rates));

semilog_plot_args = cell(2, length(bit_rates));

for jj = 1:length(bit_rates)
    bit_rate = bit_rates(jj);
    photo_detector.electrical_bw = 1e9 * bit_rate; % Updates detector bandwidth
    laser_power = minimum_power(photo_detector);
    symbol_rate = bit_rate; % GSymbols/s
    symbol_period = 1000 / symbol_rate; % ps
    symbol_period_seconds = symbol_period / 1e12; % s

    for kk = length(fiber_lengths):-1:1
        fiber_length = fiber_lengths(kk);
        fprintf("\tFiber Length = %.2f Km\n", fiber_length);
        last_bit_errors = 1;
        fiber_config.fiber_length = fiber_length;
        bit_errors = 0;
        total_sent_bits = 0;
        sim_steps_taken = 0;

        
        %%%% TX PULSE CREATION %%%%
        [tx_pulse, ~, ~, f_sampling, ~] = square_pulse(fiber_config, 1, symbol_period,...
            wavelength_0, signal_central_wavelength);

        laser_config = make_emlaser('P_opt_dBm', laser_power);

        %%%% PHOTO DETECTOR

        photodetector_config = make_photodetector(...
            'sensitivity', photo_detector.sensitivity, ...
            'B_e', photo_detector.electrical_bw, ...
            'B_opt', photo_detector.optical_bw, ...
            'R_load', photo_detector.r_load, ...
            'N_th', photo_detector.n_th ...
            );

        while bit_errors < bit_errors_min && sim_steps_taken < max_sim_step
            %%%% INPUT GENERATION %%%%
            symbols_amount = min(2 * symbols_per_sim_step, max_symbols_per_sim_step);

            tx_symbols = randi([0, 1], symbols_amount, 1);

            %%%% TX OPTICAL FIELD %%%%

            [tx_optical_field, tx_sampling_period, ~] = ...
                TX_optical_eml(tx_symbols, symbol_period_seconds, laser_config);

            %%%% UPSAMPLING OF tx_optical_field
            tx_upsampling_ratio = ceil(symbol_period * f_sampling);
            tx_upsampled_optical_field = upsample(tx_optical_field, tx_upsampling_ratio, floor(tx_upsampling_ratio/2));

            %%%% CONVOLUTION WITH PULSE
            tx_symbol_pulses = conv(tx_upsampled_optical_field, tx_pulse, 'same');
            tx_pulse_period = length(tx_pulse);

            %%%% FIBER TRANSMISSION %%%%
            [rx_symbol_pulses, ~] = singlemode_fiber(fiber_config, wavelength_0, ...
                signal_central_wavelength, tx_symbol_pulses', f_sampling, false);

            %%%% RX PHOTO CURRENT %%%%
            actual_rx_Ts_seconds = (1 / f_sampling) * 1e-12;
            [rx_photo_current, rx_sampling_period, ~, rx_eletrical_snr] = ...
                RX_photodetector(rx_symbol_pulses, actual_rx_Ts_seconds, ...
                0, photodetector_config);

            rx_photo_current = rx_photo_current';

            %%%% DOWNSAMPLING RX GAUSSIAN
            rx_sampled_photo_current = rx_photo_current(floor(tx_upsampling_ratio/2):tx_upsampling_ratio:end);
            %%%% RX SYMBOL DETECTION %%%%
            rx_symbols = rx_sampled_photo_current > mean(rx_sampled_photo_current);

            %%%% CHAIN PERFORMANCE %%%%
            bit_errors = bit_errors + sum(rx_symbols ~= tx_symbols);
            total_sent_bits = total_sent_bits + length(rx_symbols);
            sim_steps_taken = sim_steps_taken + 1;
            
            %{    
            plot(tx_symbol_pulses)
            figure();
            plot(rx_symbol_pulses)
            figure();
            plot(rx_photo_current)
            figure();
            %}

            last_bit_errors = bit_errors;
            
        end
        fprintf("\t\t\tBit Errors %d / %d \n",...
                bit_errors, total_sent_bits);

        if bit_errors/total_sent_bits < BER_threshold
            L_sim(jj) = fiber_length;
            break;
        end
    end

    L_theo(jj) = theoretical_lmax(fiber_config, bit_rate, wavelength_0, signal_central_wavelength);
end

semilog_plot_args(:, 1) = {bit_rates; L_sim};
legend_args(:, 1) = {"Simulation"};
semilog_plot_args(:, 2) = {bit_rates; L_theo};
legend_args(:, 2) = {"Theoretical"};


figure();
semilogy(semilog_plot_args{:});
title('L_{max} dependency on data rates');
xlabel('R_b (Gbit/s)');
ylabel('L_{max}');
ax = gca;
ax.LineStyleOrder = ["-"; "--"; "-o"];
legend(legend_args{:}, 'Location','southwest');



