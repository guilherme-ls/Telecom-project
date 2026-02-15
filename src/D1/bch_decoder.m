%%%%% bch_decoder %%%%%
%%%%% Arguments:
%%%%% - y : Column vector representation of the y(x) received input polynomial
%%%%% - g : Column vector representation of the g(x) polynomial
%%%%% - t : Max amount of errors the BCH code can fix 
%%%%% - syndrome_table : Dictionary associating syndromes to the errors 
%%%%% Return:
%%%%% - m_hat : Column vector representation of the closest predicted m(x) 
function [m_hat, err] = bch_decoder(y, g, t, syndrome_table)
%%% Calculate syndrome and turn it into a integer representation
syndrome = bch_mod_g(y,g);
syndrome_int = bi2de(syndrome');

%%% Error calculation
if syndrome == 0 %% No Errors!
    err = zeros(length(y), 1);
else
    err = syndrome_table{syndrome_int}; %%% Get the error from the syndrome table
end

y_hat = mod(y + err, 2); %%% Error elimination
m_hat = y_hat(length(g):1:end); %%% Because this is using the systematic format, m(x) is appended at the end of y(x)
end
