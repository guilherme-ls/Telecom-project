function params = simulation_config()
    % A function that sets the simulation configuration parameters
    %
    % The system is divided into:
    % - Simulator parameters (e.g., simulation step)
    % - Electrical properties (e.g., temperature, impedance)
    % - TX:
    %   - Baseband:
    %       - Modulation: Symbol rate, Modulation order, etc.
    %       - ISI cancellation: Sampling rate, rolloff factor, etc.
    %       - DAC: Number of bits, Reference voltage, etc.
    %       - Filter: specs
    %   - RF:
    %       - Mixer: specs
    %       - PA: Power, Efficiency, etc.
    % - Channel: path loss, etc.
    % - RX:
    %   - RF:
    %       - LNA: Noise figure, Gain, etc.
    %       - Mixer: specs
    %   - Baseband:
    %       - Filter: specs
    %       - ADC: Number of bits, Reference voltage, etc.
    %       - ISI cancellation: Sampling rate, rolloff factor, etc.



    % Germain PHAM, C2S-Telecom-Paris, 25 Nov 2024

    % Fundamental sampling parameters
    Fsymbol                  = 20e6;    % Symbol rate of the baseband signal
    Fbaseband                = 30.72e6; % Sample rate of the baseband signal
    simulator_step_rate_orig = 10e9;    % Approximate Simulation step rate in Hz
    simulator_step_rate      = round(simulator_step_rate_orig/Fbaseband)*Fbaseband; % Simulation step rate in Hz

    % Compute conversion factors for the ISI cancellation filter at TX
    GCD_Fbb_Fsymb    = gcd(Fbaseband,Fsymbol);
    tx_isi_cancel_up = Fbaseband/GCD_Fbb_Fsymb;
    tx_isi_cancel_dw = Fsymbol/GCD_Fbb_Fsymb;


    % Signal type
    signal_type = 'modulated'; % 'modulated' or 'sine' or 'exp'
    Nrandomize  = 0;      % Number of randomize signals to generate ; if <= 1, only one signal is generated ; works only for 'sine' or 'exp'

    % General structure
    params = struct();

    % Simulator parameters
    params.simulatorStepRate = simulator_step_rate; % Sampling rate to emulate a continuous time system

    % Electrical properties
    params.elec.temperature = 290; % room temperature in Kelvin
    params.elec.impedance   = 50; % Matching impedance chosen equal to 50 Ohm
    params.elec.k_Boltz     = 1.38e-23; % Boltzmann Constant

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % TRANSMITTER
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    params.tx = struct();
    % Baseband
    params.tx.baseband = struct();

    % Baseband sampling parameters
    params.tx.baseband.sampleRate = Fbaseband; % Sample rate of the baseband signal

    % Modulation
    params.tx.baseband.modulation = struct();
    params.tx.baseband.modulation.symbolRate = Fsymbol; % Symbol rate
    params.tx.baseband.modulation.modulationOrder = 16; % Modulation order
    params.tx.baseband.modulation.Nsymbols   = 2^13;  % Number of symbols to generate
    params.tx.baseband.modulation.signal     = set_modulation_params(signal_type,Nrandomize);
    params.tx.baseband.modulation.signal.length = fix(params.tx.baseband.modulation.Nsymbols*Fbaseband/Fsymbol); % Length of the baseband signal in samples
    params.tx.baseband.symbol_to_baseband_OSR = params.tx.baseband.sampleRate/params.tx.baseband.modulation.symbolRate;
    % ISI cancellation filter (always a raised consine filter)
    params.tx.baseband.isiCancel = struct();
    params.tx.baseband.isiCancel.filterSpan       = 10;           % Filter span in terms of number of symbols
    params.tx.baseband.isiCancel.rolloff          = 0.22;         % Rolloff factor of the RC filter
    params.tx.baseband.isiCancel.upSampleFactor   = tx_isi_cancel_up; % Samples per symbol of the RC filter
    params.tx.baseband.isiCancel.downSampleFactor = tx_isi_cancel_dw; % Downsample factor after the RC filter

    % DAC parameters
    params.tx.baseband.dac = struct();
    params.tx.baseband.dac.resolution = 100; % DAC resolution in bits
    params.tx.baseband.dac.fullscale  = 2;  % DAC fullscale voltage range in Volts (peak-to-peak)
    params.tx.baseband.dac.center     = 0;  % DAC center voltage in Volts ; the fullscale is centered around this value
    params.tx.baseband.dac.Vmax       = params.tx.baseband.dac.fullscale/2+params.tx.baseband.dac.center; % DAC max voltage in Volts (peak)
    params.tx.baseband.dac.type       = 'zoh'; % DAC type: 'zoh' or 'impulse'
    % The DAC function implements the change rate from params.baseband.sampleRate (Fbaseband) to params.simulation.stepRate (simulation_step_rate)

    % Baseband analog filtering parameters
    % 
    % Though this filter is denominated "analog", it is a digital filter in this
    % simulation because in matlab, it is impossible to filter with a real
    % analog filter (because matlab can only implement discrete time
    % simulations). 
    params.tx.baseband.analog_filter = struct();
    params.tx.baseband.analog_filter.filterType = 'butter';    % Filter type: 'butter' or 'kaiser'
    params.tx.baseband.analog_filter.Fpass      = Fsymbol/2;   % Passband frequency in Hz
    params.tx.baseband.analog_filter.Fstop      = Fbaseband/2; % Stopband frequency in Hz
    params.tx.baseband.analog_filter.Apass      = 0.1;         % Passband ripple in dB
    params.tx.baseband.analog_filter.Astop      = 60;          % Stopband attenuation in dB
    params.tx.baseband.analog_filter.NF         = 00;          % Noise figure in dB
    params.tx.baseband.analog_filter.sos_form   = true;
    % When set to true, the filter is synthesized as a second-order section
    % (SOS) filter ; it is useful for high-order filters and to avoid numerical
    % issues. 
    % 
    % When set to false, the filter is synthesized as a transfer function (TF)
    % filter
    params.filtfilt   = true;  % Use filtfilt (Zero-phase filtering (true) or not (false))
    % When a high order IIR filter (e.g. butterworth) is used, 
    %   - the SOS form is recommended because it is more stable than the TF form.
    %   - the filtfilt function is recommended
    %       +------------------+------------------+
    %       |                  |    sos_form      |
    %       |                  +-------+----------+
    %       |                  | true  | false    |
    %       +----------+-------+-------+----------+
    %       |          | true  | BEST  | UNSTABLE |
    %       | filtfilt +-------+-------+----------+
    %       |          | false | valid | UNSTABLE |
    %       +----------+-------+-------+----------+
    % 
    % When a kaiser filter is used, 
    %   - the TF form is recommended because the SOS form is not reliable for FIR filters
    %   - the filtfilt function is recommended
    %       +------------------+------------------+
    %       |                  |       sos_form   |
    %       |                  +----------+-------+
    %       |                  | true     | false |
    %       +----------+-------+----------+-------+
    %       | filtfilt | true  | UNSTABLE | BEST  |
    %       |          +-------+----------+-------+
    %       |          | false | UNSTABLE | valid |
    %       +----------+-------+----------+-------+

    params.tx.rf.Flo = 2.4e9;   % RF center frequency in Hz
    params.tx.rf.BW  = Fsymbol; % RF bandwidth in Hz


 
end
