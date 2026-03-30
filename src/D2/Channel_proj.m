function [signal_out] = Channel_proj(simulation_config, tx_config, signal_in, dist)
Rin = 50; % Ohms
K   = 1.38e-23; % Boltzmann Constant
T   = 290;      % room temperature

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%                      Channel                        %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%% Channel %%%
carrierFreq        = tx_config.Flo; % Center frequency of the transmission
c                  = 3e8; % speed of light in vacuum
distance           = dist; % Distance between Basestation and UE : [1.4,1.4e3] metres
% Amplitude Attenuation in free space
ChannelAttenuation = (c/carrierFreq./(4*pi*distance))^2; % Free space path loss in terms of power
rxSignal           = signal_in*sqrt(ChannelAttenuation);
AntennaNoise       = randn(length(rxSignal),1)*sqrt(K*T*...
                     simulation_config.continuousTimeSamplingRate/2*Rin);
signal_out       = rxSignal+AntennaNoise;
end

