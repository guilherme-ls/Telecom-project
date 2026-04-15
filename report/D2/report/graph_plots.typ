#import "@preview/lilaq:0.5.0" as lq

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

#let create-ser-ber-figure(file, cap, ax_x) = {
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

