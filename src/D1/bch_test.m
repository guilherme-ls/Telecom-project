%%%%% BCH Coding Test %%%%%%
%%%%% Arguments:
%%%%% - simulation_params : A struct containing the simulation parameters. Check bellow for the struct details. 
%%%%% - system_params : A struct containing the system parameters. Check bellow for the struct details. 
%%%%% Return:
%%%%% - ber_per_snr : A vector with the BER's found for each requested SNR.
%%%%% - throughput_per_snr : A vector with the Throughputs found for each requested SNR.
%%%%% Details:
%%%%% - simulation_params fields:
%%%%%   - syndrome_table_file_fmt : The string holding the file format of the syndrome table file.
%%%%%   - min_frame_number : The minimal amount of frames to run in parallel in each simulation iteration.
%%%%%   - min_error_bits_per_snr : One of the simulations stop conditions, the minimal amount of error bits detected to stop the iterations for a specific SNR. 
%%%%%   - max_snr_simulation_iterations : One of the simulations stop conditions, the maximal amount of iterations a specific SNR can have.
%%%%%   - max_simultaneous_frame_simulation : The maximal amount of frames to be simulated in the same simulation iteration.
%%%%% - system_params fields:
%%%%%  - frame_size : The size of a single simulated frame.
%%%%%  - modulation : The modulation type.
%%%%%  - M : The size of the constellation for the modulation.
%%%%%  - channel : The channel to be used for the simulation.
%%%%%  - equalization : The equalizer to be used in the simulation.
%%%%%  - bch_code_option : The BCH code to be used, "0" means none.
%%%%%  - Ts : The time interval of each symbol.
%%%%%  - normalize_symbol_energy : Selects if Es = 1 or Eb = 1.
%%%%%  - snr_bits : The interval of SNR values for the simulation to run on.
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

Ts = system_params.Ts;
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
      snr = snr - 10*log10(log2(M));
    end
    N0 = 1./10.^(snr/10) / r;
    err_per_bit_total = 0;
    err_total = 0;
    throughput_total = 0;
    %% Sends a given number of frames through the channel and calculates error
    snr_iteration = 1; %last_snr_iteration;
    while err_total < min_error_bits_per_snr && snr_iteration <= max_snr_simulation_iterations
        frame_number = min(min_frame_number*(snr_bits(ii) + last_snr_iteration)*snr_iteration, max_simultaneous_frame_simulation);
        %disp(sprintf("\t Simultaneous frames = %d", frame_number));
        %tic;
        [m_c_total, m_total] = frame_generation(n, k, g, M, frame_size, frame_number, bch_code_option);
        frame_bits = channel_simulation(m_c_total, N0, modulation, M, channel, frame_size, equalization);
        [errors_per_frame, errors_per_bit, amount_of_errors] = frame_decode_compare(m_total, frame_bits, g, t, syndrome_table, n, k);

        err_per_bit_total = err_per_bit_total + errors_per_bit;
        err_total = err_total + amount_of_errors;
        frame_sucess = sum(errors_per_frame == 0);
        message_bits_per_frame = k * floor(size(frame_bits, 1) / n);
        frame_sucess_rate = frame_sucess * message_bits_per_frame / (frame_size * Ts);
        throughput_total = throughput_total + frame_sucess_rate / length(errors_per_frame);
        %throughput_total = throughput_total + frame_sucess * message_bits_per_frame / (frame_size * Ts);
        snr_iteration = snr_iteration + 1;
        %toc
    end

    disp(sprintf("\t Total amount of errors found = %d | BER = %d | FSR = %d | T = %d\n", ...
                     err_total, err_per_bit_total/(snr_iteration - 1), ...
                     frame_sucess, throughput_total/(snr_iteration - 1)));
    %% Calculates final BER
    %disp(sprintf("\t -- Snr Iterations = %d --", snr_iteration - 1));
    ber = err_per_bit_total / (snr_iteration - 1);
    %throughput_total
    %snr_iteration
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
