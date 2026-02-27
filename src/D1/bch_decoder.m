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
    [~, syndrome_ind, error_ind] = intersect(syndrome', syndrome_table.synd_mat', "rows");

    %%% Error calculation
    err = zeros(size(y, 1), size(y, 2));
    err(:, syndrome_ind) = syndrome_table.err_mat(:, error_ind);
    %%% Error elimination
    y_hat = mod(y + err, 2);
    %%% Retrieving m_hat from the end of y_hat, as we are using the systematic coding form
    m_hat = y_hat(length(g):1:end, :); 
end
