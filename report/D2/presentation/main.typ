#import "@preview/diatypst:0.9.1": *

#import "@preview/lilaq:0.5.0" as lq

#let create-pa-am-am-figure(file, tit, cap, ax_x, ax_y) = {
  let (x, y, z) = lq.load-txt(read(file))

  let n = 0;
  let ideal = while n < x.len() {
    n = n + 1
    (x.at(n - 1) - 10.1, )
  }

  figure(
    lq.diagram(
      width: 12cm,
      height: 6cm,

      lq.plot(
        x, y,
        mark-size: 5pt,
        mark: lq.marks.at("d"),
        stroke: (thickness: 1pt)
      ),

      lq.plot(
        x, ideal,
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
  let gain = while n < x.len() {
    n = n + 1
    (y.at(n - 1) - x.at(n - 1), )
  }
  figure(
    lq.diagram(
      width: 12cm,
      height: 6cm,

      lq.plot(
        x, gain,
        mark-size: 10pt,
        stroke: (thickness: 1pt)
      ),
      lq.plot(
        x, x => -10.1,
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

#lorem(20)

#create-pa-am-am-figure("data/ZX60_V62.csv", [ZX60_V62 - AM/AM], [Curve of the measured AM/AM for the ZX60_V62 PA, with the line loss.], [Input (dB)], [Output (dB)])
#create-pa-gain-figure("data/ZX60_V62.csv", [ZX60_V62 - Gain/Power], [Curve of the measured Gain/Power for the ZX60_V62 PA, with the line loss.], [Power (dB)], [Gain (dB)])

#align(center + top,
  grid(
    columns: 2,
    gutter:10%,
    figure(
      table(
        columns: 3,
        [*Performances*],[*Value*],[*Unit*],
        [$P_(1"dB")$],[$-9$],[dB],
        [$V$],[$5$],[V],
        [$I$],[$89$],[mA],
        [$P$],[$0.445$],[W],
        [$eta_("PAE")$],[$0.5$],[],
        [$eta_("DE")$],[$0.5$],[],
      ),
      caption: "Measured",
    ),
    figure(
      table(
        columns: 3,
        [*Performances*],[*Value*],[*Unit*],
        [$P_(1"dB")$],[$-9$],[dB],
        [$V$],[$5$],[V],
        [$I$],[$89$],[mA],
        [$P$],[$0.445$],[W],
        [$eta_("PAE")$],[$0.5$],[],
        [$eta_("DE")$],[$0.5$],[],
      ),
      caption: "Datasheet",
    ),
  )
)


/ *Term*: Definition

== Pluto Self-Communication

#lorem(20)

/ *Term*: Definition
#show figure.caption: set text(size: 8pt)
#align(center + bottom,
  grid(      
    columns: (auto, auto),
    gutter: 6pt,
    create-ser-ber-figure("./data/exp_self__fixed-dac.csv", [A], [Full Scale at $-10 "dBFS"$ (and $G_"RX" = -10 "dB"$).], [Gain (dB)]),
    create-ser-ber-figure("./data/exp_self__fixed-gain.csv", [A], [Fixed Gain at $-10 "dB"$ (and $G_"RX" = -10 "dB"$).], [Full Scale (dBFS)])
  )
)
== Pluto Communication Demo

#lorem(20)

/ *Term*: Definition




