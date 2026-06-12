clear;
close all;

N_symb = 100; % Symbols
system_bandwidth = 30e6; % Hz
band_rolloff = 0.5;
available_bandwidth = system_bandwidth / (1 + band_rolloff);
max_constalation_size = 4; % bit / Symbol - 16QAM
system_total_rate = max_constalation_size * available_bandwidth; % bit/s

Dmax = 2000; % m
c = 3e8; % m/s
carry_frequency = 2.4e9; % Hz
carry_lamdba = c / carry_frequency; % m
Pmax = 20; % dBm

noise_spectral_density = -174; % dBm / Hz
%noise_power_dbm = noise_spectral_density + 10*log10(available_bandwidth); % dBm

Ts = 1 / available_bandwidth; % s
MC = 1000; %%number of Monte-Carlo simulations

user_rates = [40e3 400e3 4e6 40e6]; % bit/s
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% CH1 CH2 CH3
equalization_modes.zf.bpsk.snr_min    = [ 9.0 13.5 21]; % Es/N0 dB
equalization_modes.zf.m8qam.snr_min   = [11.5 16.4 24]; % Eb/N0 dB
equalization_modes.zf.m8qam.snr_min   = equalization_modes.zf.m8qam.snr_min + 10*log10(log2(8)); % Es/N0 dB
equalization_modes.zf.m16qam.snr_min  = [13.2 16.6 25.7]; % Eb/N0
equalization_modes.zf.m16qam.snr_min  = equalization_modes.zf.m16qam.snr_min + 10*log10(log2(16)); % Es/N0 dB

equalization_modes.dfe.bpsk.snr_min   = [ 8.6 11   13.5]; % Es/N0 dB
equalization_modes.dfe.m8qam.snr_min  = [11.2 13.5 16.3]; % Eb/N0 dB
equalization_modes.dfe.m8qam.snr_min   = equalization_modes.dfe.m8qam.snr_min + 10*log10(log2(8)); % Es/N0 dB
equalization_modes.dfe.m16qam.snr_min = [12.8 14.4 18.6]; % Eb/N0 dB
equalization_modes.dfe.m16qam.snr_min  = equalization_modes.dfe.m16qam.snr_min+ 10*log10(log2(16)); % Es/N0 dB

rejection_plot_args = cell(2, length(user_rates), numel(fieldnames(equalization_modes)));
plot_label_args = cell(1, length(user_rates), numel(fieldnames(equalization_modes)));

for jj=1:length(user_rates)
    rate = user_rates(jj);
    Kmax = system_total_rate / rate;
    K= [1:(floor(Kmax/20)+1):Kmax];

    for ii=1:numel(fieldnames(equalization_modes))
        eq_mode_name = fieldnames(equalization_modes);
        eq_mode_name = eq_mode_name{ii};
        eq_mode = equalization_modes.(eq_mode_name);

    	rej=zeros(1,length(K));
        for kk=1:length(K)
            aux=0;

            for mm=1:MC
            	xx= rand(K(kk), 1) * Dmax / 2; % m, Distribution of users in the x-axis
            	yy= rand(K(kk), 1) * Dmax / 2; % m, Distribution of users in the y-axis

            	d2=xx.^2+yy.^2;%% square-distance from the origin
              friss_attenuation_factor = carry_lamdba^2 / (4*pi)^2;
            	a2 = min(1, friss_attenuation_factor ./ d2)';% square magnitude attenuation in Friis equation 
            	a2_dB = 10*log10(a2); % dB
		
		          pr_rx = Pmax + a2_dB; % dBm 
		          Es_rx = pr_rx - 10*log10(available_bandwidth); % dBm / Hz 
		          SNR_rx_max = Es_rx - noise_spectral_density; %dB
		
            	SNR_min= eq_mode.m16qam.snr_min; %%ZF or DFE/16QAM: channel 1, channel 2, channel 3
            	if(rate*Ts*K(kk) < 3) SNR_min = eq_mode.m8qam.snr_min; end%%ZF or DFE/8QAM: channel 1, channel 2, channel 3
            	if(rate*Ts*K(kk) < 1) SNR_min = eq_mode.bpsk.snr_min;	end %%ZF or DFE/BPSK: channel 1, channel 2, channel 3

            	SNR_rx_min = SNR_min(randi(3,K(kk),1));
            	aux = aux + sum(SNR_rx_min > SNR_rx_max);
            end
            rej(kk)= aux/(K(kk)*MC);
        end
    	rejection_plot_args(:, jj, ii) = {K, rej};
    	if rate / 1e6 > 1 
    		plot_label_args(:, jj, ii) = {sprintf("%d Mb/s - %s", rate / 1e6, eq_mode_name)};
    	else
    		plot_label_args(:, jj, ii) = {sprintf("%d kb/s - %s", rate / 1e3, eq_mode_name)};
    	end
    end

end

%% Channel display
semilogx(rejection_plot_args{:});
grid;
title("Rejection Rate per User Amount");
legend(plot_label_args{:});
xlabel('User amount (K)');
ylabel('Rejection Rate');
