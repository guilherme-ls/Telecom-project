function rfPASignal = TX_proj(basebandDigital_I,basebandDigital_Q,Vref, nBitDAC,basebandSamplingRate,continuousTimeSamplingRate,dacType,TXBB_Filt,TXBB_Filt_NF,Flo,PA_IIP3,PA_NF,PA_Gain)
    %TX_proj - A shortcut function to emulate the TX chain - TELECOM205 version
    %   Calls the functions DAC, basebandAnalogFiltFake, upMixer and rfPA
    %
    % Syntax:  rfPASignal = TX_proj(basebandDigital_I,basebandDigital_Q,Vref, nBitDAC,basebandSamplingRate,continuousTimeSamplingRate,dacType,TXBB_Filt,TXBB_Filt_NF,Flo,PA_IIP3,PA_NF,PA_Gain)
    %
    % Inputs:
    %    basebandDigital_I          - baseband analog equivalent I signal before DAC
    %    basebandDigital_Q          - baseband analog equivalent Q signal before DAC
    %    Vref                       - reference voltage of the DAC
    %    nBitDAC                    - number of bits of the DAC
    %    basebandSamplingRate       - baseband sampling rate (Hz)
    %    continuousTimeSamplingRate - simulation step rate (Hz)
    %    dacType                    - DAC type (string)
    %    TXBB_Filt                  - TX baseband filter impulse response ; FIR ONLY
    %    TXBB_Filt_NF               - TX baseband filter NF (dB)
    %    Flo                        - LO frequency (Hz)
    %    PA_IIP3                    - PA IIP3 (dBm)
    %    PA_NF                      - PA NF (dB)
    %    PA_Gain                    - PA Gain (dB)
    %
    % Outputs:
    %    rfPASignal                 - RF PA signal
    %
    % Other m-files required: DAC, basebandAnalogFiltFake, upMixer, rfPA
    % Subfunctions: none
    % MAT-files required: none
    %
    % See also: none
    % Author: Germain PHAM, Chadi JABBOUR
    % C2S, COMELEC, Telecom Paris, Palaiseau, France
    % email address: dpham@telecom-paris.fr
    % Website: https://c2s.telecom-paristech.fr/TODO
    % Dec. 2023
    %------------- BEGIN CODE --------------


Rin = 50;

% Perform conversion
basebandAnalog_dac_I = DAC(basebandDigital_I,nBitDAC,Vref,dacType,basebandSamplingRate,continuousTimeSamplingRate);
basebandAnalog_dac_Q = DAC(basebandDigital_Q,nBitDAC,Vref,dacType,basebandSamplingRate,continuousTimeSamplingRate);

% Perform filtering
disp('Filtering the DAC output - This takes a while...')
basebandAnalog_filt_I = basebandAnalogFiltFake(basebandAnalog_dac_I,TXBB_Filt,TXBB_Filt_NF,Rin,continuousTimeSamplingRate);
basebandAnalog_filt_Q = basebandAnalogFiltFake(basebandAnalog_dac_Q,TXBB_Filt,TXBB_Filt_NF,Rin,continuousTimeSamplingRate);

%%% Mixing up to RF %%%
rfSignal = upMixer(basebandAnalog_filt_I,basebandAnalog_filt_Q,Flo,continuousTimeSamplingRate);

%%% RF Amplification %%%
rfPASignal = rfPA(rfSignal,PA_Gain,PA_NF,PA_IIP3,Rin,continuousTimeSamplingRate/2);