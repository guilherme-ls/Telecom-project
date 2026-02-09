%%%%% BCH Coding Test %%%%%%
clear all;

%%%% Simulation/Configuration Parameters %%%%
syndrome_table_file_fmt = "syndrome-table-%d.mat";

%%%% BCH Code Parameters %%%%
n = 31;
k = 26;

bch_code_option = "1"; %"2"
if bch_code_option == "1"
  g = [1; 0; 1; 0; 0; 1];
  t = 1;
else
  g = [1; 0; 1; 0; 0; 1];
  t = 2;
end

syndrome_table_file = sprintf(syndrome_table_file_fmt, t); %% Syndrome file table based on the amount of corrected errors
%%%%%% Simulation %%%%%%

%%%% Data input generation %%%%
m = zeros(k, 1);
m(1) = 1;

%%%% BCH code encoding %%%
y = bch_coder(m, g)

%%%% BPSK Symbol generation %%%

%TODO%

%%%% Channel model with noise %%%%

%%%% BPSK Receiver and symbol detection

%%%% BCH Code decoding %%%

[m_hat, err] = bch_decoder(y, g, t, syndrome_table_file);

%%%% Total amount of error bits

err_bits = sum(mod(m_hat + m, 2));

fprintf("%d error bits! (%s)\n", err_bits, mat2str(err));

