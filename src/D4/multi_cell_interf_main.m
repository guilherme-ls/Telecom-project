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

adjacent_cells = 2;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% CH1 CH2 CH3
equalization_modes.zf.bpsk.snr_min    = [ 9.0 13.5 21]; % Es/N0 dB

equalization_modes.dfe.bpsk.snr_min   = [ 8.6 11   13.5]; % Es/N0 dB

ber_plot_args = cell(2, 1);
plot_label_args = cell(1, 1);

Kmax = system_total_rate / user_rate;
K = 1;

powers = 0:1:Pmax;
total_ber = zeros(1, length(powers));
for ii=1:length(powers)
    P = powers(ii);
    aux=0;

    for mm=1:MC
    	xx= Dmax/1000;% rand(1,1) * Dmax / 2; 
    	yy= Dmax/1000;% rand(1,1) * Dmax / 2;

      adjacent_xx = rand(adjacent_cells, 1) * Dmax / 2;
      adjacent_xx = adjacent_xx + Dmax;
      adjacent_yy = rand(adjacent_cells, 1) * Dmax / 2;
      adjacent_yy = adjacent_yy + Dmax;

    	d2=xx.^2+yy.^2;%% square-distance from the origin
    	adjacent_d2=adjacent_xx.^2+adjacent_yy.^2;

      friss_attenuation_factor = carry_lamdba^2 / (4*pi)^2;
    	a2 = min(1, friss_attenuation_factor ./ d2)';% square magnitude attenuation in Friis equation 
    	adjacent_a2 = min(1, friss_attenuation_factor ./ adjacent_d2)';

    	a2_dB = 10*log10(a2); % dB

      Es_tx = P - 10*log10(available_bandwidth); % dBm / Hz, dB J 
      adjacent_power = 10^(P/10) .* adjacent_a2;
      
      total_noise_spectral_density = 10^(noise_spectral_density/10) ...
                                     + sum(adjacent_power) / available_bandwidth;
      %total_noise_spectral_density_dbm = 10*log10(total_noise_spectral_density);

      tx_bit_stream = randi([0, 1], N_symb, 1);
      tx_symbol_stream = tx_bit_stream * 10^(Es_tx/10);
      noise = sqrt(total_noise_spectral_density/2) * randn(N_symb, 1);
      rx_symbol_stream = tx_symbol_stream * a2 + noise;

      %%% Decoding
      rx_bit_stream = rx_symbol_stream > mean(rx_symbol_stream);
      
    	ber = sum(tx_bit_stream ~= rx_bit_stream) / N_symb;
    	aux = aux + ber;
    end
    total_ber(ii) = aux/MC;
end
ber_plot_args(:) = {powers, total_ber};
%if rate / 1e6 > 1 
%	plot_label_args(:, jj, ii) = {sprintf("%d Mb/s - %s", rate / 1e6, eq_mode_name)};
%else
%	plot_label_args(:, jj, ii) = {sprintf("%d kb/s - %s", rate / 1e3, eq_mode_name)};
%end



%% Channel display
semilogy(ber_plot_args{:});
grid;
title("Peformance in multicell interference");
%legend(plot_label_args{:});
xlabel('Power (dBm)');
ylabel('BER');
