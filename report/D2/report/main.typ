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

= Hardware Experiments

== Low Noise Amplifier Measurement

In this part, the LNA TB-432-8A+ from _Miniciruit_ was characterized. By using a vector analyser, the curves in @lna-gain, @lna-s11 and @lna-s21 were measured.
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
can be found at @pa-am-am, @pa-gain and @pa-eff. As these values were gathered "manually", the measurement points are more concentraded 
at the compression point of the PA gain.

#create-pa-am-am-figure("data/ZX60_V62.csv", [ZX60_V62 - AM/AM], [Curve of the measured AM/AM for the ZX60_V62 PA.],
                        [Input (dBm)], [Output (dBm)]) <pa-am-am>
#create-pa-gain-figure("data/ZX60_V62.csv", [ZX60_V62 - Gain/Power], [Curve of the measured Gain/Power for the ZX60_V62 PA.], 
                       [Power (dBm)], [Gain (dB)]) <pa-gain>
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
          [$I$],[$89$],[mA],
          [$P$],[$0.445$],[W],
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

