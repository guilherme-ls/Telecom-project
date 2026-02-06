function [analogFilteredOutput] = basebandAnalogFiltTF(input,b,a,NF,Rin,continuousTimeFs)
%basebandAnalogFilt - Implements a baseband analog filter
%
% Syntax:  [analogFilteredOutput] = basebandAnalogFilt(input,b,a,NF,Rin,continuousTimeFs)
%
% Inputs:
%    input            - Input baseband signal
%    b,a              - The filter description as transfer function coefficients
%    NF               - Noise factor of the filter (in dB)
%    Rin              - Input impedance of the filter (in ohm)
%    continuousTimeFs - Sampling frequency emulating the continuous time (in Hz)
%
% Outputs:
%    analogFilteredOutput - analog filtered output signal
% 
% Dev Note: 04 Dec 2025
%   This function replaces Butt_Filter.m 
%   (https://gitlab.telecom-paris.fr/telecom201/labs/tp_filteradc/-/blob/4975a968dcd0c22d3f76bc83b5955927195ab597/files/Butt_Filter.m)
%   which was used in previous years. It is a quasi clone of basebandAnalogFilt.m
%   Please note the noise addition part is different from basebandAnalogFilt.m (reflects exactly Butt_Filter.m)
%
% Other m-files required: none
% Subfunctions: sosfilt
% MAT-files required: none
%
% See also: basebandAnalogFilt.m
% Author: Germain PHAM, Chadi JABBOUR
% C2S, COMELEC, Telecom Paris, Palaiseau, France
% email address: dpham@telecom-paris.fr
% Website: https://c2s.telecom-paristech.fr/TODO
% Dec. 2025
%------------- BEGIN CODE --------------

if not(isvector(b) && isvector(a))
    error('TELECOM201:basebandAnalogFiltTF:inputType','Arguments "b" and "a" must be vectors');
end

isOctave = exist('OCTAVE_VERSION', 'builtin') ~= 0;
if isOctave
    k  = physical_constant("boltzmann constant");
else
    k  = physconst('Boltzmann');
end

T  = 290; % room temperature
        

AntennaNoise = randn(size(input))*sqrt(k*T*continuousTimeFs/2*Rin); 
AddedNoise   = sqrt(10.^(NF/10)-1) * AntennaNoise;

analogFilteredOutput = filter(b,a,input)+AddedNoise; 

%------------- END OF CODE --------------
