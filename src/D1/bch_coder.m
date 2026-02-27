%%%%% bch_coder %%%%%
%%%%% Arguments:
%%%%% - m : Column vector representation of the m(x) data input polynomial
%%%%%       If m is a matrix, its size(m, 2) will be executed in parallel 
%%%%% - g : Column vector representation of the g(x) polynomial
%%%%% Return:
%%%%% - y : Column vector representation of the code word 
%%%%%       if m is a matrix, y will also be a matrix with size(y,2) = size(m,2)
function [y] = bch_coder(m, g)
    g_deg = length(g);
    shifted_m = [zeros(g_deg - 1, size(m, 2)); m]; %% m(x) shifted by n - k 
    parity_bits = bch_mod_g(shifted_m, g);
    y = [parity_bits; m];
end
