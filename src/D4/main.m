clear;
close all;

N_symb = 100; % Symbols
system_bandwidth = 30e6; % Hz
band_rolloff = 0.5;
available_bandwidth = system_bandwidth / (1 + band_rolloff);
max_constalation_size = 4; % bit / Symbol - 16QAM
system_total_rate = max_constalation_size * available_bandwidth; % bit/s

Dmax = 2; % Km
c = 3e8; % m/s
carry_frequency = 2.4e9; % Hz
carry_lamdba = c / carry_frequency;
Pmax = 20; % dBm

noise_spectral_density = -174; % dBm / Hz
noise_power = noise_spectral_density * available_bandwidth; % dBm

snr_tx_max = Pmax - noise_power; %dB


MC=1000; %%number of Monte-Carlo simulations

user_rates = [40e3 400e3 4e6 40e6]; % bit/s
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% CH1 CH2 CH3
equalization_modes.zf.bpsk.snr_min    = [000 000 000]; % Es/N0
equalization_modes.zf.m8qam.snr_min   = [000 000 000]; % Es/N0
equalization_modes.zf.m16qam.snr_min  = [000 000 000]; % Es/N0

equalization_modes.dfe.bpsk.snr_min   = [000 000 000]; % Es/N0
equalization_modes.dfe.m8qam.snr_min  = [000 000 000]; % Es/N0
equalization_modes.dfe.m16qam.snr_min = [000 000 000]; % Es/N0

for rate=user_rates
    Kmax = system_total_rate / user_rates;
    K= [1:(floor(Kmax/10)+1):Kmax];
    rej=zeros(1,length(K));

    for ii=1:numel(fieldnames(equalization_modes))
        eq_mode_name = fieldnames(equalization_modes);
        eq_mode_name = eq_mode_name{ii};
        eq_mode = equalization_modes.(eq_mode_name);

        for kk=1:length(K)
            aux=0;

            for mm=1:MC
            	xx= rand(K(kk), 1) * Dmax; % Distribution of users in the x-axis
            	yy= rand(K(kk), 1) * Dmax; % Distribution of users in the y-axis

            	d2=xx.^2+yy.^2;%% square-distance from the origin
                friss_attenuation_factor = carry_lamdba^2 / (4*pi)^2;
            	a2 = min(1, friss_attenuation_factor/d2);% square magnitude attenuation in Friis equation 
            	a2_dB = 10*log10(a2);
            	SNR_rx_max = a2_dB + snr_tx_max; 

            	SNR_min= eq_mode.m16qam.snr_min; %%ZF or DFE/16QAM: channel 1, channel 2, channel 3
            	if(R*Ts*K(kk)<3)  SNR_min = eq_mode.m8qam.snr_min; end%%ZF or DFE/8QAM: channel 1, channel 2, channel 3
            	if(R*Ts*K(kk)<1) SNR_min = eq_mode.bpsk.snr_min; end %%ZF or DFE/BPSK: channel 1, channel 2, channel 3

            	SNR_rx_min = SNR_min(randi(3,K(kk),1));

            	aux= aux + length((find(sign(SNR_rx_min-SNR_rx_max)+1)/2));
            end

            rej(kk)= aux/(K(kk)*MC);
        end
    end
end
%% Channel display
plot(K,rej,'r--');
grid
