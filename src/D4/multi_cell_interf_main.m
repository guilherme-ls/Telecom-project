clear;
close all;

N_symb = 100; % Symbols
system_bandwidth = 30e6; % Hz
band_rolloff = 0.5;
available_bandwidth = system_bandwidth / (1 + band_rolloff);
max_constalation_size = 4; % bit / Symbol - 16QAM
system_total_rate = max_constalation_size * available_bandwidth; % bit/s

Dmax = 2000; % m
c = 3e8; % m/s
carry_frequency = 2.4e9; % Hz
carry_lamdba = c / carry_frequency; % m
Pmax = 20; % dBm

noise_spectral_density = -174; % dBm / Hz

Ts = 1 / available_bandwidth; % s
MC = 1000; %%number of Monte-Carlo simulations

user_rate = 40e6; % bit/s

cells_to_simulate = 3; %3;
xx_cells_origins = ((0:1:(cells_to_simulate-1)) - floor(cells_to_simulate / 2)) * Dmax;

ber_plot_args = cell(2, 1);
plot_label_args = cell(1, 1);

Kmax = system_total_rate / user_rate;
K = 1;

powers = 0:1:Pmax;
total_ber = zeros(cells_to_simulate, length(powers));
for ii=1:length(powers)
    P = powers(ii);
    aux = zeros(cells_to_simulate, 1);

    for mm=1:MC
    	xx = (rand(1, cells_to_simulate) - 0.5) * Dmax + xx_cells_origins; 
	    xx_to_cell = repmat(xx, cells_to_simulate, 1) - repmat(xx_cells_origins',  1, cells_to_simulate);
    	yy_to_cell = repmat((rand(1, cells_to_simulate) - 0.5) * Dmax, cells_to_simulate, 1);
	
    	d2_to_cell = xx_to_cell.^2 + yy_to_cell.^2;%% square-distance from the origin

    	friss_attenuation_factor = carry_lamdba^2 / (4*pi)^2;
    	a2_to_cell = min(1, friss_attenuation_factor ./ d2_to_cell)';% square magnitude attenuation in Friis equation 
    	a2_to_cell_dB = 10*log10(a2_to_cell); % dB

    	Es_tx_to_cell_dBm = P - 10*log10(available_bandwidth); % dBm / Hz, dB mJ 
    	Es_rx_to_cell_dBm = Es_tx_to_cell_dBm + a2_to_cell_dB; % dBm / Hz, dB mJ 
	    Es_rx_to_cell = 10.^(Es_rx_to_cell_dBm / 10); % mJ
    	
    	tx_bit_stream = randi([0, 1], N_symb, cells_to_simulate);
	    tx_symbol_stream = reshape(bits2symbols(tx_bit_stream(:), 'PSK', 2), N_symb, cells_to_simulate);
        
	    %H = eye(N_symb); Channel 0
      N0 = 10^(noise_spectral_density/10);
	    noise = sqrt(N0 / 2) * randn(N_symb, cells_to_simulate);
      y = zeros(N_symb, cells_to_simulate);
      for jj=1:cells_to_simulate
        signal_ampl = sqrt(Es_rx_to_cell(jj, :) / 2);
    	  y(:, jj) = tx_symbol_stream * signal_ampl' + noise(:, jj);
      end
	    [s_hat_matrix, ~] = threshold_detector(y(:), 'PSK', 2);
      s_hat = reshape(s_hat_matrix, N_symb, cells_to_simulate);
    	rx_bit_stream = reshape(symbols2bits(s_hat(:), 'PSK', 2)', N_symb, cells_to_simulate);

    	ber = sum(tx_bit_stream ~= rx_bit_stream, 1)' / N_symb;
    	aux = aux + ber;
    end
    total_ber(:, ii) = aux/MC;
end
ber_plot_args(:) = {powers, total_ber(2, :)};

%% Channel display
semilogy(ber_plot_args{:});
grid;
title("Peformance in multicell interference");
%legend(plot_label_args{:});
xlabel('Power (dBm)');
ylabel('BER');
