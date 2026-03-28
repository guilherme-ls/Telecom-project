close all;
clear;

% Simulation parameters
continuousTimeSamplingRate = 19.98e9; % Operating Frequency to emulate the behavior of a continuous time system
Ts_Cont                    = 1/continuousTimeSamplingRate; % Continuous time sampling period
N                          = 2^13;     % Number of signal points (@baseband rate)

ADC_FS = 30.72 * 10e6;
ADC_OSR = 1;
ADC_q = 1;

Nbits = 1:18;
ADC_SNRs = zeros(length(Nbits), 1);
ADC_NF = zeros(length(Nbits), 1);
ADC_P = zeros(length(Nbits), 1);
for ii = Nbits
  ADC_NBits = ii;
  ADC_Dyn = 6.02 * ADC_NBits;
  ADC_SNR = 1.76 + ADC_Dyn + 3.01 * log10(ADC_OSR);
  ADC_SNRs(ii) = ADC_SNR;
  ADC_ENOB = (ADC_SNR - 1.76) / 6.02;
  ADC_P(ii) = -130 + 10*log10(ADC_FS) + 10*log10(2) * ADC_ENOB;
  ADC_NF(ii) = 10*log10((ADC_q / (2^ADC_NBits))^2 / 12) + ADC_SNR ...
	       - 3.01 *log10(ADC_OSR);
end

plot(Nbits, ADC_SNRs)
xlabel ("Nbits");
ylabel ("SNR");
title ("ADC");

