function [signal_out, basebandSig, qamSig, perf_tx] = Tx_proj(simulation_config, tx_config, signal_config)

    isOctave = exist('OCTAVE_VERSION', 'builtin') ~= 0;
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%                   Transmitter                        %%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % System properties
    BW  = 10e6;     % Signal bandwidth
    K   = 1.38e-23; % Boltzmann Constant
    T   = 290;      % room temperature
    Rin = 50;       % Matching impedance chosen equal to 50
    
    %%% Signal Generation %%%
    continuousTimeSamplingRate    = simulation_config.continuousTimeSamplingRate; % A sampling rate which is sufficiently high in order to be close to the continous time
    basebandSamplingRate_or       = 30e6;     % The sampling rate of the complex baseband signal. In this project it MUST BE a multiple of symbolRate
    basebandSamplingRate          = basebandSamplingRate_or; % continuousTimeSamplingRate/round(continuousTimeSamplingRate/basebandSamplingRate_or);
    
    %%% Signal Generation %%%
    symbolRate              = 15e6;  % The raw symbol rate : the raw complex QAM symbols are sent at this rate ; Units : Symbols/second
    basebandOverSampling    = round(basebandSamplingRate/symbolRate);
    NSamples_BB             = 2^13;   % Signal length (after RRC filter)
    
    % Signal frequencies
    freqVin_or1   = 7.12e6;
    freqVin_or2   = 6.12e6;
    % Place the sine waves in an FFT bin
    freqVin1      = round(freqVin_or1/basebandSamplingRate*NSamples_BB)...
                    *basebandSamplingRate/NSamples_BB; 
    freqVin2      = round(freqVin_or2/basebandSamplingRate*NSamples_BB)...
                    *basebandSamplingRate/NSamples_BB; 
    
    % Time vector of the simulation
    t = 0:1/basebandSamplingRate:(NSamples_BB-1)/basebandSamplingRate;
    
    %%% Baseband (digital) shaping filter %%%
    rollOff     = 0.25; % (for RRC filter, single sided output BW is (1+beta)*Rsymb/2 )
    symbolSpan  = 25;   % This parameter is related to both the filter length and the attenuation of the stop band
    % Instanciate filter
    basebandRRC = rcosdesign(rollOff,symbolSpan,basebandOverSampling,'sqrt');
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%% Possible values of test_type are:
    %%%%%                               'onetone' for a one-tone sine 
    %%%%%                               'twotone' for a two-tone sine 
    %%%%%                               'mod'     for a modulated QAM 16 signal
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    qamSig = 0;
    switch signal_config.test_type
        case 'onetone'
            %%% one tone signal%%%
            basebandSig = exp(1j*2*pi*freqVin1*t);
        case 'twotone'
            %%% two tone signal%%%
            basebandSig = exp(1j*2*pi*freqVin1*t)+exp(1j*2*pi*freqVin2*t);
        case 'mod'
            %%% Modulated signal
            modSize       = 16; % Modulation order for 16QAM
            nQAMSymbols   = round(NSamples_BB/basebandOverSampling); % Number of QAM symbols to be generated
            inSig         = randi([0 modSize-1],nQAMSymbols,1);      % generate symbols as integer
            % Perform modulation : convert integer symbols to complex symbols
            if isOctave
                qamSig        = qammod(inSig,modSize);
                qamSig        = qamSig/sqrt(mean(abs(qamSig).^2));
            else % Matlab
                qamSig        = qammod(inSig,modSize,'UnitAveragePower',true);
            end
            % Apply filter with upsampling to basebandSamplingRate 
            basebandSig   = resample(qamSig,basebandOverSampling,1,basebandRRC);
            % Resample (compared to upfirdn) generates a signal that is exactly the 
            % length we can predict without having to compensate for the delay introduced by the filter
            % https://groups.google.com/d/msg/comp.soft-sys.matlab/UGLNR9vFqhM/c56ZlfUlhhcJ
            
        otherwise
            %%% one tone signal%%%
            basebandSig = exp(1j*2*pi*freqVin1*t);
    end

    %%% Digital to Analog Conversion %%%
    nBitDAC = tx_config.nBitDAC; % Number of bits of the DAC
    Vref    = tx_config.Vref;    % Voltage reference of the DAC
    dacType = 'zoh';        % DAC type ; can be 'zoh' or 'impulse'
    
    %%% IQ separation for real baseband signals %%%
    [basebandDigital_I_unorm,basebandDigital_Q_unorm] = complx2cart(basebandSig(:));
    
    % Normalize signal for conversion
    % Must use same scale factor for both wave (Take max of both)
    normalize_factor    = max(max(abs(basebandDigital_I_unorm)), max(abs(basebandDigital_Q_unorm)));
    basebandDigital_I   = basebandDigital_I_unorm/normalize_factor*Vref;
    basebandDigital_Q   = basebandDigital_Q_unorm/normalize_factor*Vref;
    
    % Perform conversion
    basebandAnalog_dac_I = DAC(basebandDigital_I,nBitDAC,Vref,dacType,basebandSamplingRate,continuousTimeSamplingRate);
    basebandAnalog_dac_Q = DAC(basebandDigital_Q,nBitDAC,Vref,dacType,basebandSamplingRate,continuousTimeSamplingRate);
    
    % Calculate the power used by the DACs
    P_DAC = 10e-13 * basebandSamplingRate * 2^(nBitDAC);
    P_DAC_total = 2 * P_DAC;
    
    %%% Baseband FAKE Analog filter %%%
    TXBB_Filt_NF    = 00;    %(in dB)
    
    % https://fr.mathworks.com/help/signal/ref/firpmord.html
    TXBB_Filt_rp    = tx_config.TXBB_Filt_rp;       % Passband ripple in dB
    TXBB_Filt_rs    = tx_config.TXBB_Filt_rs;       % Stopband ripple in dB
    TXBB_Filt_fs    = continuousTimeSamplingRate;   % Sampling frequency (Hz)
    TXBB_Filt_f     = tx_config.TXBB_Filt_f;        % Cutoff frequencies (Hz)
    TXBB_Filt_a     = [1 0];                        % Desired amplitudes
    % Convert the deviations to linear units. 
    TXBB_Filt_dev   = [(10^(TXBB_Filt_rp/20)-1)/(10^(TXBB_Filt_rp/20)+1) 10^(-TXBB_Filt_rs/20)];
    % Design the filter
    [TXBB_Filt_n,TXBB_Filt_fo,TXBB_Filt_ao,TXBB_Filt_w] = firpmord(TXBB_Filt_f,TXBB_Filt_a,TXBB_Filt_dev,TXBB_Filt_fs);
    if isOctave
        disp('Using octave standard filter values')
        TXBB_Filt_n = 6511;
    end
    disp('Designing the TX filter - This takes a while...')
    TXBB_Filt       = firpm(TXBB_Filt_n,TXBB_Filt_fo,TXBB_Filt_ao,TXBB_Filt_w);
    
    % Perform filtering
    disp('Filtering with the TX filter - This takes a while...')
    basebandAnalog_filt_I = basebandAnalogFiltFake(basebandAnalog_dac_I,TXBB_Filt,TXBB_Filt_NF,Rin,continuousTimeSamplingRate);
    basebandAnalog_filt_Q = basebandAnalogFiltFake(basebandAnalog_dac_Q,TXBB_Filt,TXBB_Filt_NF,Rin,continuousTimeSamplingRate);
    
    %%% Mixing up to RF %%%
    Flo      = tx_config.Flo; % Local Oscillator Frequency
    rfSignal = upMixer(basebandAnalog_filt_I,basebandAnalog_filt_Q,Flo,continuousTimeSamplingRate);
    
    P_upMixer = 5 * 10e-12 * Flo;
    P_upMixer_total = 2 * P_upMixer;
    
    %%% RF Amplification %%%
    PA_mux = tx_config.PA_mux;
    
    switch PA_mux
        case 'ZX60_V63+'
            PA_IIP3       = 30-19.7;      % OIP3 = 31.2 dBm à 2GHz et 28.8 dBm à 3GHz
            PA_NF         = 5.1;      % PA Noise figure ; in dB
            PA_Gain       = 19.7;     % 20.3 dB à 2GHz et 19.2 dB à 3 GHz
            P_cons_PA = 5*69*10^(-3);
        case 'ZX60_V62+'
            PA_IIP3       = 31.9-15.5;      % OIP3 = 33.4 dBm à 2GHz et 30.4 dBm à 3GHz
            PA_NF         = 5.1;      % PA Noise figure ; in dB
            PA_Gain       = 15.5;     % 
            P_cons_PA = 5*82*10^(-3);
        case 'ZHL42'
            PA_IIP3       = 44.85-39.46;      % 
            PA_NF         = 8.07;      % PA Noise figure ; in dB
            PA_Gain       = 39.46;     %
            P_cons_PA = 15*1;
        case 'ADL5606'
            PA_IIP3       = 44.3-21.45;      % 45.5 dBm à 2140MHz et 43.2 dBm à 2630MHz
            PA_NF         = 4.9;      % 4.7dB à 2140MHz et 5.1dB à 2630MHz
            PA_Gain       = 21.45;     % 24.3 dB à 2140MHz et 20.6dB à 2630 MHz
            P_cons_PA = 380*10^(-3) * 5;
        case 'RFLUPA05M06G'
            PA_IIP3       = 43-33;      % 45.5 dBm à 2140MHz et 43.2 dBm à 2630MHz
            PA_NF         = 3;      % 4.7dB à 2140MHz et 5.1dB à 2630MHz
            PA_Gain       = 33;     % 24.3 dB à 2140MHz et 20.6dB à 2630 MHz
            P_cons_PA = 12 * 350 * 10^(-3);
        case 'none'
            PA_IIP3       = 150;      % 45.5 dBm à 2140MHz et 43.2 dBm à 2630MHz
            PA_NF         = 0;      % 4.7dB à 2140MHz et 5.1dB à 2630MHz
            PA_Gain       = 0;     % 24.3 dB à 2140MHz et 20.6dB à 2630 MHz
            P_cons_PA = 0;
    end

    function signalPSD = PSD(signal)
        Nsignal = length(signal);
        win     = blackman(Nsignal);
        U       = (1/length(win))*sum(abs(win).^2);
        win     = sqrt(1/U)*win/length(win);
        signalPSD = abs(fft(signal.*win)).^2;
    end
        
    P_TX_total = P_cons_PA + P_upMixer_total + P_DAC_total;
    
    %%% Power Performances
    perf_tx.power.P_TX_total = P_TX_total;
    perf_tx.power.P_cons_PA = P_cons_PA;
    perf_tx.power.P_upMixer = P_upMixer;
    perf_tx.power.P_DAC = P_DAC;
    

    dif = 1;
    att = 0;
    while abs(dif) > 0.1
        % Pre-amplification step
        rfSignalIn = rfSignal * 10^(att/20);
        
        rfPASignal    = rfPA(rfSignalIn,PA_Gain,PA_NF,PA_IIP3,Rin,continuousTimeSamplingRate/2);
        
        signal_out = rfPASignal;
        
        %%% Output signal power and ACPR
        if 1 % strcmpi(signal_config.test_type, 'mod')
            NBins = length(rfPASignal);
            bin_signal_start = floor(2.385e9/continuousTimeSamplingRate*NBins); 
            bin_signal_end = ceil(2.415e9/continuousTimeSamplingRate*NBins);
            bin_signal_band = bin_signal_start:bin_signal_end;
            
            bin_sideband_sup_end = ceil(2.445e9/continuousTimeSamplingRate*NBins);
            bin_sideband_sup_band = bin_signal_end:bin_sideband_sup_end;
            
            bin_sideband_inf_start = floor(2.355e9/continuousTimeSamplingRate*NBins);
            bin_sideband_inf_band = bin_sideband_inf_start:bin_signal_start;
    
            voltsq2mwatt    = 1e3/Rin;
            signal_psd = PSD(rfPASignal*sqrt(voltsq2mwatt));
            
            signal_power = sum(signal_psd(bin_signal_band)) * 2;% * length(bin_signal_band); % (continuousTimeSamplingRate/NBins);
            sideband_sup_power = sum(signal_psd(bin_sideband_sup_band)) * 2;% * length(bin_sideband_sup_band); % (continuousTimeSamplingRate/NBins) - signal_power;
            sideband_inf_power = sum(signal_psd(bin_sideband_inf_band)) * 2;% * length(bin_sideband_sup_band); % (continuousTimeSamplingRate/NBins) - signal_power;
            ACPR = signal_power / ((sideband_sup_power + sideband_inf_power) / 2);
            
            perf_tx.acpr = ACPR;
            perf_tx.signal_power = signal_power;
        end

        dif = 20 - 10*log10(perf_tx.signal_power);
        att = att + dif;
        disp(['Att: ', num2str(att)])
    end

    perf_tx.attenuation = att;

end


clear;
close all;

%%% Simulation Params %%%
simulation_config.continuousTimeSamplingRate = 19.968e9;
simulation_config.basebandSamplingRate = 30.72e6;
simulation_config.symbolRate = 15.36e6; 

%%% Signal Params %%%
signal_config.test_type = 'mod';

%%% TX Params %%%
%%%%% DAC %%%%
tx_config.nBitDAC = 6; % Number of bits of the DAC
tx_config.Vref = 1;    % Voltage reference of the DAC
%%%%% Filter %%%%
tx_config.TXBB_Filt_rp = 0.5; % Passband ripple in dB
tx_config.TXBB_Filt_rs = 40; % Stopband ripple in dB
tx_config.TXBB_Filt_f = [15 20]*1e6; % Cutoff frequencies (Hz) 0.5;        
%%%%% Up Mixer %%%%
tx_config.Flo  = 2.4e9;
%%%%% PA %%%%                                             
tx_config.PA_mux = 'RFLUPA05M06G'; % PA Model 


%%% Transmission Chain %%%

N = 4:14;
ACPRs = zeros(1,length(N));
Ps = zeros(1,length(N));
Powers = zeros(1,length(N));
Atts = zeros(1,length(N));
for n = 1:length(N)
    tx_config.nBitDAC = N(n); % Number of bits of the DAC
    [tx_output, tx_input, tx_qam_input, perf_tx] = Tx_proj(simulation_config, tx_config, signal_config); 
    ACPRs(n) = 10*log10(perf_tx.acpr);
    Ps(n) = 10*log10(perf_tx.signal_power);
    Powers(n) = perf_tx.power.P_TX_total;
    Atts(n) = perf_tx.attenuation;
end

figure(1)
subplot(2,2,1)
plot(N, ACPRs)
xlabel ("Nbits");
ylabel ("ACPR (dB)");
title ("ACPR per Nbits");

subplot(2,2,2)
plot(N, Ps)
xlabel ("Nbits");
ylabel ("Power (dBm)");
title ("Signal Power per Nbits");

subplot(2,2,3)
plot(N, Powers)
xlabel ("Nbits");
ylabel ("Power (W)");
title ("Power per Nbits");

subplot(2,2,4)
plot(N, Atts)
xlabel ("Nbits");
ylabel ("Attenuation (dB)");
title ("Attenuation per Nbits");
sgtitle(['Configuration: ', tx_config.PA_mux]);

basebandSamplingRate          = simulation_config.basebandSamplingRate;

%%% Plotting %%%
Rin = 50;
voltsq2mwatt    = 1e3/Rin; % Conversion factor from V^2 to milliWatt
window_number       = 2;
lineSpec_index      = 1;
fullband_spectrum   = true;

plot_spectrum(tx_input*sqrt(voltsq2mwatt), window_number,...
               basebandSamplingRate,lineSpec_index, fullband_spectrum);
title('TX Digital Complex recombined signal')
xlabel('frequency (Hz)')
ylabel('PSD (dBm/bin)')

window_number       = window_number+1;
fullband_spectrum   = false;
plot_spectrum(tx_output*sqrt(voltsq2mwatt), window_number, ...
              simulation_config.continuousTimeSamplingRate, 1, false);
title('TX Output')
xlabel('frequency (Hz)')
ylabel('PSD (dBm/bin)')

disp(['Signal power: ', num2str(perf_tx.signal_power), ' mW or ', num2str(10*log10(perf_tx.signal_power)), ' dBm.'])
disp(['ACPR: ', num2str(10*log10(perf_tx.acpr)), ' dB.'])
disp(['Total power used by TX: ', num2str(perf_tx.power.P_TX_total), ' W.'])

%%% Performances %%%
