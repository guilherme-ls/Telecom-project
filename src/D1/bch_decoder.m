function [x_hat, err] = bch_decoder(y, g, syndrome_table_file)
    arguments
        y
        g
        syndrome_table_file  = "syndrome-table.mat"
    end

if exist(syndrome_table_file, 'file')
    disp("Loading syndrome table...\n");
    load(syndrome_table_file,"synd_table")
else
    disp("Generating syndrome table...\n");
    synd_table = bch_syndrome_table_gen(length(y), g, 1);
    save(syndrome_table_file, "synd_table",'-mat');
end

synd = bch_mod_g(y,g);

synd_int = bit2int(synd, length(synd));

if synd == 0
    disp("No errors!\n")
    err = zeros(length(y), 1);
else
    err = synd_table{synd_int};
end

y_hat = mod(y + err, 2);
x_hat = y_hat(length(g):1:end);

end
