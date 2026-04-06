#import "template.typ": project

#import "@preview/equate:0.3.2": equate
#import "@preview/lilaq:0.5.0" as lq

// LTeX: language=en-US
// LTeX: statusBatItem=true 
//
#show: equate.with(breakable: true, sub-numbering: false)
#set math.equation(numbering: "(1.1)")

#let filter-positive(xdata, ydata) = {
  let pairs = xdata.zip(ydata)
  let filtered = pairs.filter(p => p.at(1) > 0)
  (
    filtered.map(p => p.at(0)),
    filtered.map(p => p.at(1)),
  )
}

#let load-eq(mod, eq, ch) = {
  let file = "./graphs/eq_sims/" + mod + "_" + eq + "_" + str(ch) + ".csv"
  let (x, y) = lq.load-txt(read(file))
  filter-positive(x, y)
}

// Ploting semilog from csv function
/*#let (bpsk_0_x, bpsk_0_y) = lq.load-txt(read("./graphs/bch_sims/bch0.csv"))
#let (bpsk_0_x_f, bpsk_0_y_f) = filter-positive(bpsk_0_x, bpsk_0_y)
#let (bpsk_1_x, bpsk_1_y) = lq.load-txt(read("./graphs/bch_sims/bch1.csv"))
#let (bpsk_1_x_f, bpsk_1_y_f) = filter-positive(bpsk_1_x, bpsk_1_y)
#let (bpsk_2_x, bpsk_2_y) = lq.load-txt(read("./graphs/bch_sims/bch2.csv"))
#let (bpsk_2_x_f, bpsk_2_y_f) = filter-positive(bpsk_2_x, bpsk_2_y)*/


#let create_resp_channel_fig(ch) = {
  let file = "./graphs/response-channel-" + str(ch) + ".csv"
  let (resp_chan_l_raw, resp_chan_h_raw) = lq.load-txt(read(file))
  //let resp_chan_h_abs = resp_chan_h_raw.map(calc.abs)
  //let (resp_chan_l, resp_chan_h) = filter-positive(resp_chan_l_raw, resp_chan_h_abs)
  figure(
    lq.diagram(
      width: 12cm,
      height: 9cm,

      lq.stem(
        resp_chan_l_raw, resp_chan_h_raw,
        mark: "o",
        stroke: (thickness: 1pt)
      ),
      title: [
        Coefficients of $h(m)$ for Channel #ch. 
      ],

      //yscale: lq.scale.scale(x => calc.log(calc.abs(x + 0.1)), x => x), //"log",
      //xscale: "linear",
      ylabel: [$h(m)$],
      xlabel: [$m$],
      xaxis: (subticks: none),
      legend: (position: left + bottom)
    ),

    caption: [
      Plot of the coefficients of $h(m)$ for Channel #ch from $-L$ to $L$.
    ],
  ) 
}

#set par(
  justify: true,
  leading: 0.52em,
)

#let create-pow-figure(file, tit, cap) = {
  let (x, y) = lq.load-txt(read(file))

  figure(
    lq.diagram(
      width: 15cm,
      height: 7cm,

      lq.plot(
        x, y,
        mark-size: 0pt,
        stroke: (thickness: 1pt)
      ),

      title: tit,

      ylabel: [Power (dBm)],
      xlabel: [Frequency (MHz)],
      xaxis: (subticks: none),
      legend: (position: left + bottom)
    ),

    caption: cap,
  )
}

#let create-lna-figure(file, tit, cap, ax_x, ax_y, power) = {
  let (x, y, z) = lq.load-txt(read(file))

  let divided = x.map(n => n / calc.pow(10, power))

  figure(
    lq.diagram(
      width: 15cm,
      height: 7cm,

      lq.plot(
        divided, y,
        mark-size: 0pt,
        stroke: (thickness: 1pt)
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
        [],
        [AD9363],
        [ADALM Pluto],
      ),

      table.hline(),

      [Transmitters],
      [$2$],
      [$1$],

      table.hline(),

      [Receivers],
      [2],
      [1],

      table.hline(),

      [Local Oscillator Freq.],
      table.cell(colspan: 2, $325 "MHz to" 3.8 "GHz"$),

      table.hline(),

      [Sampling Frequency],
      table.cell(colspan: 2, $65.2 "kSPS to" 61.44 "MSPS"$),

      table.hline(),

      [Transmitted Power],
      [$7.5 "dBm"$],
      [$7 "dBm"$],

      table.hline(),

      [Received Power],
      [?],
      [?],

      table.hline(),
    ),
  ) <tab:code_information>



  #create-pow-figure("data/tinySA/ONE-TONE.csv", [titutol], [algo])
  #create-pow-figure("data/tinySA/ONE-PA.csv", [titutol], [algo])
  #create-pow-figure("data/tinySA/TWO-TONE.csv", [titutol], [algo])
  #create-pow-figure("data/tinySA/TWO-PA.csv", [titutol], [algo])
  #create-pow-figure("data/tinySA/MOD-10.csv", [titutol], [algo])

== LNA Measurement

  #create-lna-figure("data/PA-measurements/power_compression.csv", [Power x Power], [algo], [Power (dBm)], [Gain (dB)], 0)
  #create-lna-figure("data/PA-measurements/s11.csv", [S11], [algo], [Frequency (MHz)], [Power (dBm)], 6)
  #create-lna-figure("data/PA-measurements/s12.csv", [S12], [algo], [Frequency (MHz)], [Power (dBm)], 6)
