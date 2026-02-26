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
    syndrome_int(1, :) = bi2de(syndrome(1:end, :)', "left-msb");
    err = zeros(size(y, 1), size(y, 2));
    %%% Error calculation
    for ii = 1:size(y, 2)
        if syndrome(1:end, ii) == 0 %% No Errors!
            err(1:end, ii) = zeros(size(y, 1), 1);
        else
            err(1:end, ii) = syndrome_table{syndrome_int(ii)}; %%% Get the error from the syndrome table
        end
        if isempty(err)
            err(1:end, ii) = zeros(size(y, 1), 1);
        end
    end
    y_hat = mod(y + err, 2); %%% Error elimination
    m_hat = y_hat(length(g):1:end, :); %%% Because this is using the systematic format, m(x) is appended at the end of y(x)
end
