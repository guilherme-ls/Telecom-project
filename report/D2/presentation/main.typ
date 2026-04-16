#import "@preview/diatypst:0.9.1": *

#import "@preview/lilaq:0.5.0" as lq

#let create-pa-am-am-figure(file, tit, cap, ax_x, ax_y) = {
  let (x, y, z) = lq.load-txt(read(file))

  let n = 0;
  let input = while n < x.len() {
    n = n + 1
    (x.at(n - 1) + 4.3, )
  }
  n = 0;
  let output = while n < y.len() {
    n = n + 1
    (y.at(n - 1) + 30, )
  }

  figure(
    lq.diagram(
      width: 12cm,
      height: 6cm,

      lq.plot(
        input, output,
        mark-size: 5pt,
        mark: lq.marks.at("d"),
        stroke: (thickness: 1pt)
      ),

      lq.plot(
        input, x => x + 15.6,
        mark-size: 0pt,
        stroke: (thickness: 1pt, dash: "dashed")
      ),

      title: tit,

      ylabel: ax_y,
      xlabel: ax_x,
      xaxis: (subticks: none),
      legend: (position: left + bottom)
    ),

    caption: cap,
  )
}

#let create-pa-gain-figure(file, tit, cap, ax_x, ax_y) = {
  let (x, y, z) = lq.load-txt(read(file))
  let n = 0;
  let input = while n < x.len() {
    n = n + 1
    (x.at(n - 1) + 4.3, )
  }
  n = 0;
  let output = while n < y.len() {
    n = n + 1
    (y.at(n - 1) + 30, )
  }
  n = 0;
  let gain = while n < x.len() {
    n = n + 1
    (output.at(n - 1) - input.at(n - 1), )
  }
  figure(
    lq.diagram(
      width: 12cm,
      height: 6cm,

      lq.plot(
        input, gain,
        mark-size: 10pt,
        stroke: (thickness: 1pt)
      ),
      lq.plot(
        input, x => 15.6, 
        mark-size: 0pt,
        stroke: (thickness: 1pt, dash: "dashed")
      ),

      title: tit,

      ylabel: ax_y,
      xlabel: ax_x,
      xaxis: (subticks: none),
      legend: (position: left + bottom)
    ),

    caption: cap,
  )
}

#let create-pa-efficience-figure(file, tit, cap, ax_x, ax_y, ax_y2) = {
  let (x, y, z) = lq.load-txt(read(file))
  let n = 0;
  let input = while n < x.len() {
    n = n + 1
    (x.at(n - 1) + 4.3, )
  }
  n = 0;
  let output = while n < y.len() {
    n = n + 1
    (y.at(n - 1) + 30, )
  }
  n = 0;
  let power = while n < z.len() {
    n = n + 1
    (z.at(n - 1) * 5, )
  }
  n = 0;
  let efficience-pae = while n < power.len() {
    n = n + 1
    ( ((calc.pow(10,output.at(n - 1)/10) - calc.pow(10,input.at(n - 1)/10))) / power.at(n - 1), )
  }
  n = 0;
  let efficience-de = while n < power.len() {
    n = n + 1
    ( (calc.pow(10,output.at(n - 1)/10)) / power.at(n - 1), )
  }
  figure(
    lq.diagram(
      width: 12cm,
      height: 6cm,      

      lq.plot(
        input, efficience-de,
        mark-size: 5pt,
        stroke: (thickness: 1pt),
        label: ax_y
      ),
      lq.plot(
        input, efficience-pae,
        mark-size: 5pt,
        stroke: (thickness: 1pt, dash: "dashed"),
        label: ax_y2
      ),
      lq.yaxis(
        position: right,
        label: ax_y2,
      ),

      title: tit,

      ylabel: ax_y,
      xlabel: ax_x,
      xaxis: (subticks: none),
      legend: (position: left + top)
    ),

    caption: cap,
  )
}

#let create-ser-ber-figure(file, tit, cap, ax_x) = {
  let (x, ser, ber) = lq.load-txt(read(file))
  figure(
    grid(      
      columns: 1,
      gutter: 6pt,
      lq.diagram(
        height: 3cm,
        width: 6cm,
        lq.plot(
          x, ser,
          mark-size: 5pt,
          stroke: (thickness: 1pt)
        ),

        //title: tit,

        ylabel: [SER],
        //xlabel: ax_x,
        xaxis: (subticks: none),
        legend: (position: left + bottom)
      ),
      lq.diagram(
        height: 3cm,
        width: 6cm,
        lq.plot(
          x, ber,
          mark-size: 5pt,
          stroke: (thickness: 1pt)
        ),

        //title: tit,

        ylabel: [BER],
        xlabel: ax_x,
        xaxis: (subticks: none),
        legend: (position: left + bottom)
      ),
    ),
    caption: cap,
  )
}


#show: slides.with(
  title: "Radio-frequency system and hardware modeling", // Required
  subtitle: "Performance Analysis of a realistic Cloud Radio Access Network (C-RAN)",
  date: "2025-2026",
  authors: (
    "LOUROSA RECH Bernardo",
    "LORETE SCHMIDT Guilherme",
    "PANCHENIAK FILHO Ivan Roberto Wagner"
  ),
  // Optional (for more see docs at https://mdwm.org/diatypst/)
  ratio: 16/9,
  count: "dot-section",
  layout: "medium",
  title-color: blue.darken(60%),
  toc: true,
)

= System Simulation

== Transmitter (TX)

#figure(
  image("../report/assets/TX_fig.png", width: 80%),
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

== DAC

#figure(
  image("./assets/DAC_styles.png", width: 95%),
  caption: [Zero order holder and zero padding DAC output spectrums.]
) <fig:DAC_styles>

#figure(
  image("./assets/DAC_ACPR.png", width: 95%),
  caption: [DAC output ACPR per number of bits considering a 16-QAM modulated input.]
) <fig:DAC_ACPR>

== Reconstruction Filter

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

== Upsampling Mixer

The output of the combiner-mixer is modelled by:
$ y(t) = x^I(t) cos(2 pi f_"LO" t) - x^Q(t) sin(2 pi f_"LO" t) $

where $x^I(t)$ is the in-phase signal and $x^Q(t)$ is the in-quadrature signal. Developing the equation:
$
y(t) &= A_I cos(2 pi f_{1} t) cos(2 pi f_"LO" t) - A_Q sin(2 pi f_{1} t) sin(2 pi f_"LO" t) \
y(t) &= (A_I - A_Q)/2 cos(2 pi (f_1 - f_"LO") t) + (A_I + A_Q)/2 cos(2 pi (f_1 + f_"LO") t)
$

Therefore, when the amplitudes are equal ($A_I = A_Q$), the output signal is simply the input signal with its frequency spectrum shifted to be centered around $f_"LO"$, as shown in the following equation:

$ y(t) = A cos(2 pi (f_1 + f_"LO") t) $

== Power Amplifier

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

#figure(
  caption: [Power Amplifier ACPR at $20 "dBm"$ output power.],
  table(
    columns: 6,
    align: center,
    table.header(
        [],[ZX60_V63+],[ZX60_V62+],[ZHL42],[ADL5606],[RFLUPA05M06G]
    ),
    [ACPR (dB)],[19.7204],[24.8733],[54.1656],[53.1469],[50.3882],
    table.hline(),
    [Attenuation (dB)],[4.4],[0],[24.2],[6.2],[17.7],
    table.hline(),
  ),
) <tab:PA_ACPR>

#figure(
  image("./assets/PA_ACPR.png", width: 60%),
  caption: [PA output around $2.4 "GHz"$, for different PAs.]
) <fig:PA_ACPR>

== Full TX chain

#figure(
  image("./assets/TX_chain.png", width: 70%),
  caption: [Signal spectrum through different points of the TX chain.]
) <fig:TX_chain_signal>

We can observe that the transmission chain performs as expected, giving us a $19.9385 "dBm"$ of power at the output and having an ACPR of $-54.2316 "dB"$. Power consumption of the TX chain is of $1.9303 "W"$.

== Transmission Channel

$ "Att" = 20 times log ((lambda)/(4 pi d)) $ <eq:Friis_att>

$ "Att" = [-42.97, -102.97] "dB" $

$ P_r = 20 "dBm" + "Att" = [-22.97, -82.97] "dBm" $

$ N_r = 10 times log ((k T B)/(1 "mW")) = -101 "dBm" $ <eq:thermal_noise>

$ "SNR"_r = [78.03, 18.03] $

== Receiver

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

$ G_("chain") = 10 "dBm" + 22.97 "dBm" = 32.97 "dBm" $

$ "NF"_"chain" = 18.03 "dBm" - 10 "dBm" = 8.03 "dBm" $

== Low Noise Amplifier

$ F_("chain") = F_("LNA") + (F_("rest") - 1)/(G_("LNA")) $ <eq:Friis_noise>

$ G_("LNA") = 15 "dB" $

$ "P"_"LNA" = 10^(-2)/(10^("NF"_"LNA"/10) - 1) $ <eq:LNA_power>

The IIP3 value of 0 dBm was adopted.

== Down Sampling Mixer

$ v_"in" (t) = I(t) cos (omega_"LO" t) + Q(t) sin (omega_"LO" t) $

$ v_"LO,I" (t) = cos(omega_"LO" t) $
$ v_"LO,Q" (t) = sin(omega_"LO" t) $


$ v_I (t) &= v_"in" (t) cos(omega_"LO" t) = I(t)/2 [1 + cos(2 omega_"LO" t)] - Q(t)/2 sin(2 omega_"LO" t) $

$ v_Q (t) &= v_"in" (t) sin(omega_"LO" t) = -I(t)/2 sin(2 omega_"LO" t) + Q(t)/2 [1 + cos(2 omega_"LO" t)] $


$ v_"I,filt" (t) &= I(t)/2 \
  v_"Q,filt" (t) &= Q(t)/2 $

Therefore, this $6 "dB"$ loss in each arm must be considered in our chain gain calculations.

== Anti-Alias Filter

After the down-mixer the signal passes through a low-pass filter, which seeks to attenuate the replica of the signal at $2 f_("LO")$ and the noise outside the useful band, preventing both from being aliased into the useful signal when passing through the ADC.

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

== Baseband Amplifier

We can easily determine its theoretical gain through the following equation which sums all the gains in the chain:

$ G_"chain,dB" = G_"LNA,dB" + G_"mixer,dB" + G_"BBamp,dB" $

$ 32.97 = 15 -6 + G_"BBamp,dB" arrow.r.double.long G_"BBamp,dB" = 23.97 "dB" $

In practice, a slightly lower value of $G_"BBamp,dB" = 23.5 "dB"$ was employed in the simulated system to prevent the saturation of the ADC, which always leads to catastrophic results in the output signal.

In terms of noise factor, the system specifications define a fixed value of $N F_"BBamp" = 10 "dB"$.

== Analog to Digital Converter

$ "SQNR" = 6.02 dot N + C $ <eq:SQNR>
$ P_"ADC" = 10^(-13) dot f_s dot 2^("ENOB") $ <eq:PADC>

Since there is no easy way to calculate the noise factor of the ADC to determine its number of bits theoretically, we decided to create a simulation of the full RX chain, considering an LNA with $"NF"_"LNA" = 0$ and a sinusoidal input of power $-82.97 "dB"$.

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

From the table, we see that the ideal choice consists of an ADC with 12 bits and an LNA with $"NF"_"LNA" = 10 dot log(3.523)= 5.4 "dB"$.

== Full RX Simulation

#figure(
  image("./assets/RX_chain_1400.png", width: 80%),
  caption: [Signal at different points of the RX chain, whith the main peaks highlighted. This considers an input signal corresponding to the distance $d=1.4 "km"$.]
) <fig:RX_chain_sim_1400>

#figure(
  image("./assets/RX_chain_14.png", width: 80%),
  caption: [Signal at different points of the RX chain, whith the main peaks highlighted. This considers an input signal corresponding to the distance $d=1.4 "m"$.]
) <fig:RX_chain_sim_14>

#figure(
  image("./assets/RX_output_1400.png", width: 70%),
  caption: [Signal output of the chain considering an input signal corresponding to the distance $d=1.4 "km"$.]
) <fig:RX_output_sim_1400>
#figure(
  image("./assets/RX_output_14.png", width: 70%),
  caption: [Signal output of the chain considering an input signal corresponding to the distance $d=1.4 "m"$.]
) <fig:RX_output_sim_14>

== Complete TX/Rx Chain

#figure(
  image("./assets/Full_chain_1400.png", width: 80%),
  caption: [Signal spectrum through different points of the communication chain, considering a distance $d = 1.4 "km"$.]
) <fig:Full_chain_1400>

#figure(
  image("./assets/Full_chain_14.png", width: 80%),
  caption: [Signal spectrum through different points of the communication chain, considering a distance $d = 1.4 "m"$.]
) <fig:Full_chain_14>

#figure(
  image("./assets/SNRversusDist.png", width: 80%),
  caption: [SNR of the output signal for distances between $1.4 "m"$ and $1.4 "km"$ between the transmitter and the receiver.]
) <fig:SNR_dist>

= Hardware Experiments

== Power Amplifier Measurements

#create-pa-am-am-figure("data/ZX60_V62.csv", [ZX60_V62 - AM/AM], [Curve of the measured AM/AM for the ZX60_V62 PA.], [Input (dBm)], [Output (dBm)])
#create-pa-gain-figure("data/ZX60_V62.csv", [ZX60_V62 - Gain/Power], [Curve of the measured Gain/Power for the ZX60_V62 PA.], [Power (dBm)], [Gain (dB)])
#create-pa-efficience-figure("data/ZX60_V62.csv", [ZX60_V62 - $eta_("DE")$ and $eta_("PAE")$], [Curve of the measured $eta_("DE")$ and $eta_("PAE")$ for the ZX60_V62 PA.], [Power (dBm)], [$eta_("DE")$], [$eta_("PAE")$])
#align(center + top,
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
        [$I$],[$89$],[mA],
        [$P$],[$0.445$],[W],
      ),
      caption: "Measured",
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
      caption: "Datasheet",
    ),
  )
)

== Pluto Self-Communication

#show figure.caption: set text(size: 8pt)
#align(center + bottom,
  grid(      
    columns: (auto, auto),
    gutter: 6pt,
    create-ser-ber-figure("./data/exp_self__fixed-dac.csv", [A], [Full Scale at $-10 "dBFS"$ (and $G_"RX" = -10 "dB"$).], [Gain (dB)]),
    create-ser-ber-figure("./data/exp_self__fixed-gain.csv", [A], [Fixed Gain at $-10 "dB"$ (and $G_"RX" = -10 "dB"$).], [Full Scale (dBFS)])
  )
)

== Pluto Communication Demos

#text(size: 12.5pt, [
  - Wired Single Pluto Communication Demo
  - Wireless Pluto to Pluto Communication 
])

== TX Pre Processing

1. Preamble addition
  - Barker Sequence
    - Sequence with high autocorrelation
      - Makes it easy to find from random symbols in RX
  
2. RRC Filter 
  - Upsampling of the signal
  - Ensures the symbols don't "mix" with each other (reduce ISI)

== RX Post Processing

1. Coarse Frequency Compensation
  - Operates over the whole symbol stream
  - Helps with differences in the LO frequencies
  - Tries to make the symbols fit into the expected constellation type (QAM)
  - Internal PLL with PID
  - Does *not* decimate the signal
2. RRC Filter 
  - Operates over the whole symbol stream after it is compensated
  - Helps to shape the symbols back to what they are supposed to be 
  - Might have bad output from unaligned symbols
    - Loop over the different possible delays to ensure we use the best one 
  - Decimates the signal
3. Carrier Synchronization (Fine Frequency Compensation)
  - Operates over the RRC decimated signal 
  - Helps to compensate what the coarse compensation might have missed
  - Tries to make the symbols fit into the expected constellation type (QAM)
  - Internal PLL with PID
  - Does *not* decimate the signal
4. Symbol Synchronization
  - Operates over the fine compensated symbols 
  - Attempts even further to shape the symbols into the constellation 
  - *Decimates* the signal
5. Preamble Detection
  - Helps us find the start of the message
  - Helps us to align the message in the time domain
  - The phase offset in the preamble tells us by how much the constellation is "rotated"


