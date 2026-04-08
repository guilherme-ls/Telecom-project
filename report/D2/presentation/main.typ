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

== RX Post Processing

1. A 
  - Ensures
2. B
  - Ensures
3. C
  - Ensures


