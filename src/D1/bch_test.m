%%%%% BCH Coding Test %%%%%%
clear all;

%%%% Simulation/Configuration Parameters %%%%
syndrome_table_file_fmt = "syndrome-table-%d.mat";
N0 = 1;
simulation_times = 200;
%%%% Constelation Parameters %%%%

frame_size = 100;
% PBSK
modulation = 'PAM'; %% 'PAM','PSK','QAM'
M = 2;

%%%% BCH Code Parameters %%%%
n = 31;

bch_code_option = "1";
if bch_code_option == "1"
  t = 1;
  g = [1; 0; 1; 0; 0; 1];
else
  t = 2;
  g = [1; 0; 0; 1; 0; 1; 1; 0; 1; 1; 1];
end

k = n - length(g) + 1;

syndrome_table_file = sprintf(syndrome_table_file_fmt, t); %% Syndrome file table based on the amount of corrected errors
syndrome_table = bch_syndrome_table_file(n, g, t, syndrome_table_file);
%%%%%% Simulation %%%%%%

%%%% Data input generation %%%%
snr_bits = [0:2:20];
snr_length = length(snr_bits);
ber_per_snr = zeros(snr_length, 1);
for ii = 1:snr_length
    snr_symbol = snr_bits(ii) + 10*log10(log2(M));
    N0 = 1./10.^(snr_symbol/10);
    err_total = 0;
    for jj = 1:simulation_times
        m = randi([0 1], k, 1);
        [err, err_bits] = channel_simulation(m, g, t, syndrome_table, N0, modulation, M, 2, frame_size, "DFE");
        err_total = err_total + err_bits;
    end
    ber = (err_total) / (simulation_times * k);
    ber_per_snr(ii) = ber;
end

semilogy(snr_bits,ber_per_snr);
grid;
xlabel('Eb/No (in dB)');
ylabel('BER');
