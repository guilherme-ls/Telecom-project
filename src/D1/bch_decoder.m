%%%%% bch_decoder %%%%%
%%%%% Arguments:
%%%%% - y : Column vector representation of the y(x) received input polynomial
%%%%% - g : Column vector representation of the g(x) polynomial
%%%%% - t : Max amount of errors the BCH code can fix 
%%%%% - syndrome_table_file : Name of the file for the syndrome table 
%%%%% Return:
%%%%% - m_hat : Column vector representation of the closest predicted m(x) 
function [m_hat, err] = bch_decoder(y, g, t, syndrome_table_file)
%%% If the syndrome table was already generated, don't regenerate it
if exist(syndrome_table_file, 'file')
    disp("Loading syndrome table...\n");
    load(syndrome_table_file,"synd_table")
else
    disp("Generating syndrome table...\n");
    synd_table = bch_syndrome_table_gen(length(y), g, t, false);
    save(syndrome_table_file, "synd_table",'-mat');
end

%%% Calculate syndrome and turn it into a integer representation
synd = bch_mod_g(y,g);
synd_int = bi2de(synd');

%%% Error calculation
if synd == 0 %% No Errors!
    err = zeros(length(y), 1);
else
    err = synd_table{synd_int}; %%% Get the error from the syndrome table
end

y_hat = mod(y + err, 2); %%% Error elimination
m_hat = y_hat(length(g):1:end); %%% Because this is using the systematic format, m(x) is appended at the end of y(x)
end
