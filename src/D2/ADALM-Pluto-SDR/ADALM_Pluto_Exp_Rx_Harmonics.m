close all;
clear;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%          Transmission Configurations                %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%% General Config %%%%%
pluto_configs.general.device_name = "Pluto";
pluto_configs.general.center_freq = 2.4e9; % Hz 
pluto_configs.general.bb_sample_rate = 30.72e6;  % Hz
pluto_configs.general.filt_rf_bw = 20e6; % Hz

%%%%% Sync Config %%%%%
pluto_configs.sync.enable = true;
pluto_configs.sync.samples = 13; % Samples in the frame
pluto_configs.sync.length = 13; % length of the barker sequence 
pluto_configs.sync.fine.damping_factor = 0.707;
pluto_configs.sync.fine.loop_bw = 0.01;
pluto_configs.sync.coarse.frequency_resolution = 100; 

%%%%% TX Config %%%%% 
pluto_configs.tx.enable = false;  
pluto_configs.tx.automatic_emmision = true;
pluto_configs.tx.gain = -10; % dB 
pluto_configs.tx.dac.scale_factor = 0.75; % [0, 1]

%%%%% RX Config %%%%% 
pluto_configs.rx.enable = true;
pluto_configs.rx.automatic_reception = true;  
pluto_configs.rx.gain.manual = true;
pluto_configs.rx.gain.value = 10;
pluto_configs.rx.bb_rrc.roll_off = 0.25;
pluto_configs.rx.bb_rrc.symbol_span = 25;

%%%%% Signal Config %%%%% 

% Raw Signal Config
pluto_configs.signal.raw.enable = true;
pluto_configs.signal.raw.harmonics.frequencies = [6.12e6];
pluto_configs.signal.raw.harmonics.width = 0.07e6;
pluto_configs.signal.raw.usable_band = 0.15e6;
pluto_configs.signal.raw.harmonics.samples = 1e5; % Samples

% Modulated Message Config
pluto_configs.signal.modulated.enable = false;
pluto_configs.signal.modulated.symbol_rate = 3e6;
pluto_configs.signal.modulated.modulation.mod = "QAM";  
pluto_configs.signal.modulated.modulation.size = 16;  

% Modulated Message Generation
signal_generation_seed = 100;
signal_length = 100e3;

rand_message_range = [0 pluto_configs.signal.modulated.modulation.size-1];

rng(signal_generation_seed);
rand_message = randi(rand_message_range, signal_length, 1);

pluto_configs.signal.modulated.message = rand_message;

%%%%% Plot Config %%%%% 
pluto_configs.plot.spectrum = true;
pluto_configs.plot.sync = false;
pluto_configs.plot.constelation = false;
pluto_configs.plot.samples = false;

%%%%% Perfomances Display Config %%%%% 
pluto_configs.performace.snr = true;
pluto_configs.performace.ser = false;
pluto_configs.performace.ber = false;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%            Call Experiment Script                   %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

ADALM_Pluto_TxRx
