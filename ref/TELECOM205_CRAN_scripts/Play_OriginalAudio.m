% This script is used for TELECOM201b Lab / ICS905 Lab
% It only plays the audio file out.wav

% Rev: Nov 2025, Germain

% It also initializes the audio server
[~,hostname] = unix('hostname')
if contains(hostname,'tp-')
    unix('pulseaudio --start&');
end

% Rev: March 2023, Germain

% Load file
[InputAudio,fsAudio]    = audioread('lab_data/out.wav');

% Prepare signal
truncate   = 2^19;  % 2^19 = 524288
achannel   = 1;     % 1 = left channel, 2 = right channel
InputAudio = InputAudio(1:truncate,achannel)/max(InputAudio(:,achannel));

% Germain : Nov 2025 : This instruction fails now
% soundsc(InputAudio,fsAudio);

% Germain : Nov 2025 : Quick fix: Please note Matlab's environment provides wrong library versions for mpv
unix('LD_LIBRARY_PATH= mpv lab_data/out.wav');
