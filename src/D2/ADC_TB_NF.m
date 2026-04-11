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

% ADC Specifications
Nbits_ADC               = 18;
Vref_ADC                = 1;
Fs_ADC                  = 30e6;
basebandSamplingRate    = Fs_ADC;
Ts_BB                   = 1/Fs_ADC; % Baseband sampling period

% Simulation subproperties
Subsamp_fadc = round(continuousTimeSamplingRate/basebandSamplingRate);
t_Cont       = (0:(N*Subsamp_fadc-1))*Ts_Cont; % Time vector (@continuous time rate)
t_BB         = (0:(N-1))*Ts_BB;                % Time vector (@baseband rate)

%%%% Input  Generation %%%%
fsig_or   = 7.12e6;                        % Input frequency (Hz)
sig_bin   = round(fsig_or/basebandSamplingRate*N);     % Input bin of the signal frequency
fsig      = sig_bin*basebandSamplingRate/N;            % re-adjusting in a signal bin
Pin             = 10;  % Pin in dBm
Ain             = sqrt(10.^((Pin-30)/10)*2*Rin);
AntennaNoise    = randn(1,length(t_Cont))*sqrt(K*T*continuousTimeSamplingRate/2*Rin);
Input        = Ain*sin(2*pi*fsig*t_Cont+rand()*2*pi)+AntennaNoise; % Input signal

%Input = cos(2*pi*fsig*t_Cont)';  % Cosinus is also sampled

delay_ADC = 0;
DigitalOutput = ADC(Input',Nbits_ADC,Vref_ADC,Fs_ADC,delay_ADC,continuousTimeSamplingRate);

Nin = length(Input);
Bin_limits     = [1,round(BW/continuousTimeSamplingRate*Nin)];
% Compute SNR
Bin_sig_shiftd = sig_bin;
bin_width      = 4;
SNR_in         = perf_estim(Input,Bin_sig_shiftd,bin_width,Bin_limits,false);

Bin_limits     = N/2+[0,round(BW/Fs_ADC*N)];
% Compute SNR
Bin_sig_shiftd = N/2+sig_bin;
bin_width      = 4;
SNR_out        = perf_estim(DigitalOutput,Bin_sig_shiftd,bin_width,Bin_limits,true);
NF = SNR_in - SNR_out;
disp(NF)

%%%%%%%%%%%%% Plotting %%%%%%%%%%%%%%%%%%%
% Some custom parameters for the home made plot_spectrum function
window_plot_number = 1;
lineSpec_index     = 1;

figure(1)
subplot(2,2,1)
plot_spectrum(Input,window_plot_number, continuousTimeSamplingRate, lineSpec_index, true);
xlabel('frequency (Hz)')
ylabel('PSD (dB/bin)')
title('Input Signal')
axis([0,Fs_ADC/2,-200,1])

subplot(2,2,2)
plot_spectrum(DigitalOutput,window_plot_number,Fs_ADC,lineSpec_index+1, true);  
xlabel('frequency (Hz)')
ylabel('PSD (dB/bin)')
title('ADC Digital Output ')
axis([0,Fs_ADC/2,-200,1])

subplot(2,2,3)
hold on
plot_spectrum(Input,window_plot_number, continuousTimeSamplingRate, lineSpec_index);
plot_spectrum(DigitalOutput,window_plot_number,Fs_ADC,lineSpec_index+1);  
xlabel('frequency (Hz)')
ylabel('PSD (dB/bin)')
title('All signals (normalized)')
axis([0,Fs_ADC/2,-200,1])
