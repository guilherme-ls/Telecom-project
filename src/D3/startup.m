addpath(genpath('../../ref/D3'))

set(groot,'DefaultLineLinewidth',2)
set(groot,'DefaultAxesFontSize',16)
set(groot,'DefaultAxesXGrid','on')
set(groot,'DefaultAxesYGrid','on')

isOctave = exist('OCTAVE_VERSION', 'builtin') ~= 0;
if isOctave
    pkg load signal
    pkg load control 
    pkg load communications
    pkg load miscellaneous
    addpath(genpath('./octave-replacement/'))
end
