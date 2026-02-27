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
simulation_params.max_snr_simulation_iterations = 20;
simulation_params.max_simultaneous_frame_simulation = 1000;


%%%% Simulated simulation types %%%%

%%%%%% Simulations for BCH Simulation Part %%%%%%
%for bch=0:2
%  bch_sims.(sprintf("bch%d", bch)) = struct(
%                       "frame_size", 100,
%                       "modulation", 'PSK',
%                       "M", 2,
%                       "channel", 0,
%                       "equalization", '',
%                       "bch_code_option", bch,
%                       "snr_bits", [0:1:10]);
%end
%
%simulations.bch_sims = bch_sims;

%%%%%% Simulations for Equalizers and Channels Simulation Part %%%%%%
%equalizers = {"none", "ZF", "DFE"};
equalizers = {"none"};
modulations = {{"PSK", 2, [0:2:20]}, {"QAM", 8, [0:3:30]}, {"QAM", 16, [0:3:30]}};

for channel=1:1
for ii=1:length(equalizers)
for jj=1:length(modulations)
  eq = equalizers{ii};
  eq_sims.(sprintf("%d%s-%s-%d", modulations{jj}{2}, modulations{jj}{1}, eq, channel)) = struct(
                       "frame_size", 100,
                       "modulation", modulations{jj}{1},
                       "M", modulations{jj}{2},
                       "channel", channel,
                       "equalization", eq,
                       "bch_code_option", 0,
                       "snr_bits", modulations{jj}{3});
end
end
end
simulations.eq_sims = eq_sims;

%%%%%%% Simulations for Extra Part %%%%%%
%for channel=1:3
%for bch=1:2
%for ii=1:length(equalizers)
%  eq = equalizers{ii};
%  extra_sims.(sprintf("bch%d-%s-%d", bch, eq, channel)) = struct(
%                       "frame_size", 100,
%                       "modulation", 'PSK',
%                       "M", 2,
%                       "channel", channel,
%                       "equalization", eq,
%                       "bch_code_option", bch,
%                       "snr_bits", [0:2:20]);
%end
%end
%end
%
%for bch=0:2
%for ii=1:length(equalizers)
%for jj=1:length(modulations)
%  eq = equalizers{ii};
%  eq_sims.(sprintf("bch%d-%d%s-%s-%d", bch, modulations{jj}{2}, modulations{jj}{1}, eq, channel)) = struct(
%                       "frame_size", 100,
%                       "modulation", modulations{jj}{1},
%                       "M", modulations{jj}{2},
%                       "channel", 0,
%                       "equalization", eq,
%                       "bch_code_option", bch,
%                       "snr_bits", modulations{jj}{3});
%end
%end
%end
%
%simulations.extra_sims = extra_sims;

for ii=1:numfields(simulations)
  sim_group_name = fieldnames(simulations){ii};
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
  for jj=1:numfields(sim_group)
    sim_name = fieldnames(sim_group){jj};
    sim = sim_group.(sim_name);
    file_name = sprintf("%s/%s.csv", group_folder_name, sim_name);
    if exist(file_name, 'file') && ~force_generate
      disp(sprintf("File already exists, skipping %s/%s...", sim_group_name, sim_name));
    else
      disp(sprintf("Running simulation %s/%s...", sim_group_name, sim_name));
      [ber_per_snr] = bch_test(simulation_params, sim);
      dlmwrite(file_name, [sim.snr_bits', ber_per_snr]);
      if plot_graphs 
         semilogy(sim.snr_bits, ber_per_snr', 'DisplayName', sim_name);
         legend;
      end
    end
  end
  if plot_graphs 
    hold on;
  end
end

disp("Finished! :D");
