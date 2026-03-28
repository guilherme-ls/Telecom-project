close all;
clear;

% Simulation parameters
continuousTimeSamplingRate = 19.98e9; % Operating Frequency to emulate the behavior of a continuous time system
Ts_Cont                    = 1/continuousTimeSamplingRate; % Continuous time sampling period
N_Cont                     = 2^18;   % Number of signal points (@continuous time rate)

% System properties
BW  = 10e6;     % Signal bandwidth
K   = 1.38e-23; % Boltzmann Constant
T   = 290;      % room temperature
Rin = 50;       % Matching impedance chosen equal to 50

% RF parameters
Flo       = 2.4e9;
BW_rf     = 2*BW;

% Simulation subproperties
t_Cont       = (0:(N_Cont-1))*Ts_Cont; % Time vector (@continuous time rate)

% Input signal
fin_or          = Flo+1.1e6; % Input sine frequency
Bin_in          = round(fin_or/continuousTimeSamplingRate*N_Cont); % Determining the input bin
fin             = Bin_in*continuousTimeSamplingRate/N_Cont;

Pin             = -90;  % Pin in dBm
Ain             = sqrt(10.^((Pin-30)/10)*2*Rin);
AntennaNoise    = randn(1,N_Cont)*sqrt(K*T*continuousTimeSamplingRate/2*Rin);
in              = Ain*sin(2*pi*fin*t_Cont+rand()*2*pi)+AntennaNoise; % Input signal

% LNA parameters
LNA_IIP3    = 10; % (dBm)

LNA_Gains = 5:15;
LNA_NFs = 0:0.1:10;
SNRs = zeros(length(LNA_Gains), length(LNA_NFs));

for jj = 1:length(LNA_Gains)
for ii = 1:length(LNA_NFs)
LNA_Gain = LNA_Gains(jj);
LNA_NF = LNA_NFs(ii);
% Compute bins
Bin_low   = round((Flo-BW_rf/2)/continuousTimeSamplingRate*N_Cont); % Determining the bandwidth bins
Bin_high  = round((Flo+BW_rf/2)/continuousTimeSamplingRate*N_Cont); % Determining the bandwidth bins
win_width = 5; % window width in bins

% Operate LNA
LNA_out     = rfLNA(in,LNA_Gain,LNA_NF,LNA_IIP3,Rin,continuousTimeSamplingRate/2);

% Compute SNR on specified bins
SNR_in    = perf_estim(in,Bin_in,win_width,[Bin_low Bin_high]);
SNRs(jj, ii)   = perf_estim(LNA_out,Bin_in,win_width,[Bin_low Bin_high]);
end;
end;

figure(1);
hold all;

lna_gains = {};

for jj = 1:length(LNA_Gains)
plot(LNA_NFs, SNRs(jj, :))
lna_gains{end+1} = num2str(LNA_Gains(jj));
end;

legend(lna_gains)

xlabel('NF (dB)')
ylabel('SNR (dB)')
title("LNA SNR x NF")

hold off;
