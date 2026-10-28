clear;
close all;

%%%%%%%%%%%%%%%% Simulation Params
bit_errors_min = 100;
symbols_per_sim_step = 100;
max_symbols_per_sim_step = 300;
max_sim_step = 500;

%%%%%%%%%%%%%%%% Fiber Constants

fiber_config.alpha = 0; % db/km
fiber_config.dispersion_0 = 17; % ps/nm/km
fiber_config.dispersion_slope = 0.056; % ps/nm2/km
fiber_config.fiber_length = 100; % km

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

bit_rate = 10; % Gb/s
laser_powers = -25:0.5:-19; % dbm

equalizations = ["none", "inverse transfer function"];
codes = [0];%, 1, 2];

figure();
semilog_plot_args = cell(2, length(equalizations) * length(codes));
legend_args = cell(1, length(equalizations) * length(codes));
title('External modulation back-to-back performance');
xlabel('P_opt (dBm)');
ylabel('BER');

photo_detector.electrical_bw = 1e9 * bit_rate; % Updates detector bandwidth
symbol_rate = bit_rate; % GSymbols/s
symbol_period = 1000 / symbol_rate; % ps
symbol_period_seconds = symbol_period / 1e12; % s

counter = 1;
for jj = 1:length(codes)
    % coding part
    code = codes(jj);
    n = 31;

    if code == 1
        t = 1;
        g = [1; 0; 1; 0; 0; 1];
    elseif code == 2
        t = 2;
        g = [1; 0; 0; 1; 0; 1; 1; 0; 1; 1; 1];
    else
        g = 0;
        t = 0;
    end

    k = n - length(g) + 1;
    r = k / n;
    
    if t ~= 0
        syndrome_table_file = sprintf("syndrome-table-%d.mat", t); %% Syndrome file table based on the amount of corrected errors
        syndrome_table = bch_syndrome_table_file(n, g, t, syndrome_table_file);
    end

    for kk = 1:length(equalizations)
        equalization = equalizations(kk);
        fprintf("----------------------\n");
        fprintf("Code = %d | Equalization = %s\n", code, equalization);
        bers = zeros(1, length(laser_powers));
        last_bit_errors = 1;
        %%%% LASER
        for ii = 1:length(laser_powers)
            fprintf("\tLaser Power = %.2f dBm\n", laser_powers(ii));
            bit_errors = 0;
            total_sent_bits = 0;
            sim_steps_taken = 0;
            while bit_errors < bit_errors_min && sim_steps_taken < max_sim_step
                laser_config = make_emlaser('P_opt_dBm', laser_powers(ii) + 10*log10(r)); % considering loss from code rate
    
                %%%% PHOTO DETECTOR
    
                photodetector_config = make_photodetector(...
                    'sensitivity', photo_detector.sensitivity, ...
                    'B_e', photo_detector.electrical_bw, ...
                    'B_opt', photo_detector.optical_bw, ...
                    'R_load', photo_detector.r_load, ...
                    'N_th', photo_detector.n_th ...
                    );
    
                %%%% INPUT GENERATION %%%%
                symbols_amount = symbols_per_sim_step; % min(2^ii * symbols_per_sim_step, max_symbols_per_sim_step);
    
                tx_symbols = randi([0, 1], k * symbols_amount, 1);
                if code ~= 0
                    m = reshape(tx_symbols, k, symbols_amount);
                    tx_symbols_c = reshape(bch_coder(m, g), symbols_amount * n, 1);
                else
                    tx_symbols_c = tx_symbols;
                end
    
                %%%% TX OPTICAL FIELD %%%%
    
                [tx_optical_field, tx_sampling_period, ~] = ...
                    TX_optical_eml(tx_symbols_c, symbol_period_seconds, laser_config);
                
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
                [rx_photo_current, rx_sampling_period, ~, rx_eletrical_snr] = ...
                    RX_photodetector_coherent(rx_symbol_pulses, actual_rx_Ts_seconds, ...
                    0, photodetector_config);
    
                rx_photo_current = rx_photo_current';
                
                %%%% DOWNSAMPLING RX GAUSSIAN 
                %rx_sampled_photo_current = rx_photo_current(floor(tx_upsampling_ratio/2):tx_upsampling_ratio:end);

                %%%% DIGITAL EQUALIZATION AND SYMBOL DETECTION
                if strcmp(equalization, "none")
                    rx_sampled_photo_current = rx_photo_current(floor(tx_upsampling_ratio/2):tx_upsampling_ratio:end);
                    rx_symbols = rx_sampled_photo_current > mean(rx_sampled_photo_current);
                else
                    [rx_photo_current_eq, ~] = digital_equalizer(fiber_config, wavelength_0, ...
                    signal_central_wavelength, rx_photo_current', f_sampling);

                    rx_sampled_photo_current_eq = rx_photo_current_eq(floor(tx_upsampling_ratio/2):tx_upsampling_ratio:end);
                    rx_sampled_photo_current_eq = abs(rx_sampled_photo_current_eq');
                    rx_symbols = rx_sampled_photo_current_eq > mean(rx_sampled_photo_current_eq);
                end
                %{
                plot(tx_symbols)
                figure();
                plot(tx_symbol_pulses)
                figure();
                plot(rx_photo_current)
                figure();
                plot(rx_symbols)
                figure();
                %}
    
                %%%% CHAIN PERFORMANCE %%%%
                bit_errors = bit_errors + sum(rx_symbols ~= tx_symbols);
                total_sent_bits = total_sent_bits + length(rx_symbols);
                sim_steps_taken = sim_steps_taken + 1;
                %return;
            end
            
            fprintf("\t\tBit Errors %d / %d\n",...
                bit_errors, total_sent_bits);
            
            last_bit_errors = bit_errors;
            bers(ii) = bit_errors / total_sent_bits;
            if bit_errors == 0
                break;
            end
        end
        semilog_plot_args(:, counter) = {laser_powers; bers};
        legend_args(:, counter) = {sprintf("Code = %d | Equalization = %s", code, equalization)};
        counter = counter + 1;
    end
end
semilogy(semilog_plot_args{:});
title('BER for different rates');
xlabel('Laser Power (dBm)');
ylabel('BER');
legend(legend_args{:}, 'Location','southwest');



