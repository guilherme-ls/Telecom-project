function [synd_table] = bch_syndrome_table_gen(n, g, e_num)
    for ii=1:n
        e = zeros(n, 1);
        e(ii) = 1;
        synd = bch_mod_g(e, g);
        fprintf("Synd: %d Err: %s\n", bit2int(synd, length(synd)), mat2str(e))
        synd_table{bit2int(synd, length(synd))} = e;
    end
end