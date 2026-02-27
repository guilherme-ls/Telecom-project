%%%%% BCH Coding Test %%%%%%
clear all;

%%%% Simulation/Configuration Parameters %%%%
syndrome_table_file_fmt = "syndrome-table-%d.mat";
min_frame_number = 100;
min_error_bits_per_snr = 3;
max_snr_simulation_iterations = 20;

%%%% General System Parameters (to configure according to preferences) %%%%
frame_size = 100;
modulation = 'QAM'; %% 'PAM','PSK','QAM'
M = 4;
channel = 1;
equalization = "DFE";
bch_code_option = 1;

%%%% BCH Code Parameters %%%%
if bch_code_option == 0
    n = frame_size * log2(M);
    k = frame_size * log2(M);
    syndrome_table = 0;
    g = 0;
    t = 0;
    r = 1;
else
    n = 31;

    if bch_code_option == 1
        t = 1;
        g = [1; 0; 1; 0; 0; 1];
    else
        t = 2;
        g = [1; 0; 0; 1; 0; 1; 1; 0; 1; 1; 1];
    end

    k = n - length(g) + 1;
    r = k / n;

    syndrome_table_file = sprintf(syndrome_table_file_fmt, t); %% Syndrome file table based on the amount of corrected errors
    syndrome_table = bch_syndrome_table_file(n, g, t, syndrome_table_file);
end

%%%%%% Simulation %%%%%%

%%%% Data input generation %%%%
snr_bits = [0:2:20];
snr_length = length(snr_bits);
ber_per_snr = zeros(snr_length, 1);
%% Calculates BER for each SNR
for ii = 1:snr_length
    disp(sprintf("Simulating snr %d dB", snr_bits(ii)));
    % snr_symbol = snr_bits(ii) + 10*log10(log2(M));
    % analysing the bits2symbols code provided, it considers Eb=1, not Es=1 as in the TE02 subject
    N0 = 1./10.^(snr_bits(ii)/10) / r;
    err_total = 0;
    %% Sends a given number of frames through the channel and calculates error
    snr_iteration = 1;
    while err_total < min_error_bits_per_snr && snr_iteration <= max_snr_simulation_iterations
        tic;
        frame_number = min_frame_number*(snr_bits(ii) + 1)*snr_iteration;
        [m_c_total, m_total] = frame_generation(n, k, g, M, frame_size, frame_number, bch_code_option);
        frame_bits = channel_simulation(m_c_total, N0, modulation, M, channel, frame_size, equalization);
        err_bits = frame_decode_compare(m_total, frame_bits, g, t, syndrome_table, n, k);
        err_total = err_total + err_bits;
        snr_iteration = snr_iteration + 1;
        toc
    end
    %% Calculates final BER
    disp(sprintf("\t - Snr Iterations = %d", snr_iteration - 1));
    ber = err_total / snr_iteration;
    ber_per_snr(ii) = ber;
    if ber == 0 
      disp("BER was 0, expecting that this trend will continue. Terminating early...");
      break;
    end
end

semilogy(snr_bits,ber_per_snr);
grid;
xlabel('Eb/No (in dB)');
ylabel('BER');

%Example how to save as csv 
%csvwrite(["bpsk-rayleight.csv"], [SNR_bit.', BER.'])
