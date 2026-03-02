%%%%% bch_decoder %%%%%
%%%%% Arguments:
%%%%% - y : Column vector representation of the y(x) received input polynomial
%%%%%       If y is a matrix, its size(m, 2) will be executed in parallel 
%%%%% - g : Column vector representation of the g(x) polynomial
%%%%% - t : Max amount of errors the BCH code can fix 
%%%%% - syndrome_table : Dictionary associating syndromes to the errors 
%%%%% Return:
%%%%% - m_hat : Column vector representation of the closest predicted m(x) 
%%%%%           If y is a matrix, m_hat will also be a matrix with size(m_hat, 2) = size(y, 2)
function [m_hat, err] = bch_decoder(y, g, t, syndrome_table)
    %%% Calculate syndrome and turn it into a integer representation
    syndrome = bch_mod_g(y,g);
    %[~, syndrome_ind, error_ind] = intersect(syndrome', syndrome_table.synd_mat', "rows");
    %%%% Error calculation
    %err = zeros(size(y, 1), size(y, 2));
    %err(:, syndrome_ind) = syndrome_table.err_mat(:, error_ind);
    %%%% Error elimination
    %y_hat = mod(y + err, 2);
    %%%% Retrieving m_hat from the end of y_hat, as we are using the systematic coding form
    %m_hat = y_hat(length(g):1:end, :);
    syndrome_int(1, :) = bi2de(syndrome(1:end, :)', "left-msb");
    err = zeros(size(y, 1), size(y, 2));
    %%% Error calculation
    %%% TODO Vectorize this! This is the last major bottleneck I was able to find
    for ii = 1:size(y, 2)
        if syndrome(1:end, ii) == 0 %% No Errors!
            err_v = zeros(size(y, 1), 1);
        elseif syndrome_int(ii) <= size(syndrome_table, 2)
            err_v = syndrome_table{syndrome_int(ii)}; %%% Get the error from the syndrome table
        else
            err_v = zeros(size(y, 1), 1);
        end
        if isempty(err_v)
            err_v = zeros(size(y, 1), 1);
        end
        err(1:end, ii) = err_v;
    end
    y_hat = mod(y + err, 2); %%% Error elimination
    m_hat = y_hat(length(g):1:end, :); %%% Because this is using the systematic format, m(x) is appended at the end of y(x)
end
