close all;
clear;

% Simulation parameters
continuousTimeSamplingRate = 19.98e9; % Operating Frequency to emulate the behavior of a continuous time system
Ts_Cont                    = 1/continuousTimeSamplingRate; % Continuous time sampling period
N                          = 2^13;     % Number of signal points (@baseband rate)

% System properties
BW  = 10e6;     % Signal bandwidth (UNILATERAL)
K   = 1.38e-23; % Boltzmann Constant
T   = 290;      % room temperature
Rin = 50;       % Matching impedance chosen equal to 50

% Mixer Specifications
LO_frequency = 2.4e9; % Hz


% Simulation subproperties
t_Cont       = (0:(N-1))*Ts_Cont; % Time vector (@continuous time rate)

%%%% Input  Generation %%%%
InputI = (cos(2*pi*LO_frequency/4*t_Cont) + cos(2*pi*LO_frequency/8*t_Cont))';  % Cosinus is also sampled
InputQ = zeros(N,1);  % Cosinus is also sampled


up_mixed = upMixer(InputI,InputQ,LO_frequency,continuousTimeSamplingRate);

down_mixed = downMixer(up_mixed,LO_frequency,continuousTimeSamplingRate);

%%%%%%%%%%%%% Plotting %%%%%%%%%%%%%%%%%%%
% Some custom parameters for the home made plot_spectrum function
window_plot_number = 1;
lineSpec_index     = 1;

figure(1)
subplot(2,2,1)
hold on
plot_spectrum(InputI,window_plot_number, continuousTimeSamplingRate, lineSpec_index);
plot_spectrum(InputQ,window_plot_number, continuousTimeSamplingRate, lineSpec_index+1);
xlabel('frequency (Hz)')
ylabel('PSD (dB/bin)')
title('Input Signal')
axis([0,LO_frequency*2,-200,1])

subplot(2,2,2)
plot_spectrum(up_mixed,window_plot_number, continuousTimeSamplingRate, lineSpec_index);
xlabel('frequency (Hz)')
ylabel('PSD (dB/bin)')
title('Up mixed signal ')
axis([0,LO_frequency*2,-200,1])

subplot(2,2,3)
plot_spectrum(down_mixed,window_plot_number, continuousTimeSamplingRate, lineSpec_index);
xlabel('frequency (Hz)')
ylabel('PSD (dB/bin)')
title('Down mixed signal')
axis([0, LO_frequency*2,-200,1])

subplot(2,2,4)
hold on
plot_spectrum(InputI,window_plot_number, continuousTimeSamplingRate, lineSpec_index);
plot_spectrum(InputQ,window_plot_number, continuousTimeSamplingRate, lineSpec_index+1);
plot_spectrum(up_mixed,window_plot_number, continuousTimeSamplingRate, lineSpec_index+2);
plot_spectrum(down_mixed,window_plot_number, continuousTimeSamplingRate, lineSpec_index+3);
xlabel('frequency (Hz)')
ylabel('PSD (dB/bin)')
title('All signals (normalized)')
axis([0,LO_frequency*2,-200,1])





