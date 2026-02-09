%%%%% bch_syndrome_table_gen %%%%%
%%%%% Arguments:
%%%%% - n : Size of the code word 
%%%%% - g : Column vector representation of the g(x) polynomial
%%%%% - e_num : Amount of errors to calculate the syndrome table 
%%%%% - debug : Option to print the generated syndrome table for each error vector 
%%%%% Return:
%%%%% - synd_table : Dictionary associating a syndrome (in integer form) to an error vector 
function [synd_table] = bch_syndrome_table_gen(n, g, e_num, debug)
    %% Error vector generation
    err_mat = bch_error_vector_gen(n, e_num);
    fprintf("%d unique error vectors\n", size(err_mat, 2) - 1) %% Minus 1 to remove the all zeros error vector
    for ii=1:size(err_mat,2)
        e = err_mat(:,ii); %% Getting error collumn vector from error matrix
        %% Syndrome calculation
        synd = bch_mod_g(e, g);
        synd_int = bi2de(synd');
        if debug
          fprintf("Synd: %d Err: %s\n", synd_int, mat2str(e))
        end
        %% Associating syndrome to error vector
        synd_table{synd_int} = e;
    end
end

%%%%% bch_error_vector_gen %%%%%
%%%%% Arguments:
%%%%% - n : Size of error word
%%%%% - e_num : Max amount of errors
%%%%% Return:
%%%%% - err_mat: Matrix with all collumn error vectors
function [err_mat] = bch_error_vector_gen(n, e_num)
    %%% Position 0 means no error, prefixing e_num - 1 zeros to have from 1 to e_num errors vector combinations
    err_positions = [zeros(1, e_num - 1), 1:n];
    %% As there is only one 0 position in err_positions, this results in a matrix with all error combinations
    %% of both 1 error and 2 error positions
    err_combinations = nchoosek(err_positions, e_num);
    err_amount = size(err_combinations, 1);
    err_mat = zeros(n, err_amount);
    for ii=1:err_amount
      for jj=1:e_num
        if err_combinations(ii, jj) != 0 %% If there is an error (position != 0), set the bit in that position
          err_mat(err_combinations(ii,jj), ii) = 1;
        end
      end
    end
end
