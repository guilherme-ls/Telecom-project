%%%%% BCH Coding Test %%%%%%
function [ber_per_snr, throughput_per_snr] = bch_test(simulation_params, system_params)

%%%% Simulation/Configuration Parameters %%%%
syndrome_table_file_fmt = simulation_params.syndrome_table_file_fmt;
min_frame_number = simulation_params.min_frame_number;
min_error_bits_per_snr = simulation_params.min_error_bits_per_snr;
max_snr_simulation_iterations = simulation_params.max_snr_simulation_iterations;
max_simultaneous_frame_simulation = simulation_params.max_simultaneous_frame_simulation;

%%%% General System Parameters (to configure according to preferences) %%%%
frame_size = system_params.frame_size;
modulation = system_params.modulation;
M = system_params.M;
channel = system_params.channel;
equalization = system_params.equalization;
bch_code_option = system_params.bch_code_option;
normalize_symbol_energy = system_params.normalize_symbol_energy;

snr_bits = system_params.snr_bits;

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
snr_length = length(snr_bits);
ber_per_snr = zeros(snr_length, 1);
throughput_per_snr = zeros(snr_length, 1);
last_snr_iteration = 1;
%% Calculates BER for each SNR
for ii = 1:snr_length
    disp(sprintf("Simulating snr %d dB", snr_bits(ii)));
    snr = snr_bits(ii);
    if normalize_symbol_energy
      % analysing the bits2symbols code provided, it considers Eb=1, not Es=1 as in the TE02 subject
      snr = snr + 10*log10(log2(M));
    end
    N0 = 1./10.^(snr/10) / r;
    err_per_bit_total = 0;
    err_total = 0;
    throughput_total = 0;
    %% Sends a given number of frames through the channel and calculates error
    snr_iteration = 1; %last_snr_iteration;
    while err_total < min_error_bits_per_snr && snr_iteration <= max_snr_simulation_iterations
        frame_number = min(min_frame_number*(snr_bits(ii) + last_snr_iteration)*snr_iteration, max_simultaneous_frame_simulation);
        disp(sprintf("\t Simultaneous frames = %d", frame_number));
        tic;
        [m_c_total, m_total] = frame_generation(n, k, g, M, frame_size, frame_number, bch_code_option);
        frame_bits = channel_simulation(m_c_total, N0, modulation, M, channel, frame_size, equalization);
        [errors_per_frame, errors_per_bit, amount_of_errors] = frame_decode_compare(m_total, frame_bits, g, t, syndrome_table, n, k);

        err_per_bit_total = err_per_bit_total + errors_per_bit;
        err_total = err_total + amount_of_errors;
        frame_sucess = sum(errors_per_frame == 0);
        frame_sucess_rate = frame_sucess * k / (frame_size * log2(M));
        throughput_total = throughput_total + frame_sucess_rate / length(errors_per_frame) ;
        snr_iteration = snr_iteration + 1;
        toc
        disp(sprintf("\t Total amount of errors found = %d | BER = %d | T = %d\n", 
                         err_total, err_per_bit_total/(snr_iteration - 1),
                         throughput_total/(snr_iteration - 1)));
    end
    %% Calculates final BER
    disp(sprintf("\t -- Snr Iterations = %d --", snr_iteration - 1));
    ber = err_per_bit_total / (snr_iteration - 1);
    throughput_total
    snr_iteration
    throughput = throughput_total / (snr_iteration - 1);
    ber_per_snr(ii) = ber;
    throughput_per_snr(ii) = throughput;
    last_snr_iteration = snr_iteration;
    if ber == 0 
      disp("BER was 0, expecting that this trend will continue. Terminating early...");
      break;
    end
end

end
