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


= Introduction

  Something

= System Simulation

== Power Amplifier Characterization

  #figure(
    caption: [Generator polynomials and code rates of the studied BCH codes.],
    table(
      columns: (1fr, 1fr, 1fr),
      inset: 12pt,
      align: center,
      stroke: 0.6pt,

      table.header(
        [],[AD9363],[ADALM Pluto],
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

      [Received Power],
      [?],[?],

      table.hline(),
    ),
  ) <tab:code_information>



  #create-pow-figure("data/tinySA/ONE-TONE.csv", [titutol], [algo])
  #create-pow-figure("data/tinySA/ONE-PA.csv", [titutol], [algo])
  #create-pow-figure("data/tinySA/TWO-TONE.csv", [titutol], [algo])
  #create-pow-figure("data/tinySA/TWO-PA.csv", [titutol], [algo])
  #create-pow-figure("data/tinySA/MOD-10.csv", [titutol], [algo])
  #create-pow-figure("data/tinySA/MOD-20.csv", [titutol], [algo])

== LNA Measurement

  #create-lna-figure("data/PA-measurements/power_compression.csv", [Power x Power], [algo], [Power (dBm)], [Gain (dB)], 0)
  #create-lna-figure("data/PA-measurements/s11.csv", [S11], [algo], [Frequency (MHz)], [Power (dBm)], 6)
  #create-lna-figure("data/PA-measurements/s12.csv", [S12], [algo], [Frequency (MHz)], [Power (dBm)], 6)

= System Simulation

== Power Amplifier Characterization

#lorem(20)

/ *Term*: Definition

== LNA Measurement

#lorem(20)

/ *Term*: Definition

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


