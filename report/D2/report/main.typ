#import "template.typ": project

#import "graph_plots.typ" : *

#import "@preview/equate:0.3.2": equate
#import "@preview/lilaq:0.5.0" as lq

#show: equate.with(breakable: true, sub-numbering: false)
#set math.equation(numbering: "(1.1)")

#set par(
  justify: true,
  leading: 0.52em,
)

// LTeX: language=en-US
// LTeX: statusBatItem=true 

#show: project.with(
  title: "Radio-frequency system and hardware modeling",
  subtitle: "Performance Analysis of a realistic
Cloud Radio Access Network (C-RAN)",
  authors: (
    "LOUROSA RECH Bernardo",
    "LORETE SCHMIDT Guilherme",
    "PANCHENIAK FILHO Ivan Roberto Wagner"
  ),
  school-logo: image("./assets/logo_telecom_ipparis.png", width: 8cm, height:4.0cm), 
  company-logo: [],
  mentors: (
    "NIOTAKI Kyriaki",
  ),
  jury: (),
  branch: "Filière Telecom",
  academic-year: "2025-2026",
  footer-text: "PRJ_4TE05_TP",
)

- Aux calculs analytiques qui vous ont permis de trouver les principales spécifications
- A l'approche suivie pour l'optimisation de vos chaines d'émission et de réception
- Aux résultats de simulation et à leur analyse

= Introduction

In this report, we modeled, optimized, simulated, and tested a transceiver communication chain. 

The first part will be focused on the modeling, optimization and simulation, in it, the 
different blocks that compose the receiver and the transmitter have their parameters enumerated, and how they contribute to achieve the desired performance values. 
Also, the results of the simulated performance are shown and discussed, and the optimization methodology chosen is described and explained.

Meanwhile, the second part has a focus in the experimental side of the project. A Low Noise Amplifier and a Power Amplifier were measured, the first with a vector analyser,
and the other with an ADALM-PLUTO SDR. 
The resulting curves are shown, and how they differ from the expected values found in the datasheets. Again with the same SDR, the transceiver chain was tested, with the needed 
post-processing on the received symbols, producing some metrics curved.

Finally and a discussion going over how the AD9363 chip (found in the ADALM-PLUTO) internal blocks differ from the modeled chain can be found in the conclusion section.

= System Simulation

In this project, we design the uplink modules of a Cloud Radio Access Network, modelling and optimizing all the individual components involved in the transmission and reception chains built using the Inphase/Quadrature (IQ) Homodyne architecture. Each element of the chain and the full transmission and reception chain are simulated and evaluated to ensure they meet the required performance metrics. All the elements have their parameters optimized to reduce the system's power consumption.

== Transmitter (TX)

The RF transmission chain employed in this project is represented in @fig:TX_chain. The general specifications that will guide its design can equally be found in @tab:TX_specifications.

#figure(
  image("./assets/TX_fig.png", width: 80%),
  caption: [TX transmission chain with all its individual components.]
) <fig:TX_chain>

#figure(
  caption: [TX specifications.],
  table(
    columns: 2,
    align: center,
    [Pout Average], [$20 "dBm"$],
    table.hline(),
    [ACPR], [$45 "dBm"$],
    table.hline(),
    [RF Bandwidth], [$30 "MHz"$],
    table.hline(),
    [Useful Bandwidth], [$20 "MHz"$],
    table.hline(),
    [Central Frequency], [$2.4 "GHz"$],
    table.hline(),
    [Matching Resistance], [$50 thin Omega$],
    table.hline(),
    [Temperature], [$290 "K"$],
    table.hline(),
    [DAC Full Scale], [$plus.minus 1 "V"$],
    table.hline(),
  ),
) <tab:TX_specifications>

Conducting a preliminary analysis of the transmission chain, we can see that the output power of the signal will depend solely on the power amplifier, given that the DAC full scale is fixed. Considering that the DAC produces a sinusoidal signal, its output power is $10 "dBm"$.

$ "P"_("DAC") = 10 times log (((1 "V")^2)/(2 times (50 thin Omega)) times 1/(1 "mW")) = 10 "dBm" $

Therefore, to reach the desired output power we simply need a $10 "dB"$ gain for the chain.

Concerning the ACPR, it will be affected by many elements of the transmission chain. Namely the DAC, the filter and most importantly the power amplifier. 

Given these observations, we start the design process of the TX chain.

=== Digital to Analog Converter

Firstly, the DAC was chosen to be a zero order holder, due mostly to the power requirements of the system.

To obtain a preliminary estimation of the number of bits to choose for the DAC

=== Reconstruction Filter

The reconstruction filter's objective is to filter out the DAC's replicas of the input signal. Therefore, the values present in table @tab:TX_filter_specifications were chosen to design the filter.

#figure(
  caption: [TX baseband filter specifications.],
  table(
    columns: 2,
    align: center,
    [$f_1$], [$10 "MHz"$],
    table.hline(),
    [$f_2$], [$15 "MHz"$],
    table.hline(),
    [$A_"max"$], [$0.5 "dB"$],
    table.hline(),
    [$A_"min"$], [$40 "dB"$],
    table.hline(),
  ),
) <tab:TX_filter_specifications>

The frequency $f_1$ was chosen such that the useful band of $20 "MHz"$ is not attenuated, while $f_2$ was chosen such that every replica of the signal created by the DAC is attenuated. $A_"max"$ was chosen to follow the maximum allowed ripple according to the specifications, and $A_"min"$ has a high enough value to attenuate the replicas and to improve the ACPR at the end of the chain.

Its implementation in code is done through a FIR filter to avoid non-constant group delay. It is also considered ideal and does not add noise to the signal.

=== Up Sampling Mixer

The IQ's objective is to reconstruct the full signal, received through the in-phase and in-quadrature components, and shift its frequency to be centered around its own local oscillator frequency $f_"LO"$. To do this, it mixes on one side the in-phase signal with a sinusoidal signal from its local oscillator, and on the other the in-quadrature signal with the same sinusoidal but with its phase delayed in $pi"/"2$. After this initial mixing, it combines both signals effectively as a sum.
    
The output of the combiner-mixer is modelled by:
$ y(t) = x^I(t) cos(2 pi f_"LO" t) - x^Q(t) sin(2 pi f_"LO" t) $

where $x^I(t)$ is the in-phase signal and $x^Q(t)$ is the in-quadrature signal. Developing the equation:
$
y(t) &= A_I cos(2 pi f_{1} t) cos(2 pi f_"LO" t) - A_Q sin(2 pi f_{1} t) sin(2 pi f_"LO" t) \
y(t) &= (A_I - A_Q)/2 cos(2 pi (f_1 - f_"LO") t) + (A_I + A_Q)/2 cos(2 pi (f_1 + f_"LO") t)
$

Therefore, when the amplitudes are equal ($A_I = A_Q$), the output signal is simply the input signal with its frequency spectrum shifted to be centered around $f_"LO"$, as shown in the following equation:

$ y(t) = A cos(2 pi (f_1 + f_"LO") t) $

This shows that the up sampling mixer does not impact the signal power out of the DAC.

=== Power Amplifier

As the last step in the transmission chain implementation we must choose the power amplifier to use in system among the five choices given in the specifications. @tab:PA_details details all the power amplifiers available.

#figure(
  caption: [Power Amplifier specs.],
  table(
    columns: 6,
    align: center,
    table.header(
        [],[ZX60_V63+],[ZX60_V62+],[ZHL42],[ADL5606],[RFLUPA05M06G]
    ),
    [Gain (dB)],[19.7],[15.5],[39.46],[21.45],[33],
    table.hline(),
    [Power (W)],[0.345],[0.410],[13.2],[1.9],[4.2],
    table.hline(),
    [IIP3],[10.3],[16.4],[5.39],[23.4],[10],
    table.hline(),
    [$"P"_"1dB"$ (dBm)],[17.8],[19],[28],[30],[29],
    table.hline(),
  ),
) <tab:PA_details>

From the table, we can immediately see that while the ZX60_V63+ and ZX60_V62+ have the lowest power consumption among the options, operating them at $20 "dBm"$ of output would put them beyond the $1 "dB"$ compression point, leading to heavy non-linearities and a steep decrease in the ACPR. Among the remaining options, the ADL5606 power amplifier offers at the same time the highest IIP3, highest $1 "dB"$ gain compression power, and lowest power consumption, presenting itself as the best choice available.

However, to verify the validity of this choice, we will test them in simulation and calculate the ACPR at $20 "dBm"$ output power for each one. The output spectrum of each one is presented in x, and the ACPR in @tab:PA_ACPR. We must observe that all the power amplifiers have a higher gain than necessary for the desired output level. To each amplifier input signal was added a proportional attenuation to ensure the correct output.

#figure(
  caption: [Power Amplifier ACPR at $20 "dBm"$ output power.],
  table(
    columns: 6,
    align: center,
    table.header(
        [],[ZX60_V63+],[ZX60_V62+],[ZHL42],[ADL5606],[RFLUPA05M06G]
    ),
    [ACPR (dB)],[19.7],[15.5],[39.46],[21.45],[33],
    table.hline(),
    [Attenuation (dB)],[19.7],[0],[39.46],[21.45],[33],
    table.hline(),
  ),
) <tab:PA_ACPR>



=== Full TX chain

As e

== Transmission Channel

In this project we will be considering a memoryless channel that can have its attenuation fully characterized by the Friis transmission equation, shown in @eq:Friis_transmission. In this equation $G_r$ is the receiver gain, $G_e$ the transmitter gain, $P_r$ the power received, $P_e$ the power transmitted, $lambda$ the wavelength of the transmitted signal, and $d$ the distance between the transmitter and the receiver.

$ P_r = G_r G_e P_e ((lambda)/(4 pi d)) $ <eq:Friis_transmission>

In this project, the distance between the receiver and the transmitter covers a range from $d=1.4 thin "m"$ to $d=1.4 thin "km"$. We also shall consider that the transmitting and receiving antennas provide no gain ($G_r = G_e = 1$). Therefore, we can write the channel attenuation in dB as in equation @eq:Friis_att.

$ "Att" = 20 times log ((lambda)/(4 pi d)) $ <eq:Friis_att>

Solving the equation considering for both limits of $d$ and considering $lambda$ for the case of our $2.4 "GHz"$ signal, we get:

$ "Att" = [-42.97, -102.97] "dB" $

Therefore, knowing that the output of the transmission chain will always have $20 "dBm"$ of power, we can calculate the input power of the receiver as the range:

$ P_r = 20 "dBm" + "Att" = [-22.97, -82.97] "dBm" $

Besides that, we must also consider the antenna noise added to the signal through the transmission process, which corresponds to the thermal noise given in equation @eq:thermal_noise.

$ N_r = 10 times log ((k T B)/(1 "mW")) = -101 "dBm" $ <eq:thermal_noise>

Thus, subtracting the noise power from the input power we can calculate the input SNR range as:

$ "SNR"_r = [78.03, 18.03] $

Having characterized the input signal of the receiver, we can proceed in designing its individual components.

== Receiver (RX)

The RF reception chain implemented in this project is described by @fig:RX_chain. The general specifications that will guide its design can equally be found in @tab:RX_specifications.
#figure(
  image("./assets/RX_fig.png", width: 80%),
  caption: [RX reception chain with all its individual components.]
) <fig:RX_chain>

#figure(
  caption: [RX specifications.],
  table(
    columns: 2,
    align: center,
    [SNR Receiver Out], [$>10 "dB"$],
    table.hline(),
    [In-band ripple], [$<1 "dB"$],
    table.hline(),
    [RF Bandwidth], [$30 "MHz"$],
    table.hline(),
    [Useful Bandwidth], [$20 "MHz"$],
    table.hline(),
    [Central Frequency], [$2.4 "GHz"$],
    table.hline(),
    [Matching Resistance], [$50 thin Omega$],
    table.hline(),
    [Temperature], [$290 "K"$],
    table.hline(),
    [ADC Full Scale], [$plus.minus 1 "V"$],
    table.hline(),
  ),
) <tab:RX_specifications>

From the channel analysis and the given specifications, we can start by determining the full chain gain needed for the input signal based on the ADC full range. Considering that a sinusoidal is being transmitted, and that we desire it to cover the ADC full scale when at its maximum input power, we can determine that the desired signal power at the ADC input is:

$ P_(A D C) = 10 times log (((1 "V")^2)/(2 times (50 thin Omega)) times 1/(1 "mW")) = 10 "dBm" $

Therefore, to prevent saturation of the ADC while still using its full resolution, we need a gain that takes the maximum input power from $-22.97 "dbm"$ to $10 "dBm"$:

$ G_("chain") = 10 "dBm" + 22.97 "dBm" = 32.97 "dBm" $

This gain will be affected by the LNA, the mixer and the baseband amplifier.

Similarly, we also desire an output SNR of at least $10 "dB"$. Since the minimum input SNR is of $18.03 "dB"$, we must establish a maximum noise factor for the chain of:

$ "NF"_"chain" = 18.03 "dBm" - 10 "dBm" = 8.03 "dBm" $

This noise factor will be affected by the LNA, the baseband amplifier and the ADC.

Now this report will go through each element of the reception chain and use the given specifications to model the desired parameters.

=== Low Noise Amplifier

The low noise amplifier, as the first amplification stage of the system, must provide a considerable amplification with the lowest possible noise added, as the Friis formula for noise shows that it has the greatest weight in the overall noise:

$ F_("chain") = F_("LNA") + (F_("rest") - 1)/(G_("LNA")) $ <eq:Friis_noise>

We can also see that increasing its gain reduces the noise contribution of subsequent elements of the chain, which is a desired result. Therefore, we decide to adopt the highest gain permitted by the specifications, which gives us:

$ G_("LNA") = 15 "dB" $

To determine its noise contribution, we must also determine the contributions of the baseband amplifier and the ADC. Thus, this analysis will be conducted later in the report. However, we must advance that the LNA noise figure is inversely proportional to the power it consumes (@eq:LNA_power), which must be taken into account when choosing its value.

$ "P"_"LNA" = 10^(-2)/(10^("NF"_"LNA"/10) - 1) $ <eq:LNA_power>

At last, the IIP3 value of 0 dBm was adopted, such that the LNA operates in its linear region.

== Down Sampling Mixer

To determine the down sampling mixer's impact in the system, we consider a modulated signal $v_"in"(t)$ as input of the mixer and analyse its I and Q outputs. Let us consider the following input signal, where $omega_"LO"$ is the frequency of the local oscillator:

$ v_"in" (t) = I(t) cos (omega_"LO" t) + Q(t) sin (omega_"LO" t) $

The Local Oscillator (LO) generates two unmodulated quadrature carriers with an ideal amplitude of 1:
$ v_"LO,I" (t) = cos(omega_"LO" t) $
$ v_"LO,Q" (t) = sin(omega_"LO" t) $

Considering an ideal mixer in our case, the input signal is then split and multiplied by the LO signals to obtain the I and Q components.

$ v_I (t) &= v_"in" (t) cos(omega_"LO" t) \
&= I(t)/2 [1 + cos(2 omega_"LO" t)] - Q(t)/2 sin(2 omega_"LO" t) $

$ v_Q (t) &= v_"in" (t) sin(omega_"LO" t) \
&= -I(t)/2 sin(2 omega_"LO" t) + Q(t)/2 [1 + cos(2 omega_"LO" t)] $

A down-conversion mixer is always followed by a low-pass filter to remove the high-frequency mixing products, leaving only the baseband signals:

$ v_"I,filt" (t) &= I(t)/2 \
  v_"Q,filt" (t) &= Q(t)/2 $
  
Thus we conclude that on average, and especially in the case where $v_"in" (t) = sin((omega_"sig" + omega_"LO") t)$ as is the case in the simulations, the signal power in each arm will be one fourth of the input value, which translates into a $6 "dB"$ loss.

Therefore, this $6 "dB"$ loss in each arm must be considered in our chain gain calculations.

== Anti-Alias Filter

After the down-mixer the signal passes through a low-pass filter, which seeks to attenuate the replica of the signal at $2 f_("LO")$ and the noise outside the useful band, preventing both from being aliased into the useful signal when passing through the ADC.

Therefore, for it to execute its function with the highest possible performance and while respecting the system requirements, we adopt the parameters in table @tab:RX_filter_specifications.

#figure(
  caption: [RX baseband filter specifications.],
  table(
    columns: 2,
    align: center,
    [$f_1$], [$10 "MHz"$],
    table.hline(),
    [$f_2$], [$15 "MHz"$],
    table.hline(),
    [$A_"max"$], [$0.5 "dB"$],
    table.hline(),
    [$A_"min"$], [$40 "dB"$],
    table.hline(),
  ),
) <tab:RX_filter_specifications>

The useful band of the signal has $20 "MHz"$, which justifies the choice of $f_1$. The choice of $f_2$ seeks to prevent aliasing in the ADC. $A_"max"$ comes from the system specifications. And $A_"min"$ provides a good attenuation for signals outside the useful band.

The filter is again implemented as a FIR filter to avoid non-constant group delay. It is also ideal and should not have a noticeable impact in the power and noise of the useful signal.

== Baseband Amplifier

After the filter, we have the baseband amplifier, which provides a final amplification step to ensure the signal amplitude meets the ADC full scale. We can easily determine its theoretical gain through the following equation which sums all the gains in the chain:

$ G_"chain,dB" = G_"LNA,dB" + G_"mixer,dB" + G_"BBamp,dB" $

Therefore, substituting the values already calculated we can determine $G_"BBamp,dB"$ as:

$ 32.97 = 15 -6 + G_"BBamp,dB" arrow.r.double.long G_"BBamp,dB" = 23.97 "dB" $

In practice, a slightly lower value of $G_"BBamp,dB" = 23.5 "dB"$ was employed in the simulated system to prevent the saturation of the ADC, which always leads to catastrophic results in the output signal.

In terms of noise factor, the system specifications define a fixed value of $N F_"BBamp" = 10 "dB"$, which is employed in the simulations. Since no limitations are outlined in terms of IIP3, we decided to employ the default value in the provided code.

== Analog to Digital Converter

This last step in the reception chain is extremely relevant to the noise calculations, as the choice of the number of bits used by the ADC will determine the quantization noise it adds to the signal. Therefore, we must balance how much power it consumes and how much quantization noise it adds to the signal (@eq:SQNR), both controlled by its number of bits (@eq:PADC). Observe that in the provided equations, $N$ represents the number of bits, ENOB the effective number of bits (which we adopt as equal to $N$ for practical purposes), and $C$ a constant that incorporates parameters not immediately relevant to the analysis.

$ "SQNR" = 6.02 dot N + C $ <eq:SQNR>
$ P_"ADC" = 10^(-13) dot f_s dot 2^("ENOB") $ <eq:PADC>

Based on this fact, we need to share the noise budget of the system between the ADC and the LNA in such a way that the total power consumption is minimized. 

Since there is no easy way to calculate the noise factor of the ADC to determine its number of bits theoretically, we decided to create a simulation of the full RX chain, considering an LNA with $"NF"_"LNA" = 0$ and a sinusoidal input of power $-82.97 "dB"$ summed with thermal noise (the minimum power input). In this way, we vary the number of bits of the ADC, measuring the SNR of the output and the total power consumed (excluding the LNA). Based on the output SNR, we calculate the noise figure of the whole system excluding the LNA and determine its own noise figure using @eq:Friis_noise such that the total reaches $"NF" = 10 "dB"$. Finally, we calculate the power consumed by the LNA and provide a full estimate for the system.

The results are shown in @tab:ADC_calculations.

#figure(
  caption: [Power consumption and LNA noise figure as a function of N.],
  table(
    columns: 7,
    align: center,
    table.header(
        [N],[$"SNR"_"dB"$],[$"F"_"rest"$],[$"F"_"LNA"$],[$"P"_"rest"$ (mW)],[$"P"_"LNA"$ (mW)],[$"P"_"total"$ (mW)]
    ),
    [11],[6.0275],[-],[-],[-],[-],[-],
    table.hline(),
    [12],[12.247],[3.787],[3.523],[69],[4],[73],
    table.hline(),
    [13],[15.524],[1.781],[5.529],[94],[2],[96],
    table.hline(),
  ),
) <tab:ADC_calculations>

From the table, we see that the ideal choice consists of an ADC with 12 bits and an LNA with $"NF"_"LNA" = 10 dot log(3.523)= 5.4 "dB"$. Interestingly, we can also observe that reducing the number of bits of the ADC to 11 leads to a $6 "dB"$ loss in the SNR, which indicates that it is the point where quantization noise completely overwhelms the other noise sources, according to @eq:SQNR.

Testing these values in simulation they were mostly correct, leading to a final SNR of $10.4 "dB"$.

=== Full RX Simulation

To finalize this section after having successfully designed all the individual components, we execute two RX simulations to show the system performance for sinusoidal signals in both power (and SNR) extremes, as described in the channel section.



= Hardware Experiments

== Low Noise Amplifier Measurement

In this part, the LNA TB-432-8A+ from _Minicircuit_ was characterized. By using a vector analyser, the curves in @lna-gain, @lna-s11 and @lna-s21 were measured.
From them, we can see that, at $f = 900 "MHz"$, the Return Loss is $S_"11" = -15 "dB"$, the gain is $S_"21" = 14.8 "dB"$, and that, the $1 "dB"$ compression point happens at 
$-11 "dBm"$ with $S_"21" = 13.7 "dB"$.

#create-lna-figure("data/PA-measurements/power_compression.csv", [Gain x Power], [Measured curve of the Gain x Power for the TB-432-8A+ LNA at $900 "MHz"$.],
                   [Power (dBm)], [Gain (dB)], 0) <lna-gain>
#create-lna-figure("./data/PA-measurements/s12.csv", [S11], [Measured $S_"11"$ curve for the TB-432-8A+ LNA.],
                   [Frequency (MHz)], [Power (dBm)], 6) <lna-s11>
#create-lna-figure("data/PA-measurements/s11.csv", [S21], [Measured $S_"21"$ curve for the TB-432-8A+ LNA.],
                   [Frequency (MHz)], [Power (dBm)], 6) <lna-s21>


== Power Amplifier Measurements

Here, the ZX60_V62 Power Amplifier (given to our group) was measured using the SDR ADALM-PLUTO. The resulting performance curves 
can be found at @pa-am-am, @pa-gain and @pa-eff. As these values were gathered "manually", the measurement points are more concentraded at the compression point of the PA gain.

#create-pa-am-am-figure("data/ZX60_V62.csv", [ZX60_V62 - AM/AM], [Curve of the measured AM/AM for the ZX60_V62 PA.],
                        [Input (dBm)], [Output (dBm)]) <pa-am-am>
#create-pa-gain-figure("data/ZX60_V62.csv", [ZX60_V62 - Gain/Power], [Curve of the measured Gain/Power for the ZX60_V62 PA.], 
                       [Input Power (dBm)], [Gain (dB)]) <pa-gain>
#create-pa-efficience-figure("data/ZX60_V62.csv", [ZX60_V62 - $eta_("DE")$ and $eta_("PAE")$], [Curve of the measured $eta_("DE")$ and $eta_("PAE")$ for the ZX60_V62 PA.], 
                             [Power (dBm)], [$eta_("DE")$], [$eta_("PAE")$]) <pa-eff>

From these values, more static values were calculated and can be found in the left table @pa-meas. Comparing them with the numbers 
provided by the datasheet (right table) we can see that they closely match, with the exception of the $P_"1dB"$ point, which happened 
earlier than expected in our measurements.

#figure(
  align(center + top,
    grid(
      columns: 2,
      gutter:10%,
      figure(
        table(
          columns: 3,
          [*Performances*],[*Value*],[*Unit*],
          [Gain],[$15.6$],[dB],
          [$P_(1"dB")$],[$12$],[dBm],
          [$V$],[$5$],[V],
          [$I$],[$79$],[mA],
          [$P$],[$0.395$],[W],
        ),
        caption: "Measured performance values for the ZX60_V62 PA",
      ),
      figure(
        table(
          columns: 3,
          [*Performances*],[*Value*],[*Unit*],
          [Gain],[$15.4$],[dB],
          [$P_(1"dB")$],[$19$],[dBm],
          [$V$],[$5$],[V],
          [$I$],[$82$],[mA],
          [$P$],[$0.41$],[W],
        ),
        caption: "Datasheet performance values for the ZX60_V62 PA",
      ),
    )
  ),
  caption: "Comparison of the measured and expected performance values for the ZX60_V62 PA",
)<pa-meas> 

== Pluto Self-Communication

In this last part we used the ADALM-PLUTO SDR to emulate the transceiver chain, and see how its performance varies with 
the different ways the transmitter can change its transmission gain.

You can see from @pluto-self the experiment results, which match the expected behaviour of the system quickly dropping in 
performance as the signal gets too weak, becoming difficult to reconstruct the symbol constellation. We can also see how 
the system is much more sensitive to a low Full Scale than a low Gain, meaning that it's better to first reduce the gain
than the Full Scale when optimizing the chain.

#figure(
  align(center + bottom,
    grid(      
      columns: (auto, auto),
      gutter: 6pt,
      create-ser-ber-figure("./data/exp_self__fixed-dac.csv", [Full Scale at $-10 "dBFS"$.], [Gain (dB)]),
      create-ser-ber-figure("./data/exp_self__fixed-gain.csv", [Fixed Gain at $-10 "dB"$.], [Full Scale (dBFS)])
    )
  ),
  caption: [SER and BER curves for the transceiver chain emulated by a single ADALM-PLUTO with the reception gain fixed at $G_"RX" = -10 "dB"$ and 
            varying the transmitter Gain or the DAC Full Scale.],
) <pluto-self>

= Conclusion

As discussed in this report, a lot goes into modeling and optimizing a communication chain. But it is important to note that there 
are important differences between the simulated/optimized system and the experimental one. 

For starters, we can look at how the ADALM-PLUTO differs from the AD9363 base circuit, as shown by @tab:code_information.

#figure(
    caption: [Comparison between the ADALM-PLUTO and the base AD9363 circuit.],
    table(
      columns: (1fr, 1fr, 1fr),
      inset: 12pt,
      align: center,
      stroke: 0.6pt,

      table.header(
        [],[AD9363],[ADALM-Pluto],
      ),

      table.hline(),

      [Transmitters],
      [$2$],[$1$],

      table.hline(),

      [Receivers],
      [2],[1],

      table.hline(),

      [Local Oscillator Freq.],
      table.cell(colspan: 2, $325 "MHz to" 3.8 "GHz"$),

      table.hline(),

      [Sampling Frequency],
      table.cell(colspan: 2, $65.2 "kSPS to" 61.44 "MSPS"$),

      table.hline(),

      [Transmitted Power],
      [$7.5 "dBm"$],[$7 "dBm"$],

      table.hline(),

    ),
  ) <tab:code_information>

