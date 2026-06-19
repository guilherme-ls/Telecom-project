set(groot,'DefaultLineLinewidth',2)
set(groot,'DefaultAxesFontSize',16)
set(groot,'DefaultAxesXGrid','on')
set(groot,'DefaultAxesYGrid','on')

isOctave = exist('OCTAVE_VERSION', 'builtin') ~= 0;
if isOctave
    pkg load communications
    pkg load miscellaneous
end

addpath(genpath('../../ref/D1-D4'))
addpath(genpath('../D1/'))
