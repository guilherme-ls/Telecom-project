%%%%% bch_coder %%%%%
%%%%% Arguments:
%%%%% - m : Column vector representation of the m(x) data input polynomial
%%%%% - g : Column vector representation of the g(x) polynomial
%%%%% Return:
%%%%% - y : Column vector representation of the code word 
function [y] = bch_coder(m, g)
    g_deg = length(g);
    shifted_m = [zeros(g_deg - 1, 1); m]; %% m(x) shifted by n - k 
    parity_bits = bch_mod_g(shifted_m, g);
    y = [parity_bits; m];
end
