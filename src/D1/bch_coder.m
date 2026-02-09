
clear all;
n = 31;
k = 26;
m = zeros(k, 1);
m(1) = 1;
g = [1; 0; 1; 0; 0; 1];

y = [bch_mod_g([zeros(n - k, 1); m],g); m];

%%% TODO TURN SYMBOL TO BPSK AND ADD NOISE

[m_hat, err] = bch_decoder(y, g, "syndrome-table.mat");

err_bits = sum(err);

fprintf("%d error bits! (%s)\n", err_bits, mat2str(err));

