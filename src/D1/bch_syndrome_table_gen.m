%%%%% bch_syndrome_table_gen %%%%%
%%%%% Arguments:
%%%%% - n : Size of the code word 
%%%%% - g : Column vector representation of the g(x) polynomial
%%%%% - e_num : Amount of errors to calculate the syndrome table 
%%%%% - debug : Option to print the generated syndrome table for each error vector 
%%%%% Return:
%%%%% - synd_table : Dictionary associating a syndrome (in integer form) to an error vector 
function [synd_table] = bch_syndrome_table_gen(n, g, e_num, debug)
    arguments
        n integer 
        g (:,1)
        e_num {mustBePositive} = 1
        debug {mustBeMember(debug,["no","yes"])} 
    end
    for ii=1:n
        %% Error vector generation
        e = zeros(n, 1);
        e(ii) = 1;
        %% Syndrome calculation
        synd = bch_mod_g(e, g);
        if debug == "yes"
          fprintf("Synd: %d Err: %s\n", bit2int(synd, length(synd)), mat2str(e))
        end
        %% Associating syndrome to error vector
        synd_table{bit2int(synd, length(synd))} = e;
    end
end
