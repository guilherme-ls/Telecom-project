%%%%% bch_syndrome_table_file %%%%%
%%%%% Either loads or generates the requested BCH Syndrome table
%%%%% Arguments:
%%%%% - n : Size of error word
%%%%% - g : Column vector representation of the g(x) polynomial
%%%%% - e_num : Max amount of errors
%%%%% - file_name : The name of the file the syndrome table is (or should be) located at
%%%%% Return:
%%%%% - synd_table: Dictionary associating a syndrome (in integer form) to an error vector
function [synd_table] = bch_syndrome_table_file(n, g, e_num, file_name)
  %%% If the syndrome table was already generated, don't regenerate it
  if exist(file_name, 'file')
      disp("Loading syndrome table...\n");
      load(file_name,"synd_table")
  else
      disp("Generating syndrome table...\n");
      synd_table = bch_syndrome_table_gen(n, g, e_num, false);
      save(file_name, "synd_table",'-mat');
  end
end
