%%%%% Main Simulation Chain Script %%%%%%
%% Check all the details on how to operate it in the README %%
clear all;

%%%% DEBUG VARIABLES %%%%
plot_graphs = true;

%%%% SCRIPT OUTPUT VARIABLES %%%%
output_folder = "out";
force_generate = true;

%%%% Global Simulation Parameters %%%%
simulation_params.syndrome_table_file_fmt = "syndrome-table-%d.mat";
simulation_params.min_frame_number = 100;
simulation_params.min_error_bits_per_snr = 10;
simulation_params.max_snr_simulation_iterations = 200;
simulation_params.max_simultaneous_frame_simulation = 1000;

%%%% Response channels coeficients %%%%

[stats, ~] = mkdir(output_folder);
if stats == false
  disp(sprintf("Couldn't create folder %s", output_folder));
  assert(0);
end

%{
for ii=1:3
  file_name = sprintf("%s/response-channel-%d.csv", output_folder, ii);
  if ~exist(file_name, 'file') || force_generate
    h = response_channel(ii);
    L = (length(h) - 1) / 2;
    dlmwrite(file_name, [(-L:L)', h']);
  end
end
%%%% Simulated simulation types %%%%

%%%%%% Simulations for BCH Simulation Part %%%%%%
for bch=0:2
  bch_sims.(sprintf("bch%d", bch)) = struct( ...
                       "frame_size", 100, ...
                       "modulation", 'PSK', ...
                       "M", 2, ...
                       "channel", 0, ...
                       "equalization", '', ...
                       "bch_code_option", bch, ...
                       "snr_bits", [0:1:10], ...
                       "normalize_symbol_energy", false, ...
                       "Ts", 0.05*1e-6, ...
                       "output_throughtput", false  ...
                       );
end

simulations.bch_sims = bch_sims;
%}
%%%%%% Simulations for Equalizers and Channels Simulation Part %%%%%%
equalizers = {"none", "ZF", "DFE"};
modulations = {{"PSK", 2, [0:2:20]}, {"QAM", 8, [0:3:30]}, {"QAM", 16, [0:3:30]}};
%{
for channel=1:3
for ii=1:length(equalizers)
for jj=1:length(modulations)
  eq = equalizers{ii};
  eq_sims.(sprintf("%s%d_%s_%d", modulations{jj}{1}, modulations{jj}{2}, eq, channel)) = struct( ...
                       "frame_size", 100, ...
                       "modulation", modulations{jj}{1}, ...
                       "M", modulations{jj}{2}, ...
                       "channel", channel, ...
                       "equalization", eq, ...
                       "bch_code_option", 0, ...
                       "snr_bits", modulations{jj}{3}, ...
                       "normalize_symbol_energy", false, ...
                       "Ts", 0.05*1e-6, ...
                       "output_throughtput", false ...
                       );
end
end
end
simulations.eq_sims = eq_sims;

%%%%%% Simulations for Extra Part %%%%%%
for channel=1:3
for bch=1:2
for ii=1:length(equalizers)
  eq = equalizers{ii};
  extra_bpks.(sprintf("bch%d_%s_%d", bch, eq, channel)) = struct( ...
                       "frame_size", 100, ...
                       "modulation", 'PSK', ...
                       "M", 2, ...
                       "channel", channel, ...
                       "equalization", eq, ...
                       "bch_code_option", bch, ...
                       "snr_bits", [0:2:20], ...
                       "normalize_symbol_energy", false, ...
                       "Ts", 0.05*1e-6, ...
                       "output_throughtput", false ...
                       );
end
end
end
simulations.extra_bpks = extra_bpks;
%}
channel = 0;
equalizers = {"none"};%, "ZF", "DFE"};
modulations = {{"PSK", 2, [0:1:30]}, {"QAM", 8, [0:1:30]}, {"QAM", 16, [0:1:30]}};
for bch=0:2
for ii=1:length(equalizers)
for jj=1:length(modulations)
  eq = equalizers{ii};
  extra_throughput.(sprintf("bch%d_%d%s_%s_%d", bch, modulations{jj}{2}, modulations{jj}{1}, eq, channel)) = struct( ...
                       "frame_size", 100, ...
                       "modulation", modulations{jj}{1}, ...
                       "M", modulations{jj}{2}, ...
                       "channel", 0, ...
                       "equalization", eq, ...
                       "bch_code_option", bch, ...
                       "snr_bits", modulations{jj}{3}, ...
                       "normalize_symbol_energy", true, ...
                       "Ts", 0.05*1e-6, ...
                       "output_throughtput", true ...
                       );
end
end
end

simulations.extra_throughput = extra_throughput;

for ii=1:numel(fieldnames(simulations))
  names = fieldnames(simulations);
  sim_group_name = names{ii};
  sim_group = simulations.(sim_group_name); 

  group_folder_name = sprintf("%s/%s", output_folder, sim_group_name);
  [stats, ~] = mkdir(group_folder_name);
  if stats == false
    disp(sprintf("Couldn't create folder %s", group_folder_name));
    assert(0);
  end
  if plot_graphs 
     figure;
     grid;
     xlabel('Eb/No (in dB)');
     ylabel('BER');
     title(sprintf("Plots of %s", sim_group_name));
     hold on;
  end
  for jj=1:numel(fieldnames(sim_group))
    sim_name_list = fieldnames(sim_group);
    sim_name = sim_name_list{jj};
    sim = sim_group.(sim_name);
    file_name = sprintf("%s/%s.csv", group_folder_name, sim_name);
    if exist(file_name, 'file') && ~force_generate
      disp(sprintf("File already exists, skipping %s/%s...", sim_group_name, sim_name));
    else
      disp(sprintf("Running simulation %s/%s...", sim_group_name, sim_name));
      [ber_per_snr, throughput_per_snr] = bch_test(simulation_params, sim);
      out_per_snr = ber_per_snr;

      if sim.output_throughtput
        out_per_snr = throughput_per_snr;
      end
      dlmwrite(file_name, [sim.snr_bits', out_per_snr]);
      if plot_graphs 
        semilogy(sim.snr_bits, out_per_snr', 'DisplayName', sim_name);
        legend;
      end
    end
  end
  if plot_graphs 
    hold on;
  end
end
