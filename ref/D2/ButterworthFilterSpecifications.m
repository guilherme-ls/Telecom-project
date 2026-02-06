% ButterworthFilterSpecifications - Compute and plot Butterworth lowpass filter specifications
% This script computes a continuous-time Butterworth lowpass filter that
% meets given passband and stopband requirements, computes its frequency
% response and plots the gain in dB versus frequency (MHz).
%
% Inputs:   none (parameters are set within the script)
% Outputs:  none (figure is produced and order/cutoff printed to command window)
%
% Usage:
%    Run the script to obtain the filter order and cutoff frequency and to
%    visualize the filter response.
%
% Other m-files required: none
% MAT-files required: none
% 
% Dev Note: This script is a new version of ButterworthFilterSpecifications.m
% using continuous-time filter design functions (buttord, butter, freqs).
% It replaces the previous discrete-time design approach.
% The old version is kept here: 
% https://gitlab.telecom-paris.fr/telecom201/labs/tp_filteradc/-/blob/4975a968dcd0c22d3f76bc83b5955927195ab597/files/ButterworthFilterSpecifications.m
%
% Author: Germain PHAM, Chadi JABBOUR
% Affiliation: C2S, Télécom Paris, IP Paris
% email address: dpham@telecom-paris.fr, chadi.jabbour@telecom-paris.fr
% Website: https://c2s.telecom-paristech.fr/TODO
% Last revision: December 2025
%------------- BEGIN CODE --------------

close all
clear

continuousTimeSamplingRate = 1e9; %Frequency to emulate the behavior of a continuous time system
N       = 1e5;   % number of points
f1      = 05e6;  % Low frequency - Useful Bandwidth limit
f2      = 15e6;  % High Frequency - Stop Frequency
Amin    = 10;    % Min attenuation at f2 in dB
Amax    = 2;     % Max attenuation at f1 in dB

% Compute filter order
[Order,Omega_cut]   = buttord(2*pi*f1,2*pi*f2,Amax,Amin,'s');

% Compute filter coefficients
[b_butter,a_butter] = butter(Order,Omega_cut,'s');

% Compute frequency response
[butter_f_resp,butter_f_resp_omega] = freqs(b_butter,a_butter,N);

% Plot frequency response
semilogx(butter_f_resp_omega/(2*pi)/1e6,20*log10(abs(butter_f_resp)))
xlabel("Frequency (MHz)")
ylabel("Gain(dB)")
% axis([0.1,200,-200,1])
xlim([min(get(gca,'xlim')) 200])

disp(['The filter order is ',int2str(Order),' and the Fcut is ', num2str(Omega_cut/(2*pi)/1e6),' MHz'])

%------------- END OF CODE --------------