#import "@preview/diatypst:0.9.1": *
#import "@preview/lilaq:0.5.0" as lq

// LTeX: language=en-US
// LTeX: statusBatItem=true

#let filter-positive(xdata, ydata) = {
  let pairs = xdata.zip(ydata)
  let filtered = pairs.filter(p => p.at(1) > 0)
  (
    filtered.map(p => p.at(0)),
    filtered.map(p => p.at(1)),
  )
}

#let filter-positive-2(xdata, ydata) = {
  let new-ydata = ()

  for y in ydata {
    if y == 0 and new-ydata.len() > 0 {
      new-ydata.push(new-ydata.last())
    } else {
      new-ydata.push(y)
    }
  }

  (xdata, new-ydata)
}

#let load-eq(mod, eq, ch) = {
  let file = "./data/d1/eq_sims/" + mod + "_" + eq + "_" + str(ch) + ".csv"
  let (x, y) = lq.load-txt(read(file))
  filter-positive(x, y)
}

#let load-eq-extra1(code, ch, eq) = {
  let file = "./data/d1/extra_bpks/bch" + str(code) + "_" + eq + "_" + str(ch) + ".csv"
  let (x, y) = lq.load-txt(read(file))
  filter-positive(x, y)
}

#let load-eq-extra2(code, mod, ch) = {
  let file = "./data/d1/extra_throughput/bch" + str(code) + "_" + mod + "_none_" + str(ch) + ".csv"
  let (x, y) = lq.load-txt(read(file))

  /*let x = if mod == "8QAM" {
    nt.add(x, nt.mult(10, nt.log(3)))
  } else {
    nt.add(x, nt.mult(10, nt.log(4)))
  }*/

  filter-positive(x, y)
}

#let load-eq-extra2-2(code, mod, ch) = {
  let file = "./data/d1/extra_throughput/bch" + str(code) + "_" + mod + "_none_" + str(ch) + ".csv"
  let (x, y) = lq.load-txt(read(file))

  /*let x = if mod == "8QAM" {
    nt.add(x, nt.mult(10, nt.log(3)))
  } else {
    nt.add(x, nt.mult(10, nt.log(4)))
  }*/

  filter-positive-2(x, y)
}

// Ploting semilog from csv function
#let (bpsk_0_x, bpsk_0_y) = lq.load-txt(read("./data/d1/bch_sims/bch0.csv"))
#let (bpsk_0_x_f, bpsk_0_y_f) = filter-positive(bpsk_0_x, bpsk_0_y)
#let (bpsk_1_x, bpsk_1_y) = lq.load-txt(read("./data/d1/bch_sims/bch1.csv"))
#let (bpsk_1_x_f, bpsk_1_y_f) = filter-positive(bpsk_1_x, bpsk_1_y)
#let (bpsk_2_x, bpsk_2_y) = lq.load-txt(read("./data/d1/bch_sims/bch2.csv"))
#let (bpsk_2_x_f, bpsk_2_y_f) = filter-positive(bpsk_2_x, bpsk_2_y)


#let create_resp_channel_fig(ch) = {
  let file = "./data/d1/response-channel-" + str(ch) + ".csv"
  let (resp_chan_l_raw, resp_chan_h_raw) = lq.load-txt(read(file))
  //let resp_chan_h_abs = resp_chan_h_raw.map(calc.abs)
  //let (resp_chan_l, resp_chan_h) = filter-positive(resp_chan_l_raw, resp_chan_h_abs)
  figure(
    lq.diagram(
      width: 4cm,
      height: 6cm,

      lq.stem(
        resp_chan_l_raw,
        resp_chan_h_raw,
        mark: "o",
        stroke: (thickness: 1pt),
      ),
      title: [
        Coefficients of $h(m)$ for Channel *#ch*.
      ],

      //yscale: lq.scale.scale(x => calc.log(calc.abs(x + 0.1)), x => x), //"log",
      //xscale: "linear",
      ylabel: [$h(m)$],
      xlabel: [$m$],
      xaxis: (subticks: none),
      legend: (position: left + bottom),
    ),
  )
}

#let create-ber-figure(mod, ch) = {
  let (x_none, y_none) = load-eq(mod, "none", ch)
  let (x_zf, y_zf) = load-eq(mod, "ZF", ch)
  let (x_dfe, y_dfe) = load-eq(mod, "DFE", ch)

  figure(
    lq.diagram(
      width: 16cm,
      height: 6cm,

      lq.plot(
        x_none,
        y_none,
        label: [No equalization],
        mark: "x",
        stroke: (thickness: 1pt),
      ),

      lq.plot(
        x_zf,
        y_zf,
        label: [ZF equalization],
        mark: "o",
        stroke: (thickness: 1pt),
      ),

      lq.plot(
        x_dfe,
        y_dfe,
        label: [DFE],
        mark: "+",
        stroke: (thickness: 1pt),
      ),

      title: [
        BER versus $E_b"/"N_0$ for distinct equalizations with *#mod* modulation in channel *#ch*
      ],

      yscale: "log",
      ylabel: [BER],
      xlabel: [$E_b"/"N_0 ("dB")$],
      xaxis: (subticks: none),
      legend: (position: left + bottom),
    ),
  )
}

#let extra-code-channel(ch, eq) = {
  let (x_none, y_none) = load-eq("PSK2", eq, ch)
  let (x_c1, y_c1) = load-eq-extra1(1, ch, eq)
  let (x_c2, y_c2) = load-eq-extra1(2, ch, eq)

  figure(
    lq.diagram(
      width: 16cm,
      height: 6cm,

      lq.plot(
        x_none,
        y_none,
        label: [No code],
        mark: "x",
        stroke: (thickness: 1pt),
      ),

      lq.plot(
        x_c1,
        y_c1,
        label: [BCH code 1],
        mark: "o",
        stroke: (thickness: 1pt),
      ),

      lq.plot(
        x_c2,
        y_c2,
        label: [BCH code 2],
        mark: "+",
        stroke: (thickness: 1pt),
      ),

      title: [
        BER versus $E_b"/"N_0$ for distinct codes with BPSK modulation and *#eq* equalization in channel *#ch*
      ],

      yscale: "log",
      ylabel: [BER],
      xlabel: [$E_b"/"N_0 ("dB")$],
      xaxis: (subticks: none),
      legend: (position: left + bottom),
    ),
  )
}

#let extra-throughput(mod, ch) = {
  let (x_none, y_none) = load-eq-extra2(0, mod, ch)
  let (x_c1, y_c1) = load-eq-extra2(1, mod, ch)
  let (x_c2, y_c2) = load-eq-extra2(2, mod, ch)

  figure({
    show: lq.set-grid(
      stroke-sub: 0.5pt + luma(80%),
    )

    lq.diagram(
      width: 16cm,
      height: 6cm,

      lq.plot(
        x_none,
        y_none,
        label: [No code],
        mark: "x",
        stroke: (thickness: 1pt),
      ),

      lq.plot(
        x_c1,
        y_c1,
        label: [BCH code 1],
        mark: "o",
        stroke: (thickness: 1pt),
      ),

      lq.plot(
        x_c2,
        y_c2,
        label: [BCH code 2],
        mark: "+",
        stroke: (thickness: 1pt),
      ),

      title: [
        Throughput versus $E_S"/"N_0$ for distinct codes with #mod modulation
      ],

      yscale: "log",
      ylabel: [Throughput],
      xlabel: [$E_S"/"N_0 ("dB")$],
      xaxis: (subticks: none),
      legend: (position: right + bottom),
    )
  })
}

#let extra-throughput-all(ch) = {
  let (x_none_bp, y_none_bp) = load-eq-extra2-2(0, "2PSK", ch)
  let (x_c1_bp, y_c1_bp) = load-eq-extra2-2(1, "2PSK", ch)
  let (x_c2_bp, y_c2_bp) = load-eq-extra2-2(2, "2PSK", ch)
  let (x_none_8q, y_none_8q) = load-eq-extra2-2(0, "8QAM", ch)
  let (x_c1_8q, y_c1_8q) = load-eq-extra2-2(1, "8QAM", ch)
  let (x_c2_8q, y_c2_8q) = load-eq-extra2-2(2, "8QAM", ch)
  let (x_none_16q, y_none_16q) = load-eq-extra2-2(0, "16QAM", ch)
  let (x_c1_16q, y_c1_16q) = load-eq-extra2-2(1, "16QAM", ch)
  let (x_c2_16q, y_c2_16q) = load-eq-extra2-2(2, "16QAM", ch)

  figure({
    show: lq.set-grid(
      stroke-sub: 0.5pt + luma(80%),
    )

    lq.diagram(
      width: 16cm,
      height: 6.5cm,

      lq.plot(
        x_none_bp,
        y_none_bp,
        label: [BPSK],
        mark: "x",
        stroke: (thickness: 1pt),
      ),

      lq.plot(
        x_c1_bp,
        y_c1_bp,
        label: [BPSK + BCH1],
        mark: "o",
        stroke: (thickness: 1pt),
      ),

      lq.plot(
        x_c2_bp,
        y_c2_bp,
        label: [BPSK + BCH2],
        mark: "+",
        stroke: (thickness: 1pt),
      ),

      lq.plot(
        x_none_8q,
        y_none_8q,
        label: [8QAM],
        mark: "d",
        stroke: (thickness: 1pt),
      ),

      lq.plot(
        x_c1_8q,
        y_c1_8q,
        label: [8QAM + BCH1],
        mark: "v",
        stroke: (thickness: 1pt),
      ),

      lq.plot(
        x_c2_8q,
        y_c2_8q,
        label: [8QAM + BCH2],
        mark: "<",
        stroke: (thickness: 1pt),
      ),

      lq.plot(
        x_none_16q,
        y_none_16q,
        label: [16QAM],
        mark: ">",
        stroke: (thickness: 1pt),
      ),

      lq.plot(
        x_c1_16q,
        y_c1_16q,
        label: [16QAM + BCH1],
        mark: "s5",
        stroke: (thickness: 1pt),
      ),

      lq.plot(
        x_c2_16q,
        y_c2_16q,
        label: [16QAM + BCH2],
        mark: "a5",
        stroke: (thickness: 1pt),
      ),

      title: [
        Throughput versus $E_S"/"N_0$ for distinct code and modulation pairs.
      ],

      //yscale: "log",
      ylabel: [Throughput],
      xlabel: [$E_S"/"N_0 ("dB")$],
      xaxis: (subticks: none),
      legend: (position: left + top),
    )
  })
}


= Simulation of system with ideal hardware (D1)

== System Model

#figure(
  image("images/d1/transmission_chain.png", height: 90%),
  caption: [Point-to-point communication chain],
)
== Simulation Methodology

- *$E_b = 1$ (normalized)*
  - $N^((0))_0 = (1/10)^(("SNR"_b)/10)$
  - Shows impact of *modulation* energy distribution in the SNR
    - $"SNR"_b = "SNR"_S - 10 dot log_10(log_2(M))$
  - Shows impact of energy distribution in *non information* bits for BCH codes

    - $E_b = bold(1) / r -> N_0 = N^((0))_0 / r$
  - Allows for a *head-to-head comparison* of modulation and correction codes combinations *with the same energy performance*

- *Monte Carlo simulation* with *stop conditions*
  - *Max number of iterations*
  - *Minimum number of detected errors*
    - Allows us to *stop early* for *low SNRs*

- If a simulation didn't give any errors for a given SNR, the simulation *stops early*
  - The BER is a *monotonic curve*, no need to continue simulating *if the errors are too low*

== Code Correction Methodology
- $"GF"(32)$
- $g(x) = "LCM"(mu_(alpha^1)(x), ..., mu_(alpha^(2t))(x) )$
  - $t = 1$: ${alpha^1, alpha^2}$
  - $t = 2$: ${alpha^1, alpha^2, alpha^3, alpha^4}$

#figure(
  caption: [Generator polynomials and code rates of the studied BCH codes.],
  table(
    columns: (1fr, 2fr, 1fr),
    inset: 12pt,
    align: center,
    stroke: 0.6pt,

    table.header([$"Error Capability"$], [$g(x)$], [$R$]),

    table.hline(),

    [$t = 1$],
    [$x^5 + x^2 + 1$],
    [$26"/"31$],

    table.hline(),

    [$t = 2$],
    [$x^(10) + x^9 + x^8 + x^6 + x^5 + x^3 + 1$],
    [$21"/"31$],

    table.hline(),
  ),
)

== Code Correction

#figure(
  lq.diagram(
    width: 16cm,
    height: 6.5cm,
    lq.plot(bpsk_0_x_f, bpsk_0_y_f, label: [BPSK - not coded], mark: "x", stroke: (thickness: 1pt, dash: "solid")),
    lq.plot(bpsk_1_x_f, bpsk_1_y_f, label: [BPSK - BCH code $t=1$], mark: "o", stroke: (thickness: 1pt, dash: "solid")),
    lq.plot(bpsk_2_x_f, bpsk_2_y_f, label: [BPSK - BCH code $t=2$], mark: "+", stroke: (thickness: 1pt, dash: "solid")),
    title: [BER versus $E_b"/"N_0$ for distinct coding schemes with *BPSK* modulation (channel *0*).],
    yscale: "log",
    ylabel: [BER],
    xlabel: [$E_b"/"N_0 ("dB")$],
    xaxis: (subticks: none),
    legend: (position: right + top),
  ),
)

== Multipath Channels

#align(
  center,
  grid(
    columns: 3,
    gutter: 0.5cm,
    create_resp_channel_fig(1), create_resp_channel_fig(2), create_resp_channel_fig(3),
  ),
)

#create-ber-figure("PSK2", 2)


== Code Correction in Multipath Channels
#extra-code-channel(3, "none")
#extra-code-channel(3, "DFE")
== Throughput

#extra-throughput-all(0)
