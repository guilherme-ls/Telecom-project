%%%%% BCH Coding Test %%%%%%
clear all;

%%%% Simulation/Configuration Parameters %%%%
syndrome_table_file_fmt = "syndrome-table-%d.mat";
N0 = 1;
%%%% Constelation Parameters %%%%

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
m = zeros(k, 1);
m(1) = 1;

%%%% BCH code encoding %%%
m_c = bch_coder(m, g);

%%%% BPSK Symbol generation %%%

x = bits2symbols(m_c,modulation,M);
%%%% Channel model with noise %%%%

noise = N0 * randn(length(x),1);
y = x + noise;
%%%% BPSK Receiver and symbol detection

%%%%% Symbol Decoding

[s_hat, loc] = threshold_detector(y,modulation,M);

m_c_hat = symbols2bits(s_hat,modulation,M)';
%%%% BCH Code decoding %%%

[m_hat, err] = bch_decoder(m_c_hat, g, t, syndrome_table);

%%%% Total amount of error bits

err_bits = sum(mod(m_hat + m, 2));

fprintf("Received message = %s\n", mat2str(m_hat));
if sum(err) != 0
  fprintf("Error found e = %s\n", mat2str(err));
else
  fprintf("No errors!\n");
end
fprintf("%d error bits!\n", err_bits);

