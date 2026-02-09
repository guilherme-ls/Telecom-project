%%%%% bch_decoder %%%%%
%%%%% Arguments:
%%%%% - y : Column vector representation of the y(x) received input polynomial
%%%%% - g : Column vector representation of the g(x) polynomial
%%%%% Return:
%%%%% - m_hat : Column vector representation of the closest predicted m(x) 
function [m_hat, err] = bch_decoder(y, g, syndrome_table_file)
    arguments
        y (:,1)
        g (:,1)
        syndrome_table_file string  = "syndrome-table.mat"
    end

%%% If the syndrome table was already generated, don't regenerate it
if exist(syndrome_table_file, 'file')
    disp("Loading syndrome table...\n");
    load(syndrome_table_file,"synd_table")
else
    disp("Generating syndrome table...\n");
    synd_table = bch_syndrome_table_gen(length(y), g, 1);
    save(syndrome_table_file, "synd_table",'-mat');
end

%%% Calculate syndrome and turn it into a integer representation
synd = bch_mod_g(y,g);
synd_int = bit2int(synd, length(synd));

%%% Error calculation
if synd == 0
    disp("No errors!\n")
    err = zeros(length(y), 1);
else
    err = synd_table{synd_int}; %%% Get the error from the syndrome table
end

y_hat = mod(y + err, 2); %%% Error elimination
m_hat = y_hat(length(g):1:end); %%% Because this is using the systematic format, m(x) is appended at the end of y(x)

end
