#import "@preview/diatypst:0.9.1": *

= Optical point-to-point system performance (D3)

== Introduction

In this section, we develop a fiber-link simulator for the communication between the remote server and the basestation.

#figure(
  image("./images/d3/chain.png", width: 90%),
  caption: [Complete optical transmission chain.],
) <fig:chain>

The parts in gray were already modelled in D1, so we focus on the physical part of the transmission chain, highlighted in red.

== Fiber model

We model the single mode standard fiber (SSF) used in this model using the following transfer function:

$
  H_"CD" (Delta omega)
  = exp(-alpha L -i ((beta_2 Delta omega^2)/2 + (beta_3 Delta omega^3)/6) L)
$ <eq:transfer>

where $alpha$ is the attenuation constant, $beta_2$ and $beta_3$ are the second and third order terms of the Taylor expansion of the propagation constant of the fiber around $Delta omega$ (the frequency offset) and $L$ is the fiber length. 

$
  beta_2 = - (D_lambda lambda^2)/(2 pi c)
$ <eq:b2>

$
  beta_3 = (S lambda^4)/(4 pi^2 c^2)
$ <eq:b3>

The dispersion is given by

$
  D_(lambda) = D_(lambda_0) + S(lambda - lambda_0)
$ <eq:D>

== Simulation of propagation

We consider a lossy and dispersive fiber. Thus, we implement in code the previous transfer function using the standard parameters for a fiber operating at $lambda_0 = 1550 "nm"$ according to the ITU G.652 specification.

#figure(
  caption: [Fiber parameters.],
  table(
    columns: (auto, auto, auto),
    inset: 6pt,
    align: center,
    stroke: 0.6pt,

    table.header([$alpha$], [$D_(lambda_0)$], [$S$]),

    table.hline(),

    [$0.2 "db/km"$],
    [$17 "ps/nm/km"$],
    [$0.056 " ps/nm"^2"/km"$],
  ),
) <tab:power_solve>

Laboratory measures led us to determine that the laser operates at $lambda = 1554 "nm"$. Simulations can be performed multiplying the FFT of the signal by the transfer function and then taking the IFFT again. Pulse spread can be validated against analytical expression:

$
  Delta tau = L D Delta lambda
$ <eq:disp_ana>

For a gaussian pulse and considering the FWHM as $T$: $Delta f = 0.44 / T_0$.

And thus spectral occupation is $Delta lambda = (Delta f lambda^2) / c$.


#figure(
  image("./images/d3/Fiber_2ps.png", width: 62%),
  caption: [Gaussian pulse intensity as a function of time at the input of the fiber and at its output. Considers a pulse of width $T_0 = 2 "ps"$. Analytical $Delta tau_a = 30.5 "ps"$ and sim $Delta tau_s = 30.65 "ps"$.],
) <fig:fiber_2ps>

#figure(
  image("./images/d3/Fiber_5ps.png", width: 62%),
  caption: [Gaussian pulse intensity as a function of time at the input of the fiber and at its output. Considers a pulse of width $T_0 = 5 "ps"$. Analytical $Delta tau_a = 12.2 "ps"$ and sim $Delta tau_s = 13.2 "ps"$.],
) <fig:fiber_5ps>

== Back-to-back performance

Now, we proceed with the testing of the back to back performance of the system, considering an externally modulated laser. The emitter uses a Non Return to Zero (NRZ) On Off Keying (OOK) modulation scheme.

The aim is to determine the minimum necessary optical power $P_"min"$ to achieve a BER of $10^(-3)$ and $10^(-6)$ for the datarates $R_b = 2.5 "Gb/s"$ and $R_b = 10 "Gb/s"$.

Analytically, this power can be calculated as:

$ P_"peak" = (2 Q) / S sqrt((4 k_B T B_e) / R_"load") $ <eq:optical_power>

where Q is determined from the desired BER.

#align(horizon)[#figure(
  caption: [Minimum necessary power to achieve the desired BER at each datarate.],
  table(
    columns: (auto, auto, auto, auto),
    inset: 7pt,
    align: center,
    stroke: 0.6pt,

    table.header([$R_b space ("Gbps")$], [$"BER"$], [$P_"peak" (mu W)$], [$P_"peak" ("dBm")$]),

    table.hline(),

    [$2.5$],
    [$10^(-3)$],
    [$5.45$],
    [$-22.6$],

    table.hline(),

    [$2.5$],
    [$10^(-6)$],
    [$8.50$],
    [$-20.7$],

    table.hline(),

    [$10$],
    [$10^(-3)$],
    [$10.9$],
    [$-19.6$],

    table.hline(),

    [$10$],
    [$10^(-6)$],
    [$16.7$],
    [$-17.8$],

    table.hline(),
  ),
) <tab:power_solve>]

#pagebreak()

The simulation part follows these steps: 
- Generate a random vector of bits;
- Send it to the external modulator to generate the modulated OOK optical signal;
- Upsample the signal;
- Convolve the result with a rectangle function with the same size as the upsampling factor (NRZ);
- Pass the signal onto the photodetector function;
- Sample it to determine the received bits.

#figure(
  image("./images/d3/BER_power2.png", width: 70%),
  caption: [BER as a function of the laser power in dBm, considering datarates of $R_b = 2.5 "Gb/s"$, in blue, and $R_b = 10 "Gb/s"$, in orange.],
) <fig:BER_power>

== Performance with external modulation

For each datarate we fix the laser power to that which provide a $10^(-6)$ in back-to-back configuration. We also set the fiber attenuation to 0.

A general upper limit to the chromatic dispersion, is defined as:
$ Delta tau << T/4 $

We can thus find a theoretical max length through the following equation:

$
  L_"max" = c / (2 D lambda^2 Delta f^2)
$ <eq:length_max>

Considering that a rectangle pulse has a spectral occupation $Delta f = 2/T$, we get:
- For $2.5 "Gbps"$, $L_"max" = 146 "km"$;
- For $10 "Gbps"$, $L_"max" = 9 "km"$.

#figure(
  image("./images/d3/BER_length2.png", width: 70%),
  caption: [BER as a function of the fiber optic length in km, considering datarates of $R_b = 2.5 "Gb/s"$, in orange, and $R_b = 10 "Gb/s"$, in blue.],
) <fig:BER_length>

== Performance with direct modulation

We employ a directly modulated laser (DML) with an OOK signal of 1 Gbps, on a back to back configuration and using a 20 km fiber.

The threshold current in the laser employed is $approx 7 "mA"$. We will use 4 currents in the analyses that cover a range from bellow the threshold to many times above it: 5 mA, 15 mA, 40 mA and 90 mA.

We then make a sequence of eye diagrams.

#figure(
  box(width: 50%)[
  #grid(
    columns: (1fr, 1fr),
    gutter: 0pt,
    image("./images/d3/eye/eye_5_0_bef.png", width: 100%),
    image("./images/d3/eye/eye_15_0_bef.png", width: 100%),
    image("./images/d3/eye/eye_40_0_bef.png", width: 100%),
    image("./images/d3/eye/eye_90_0_bef.png", width: 100%),
  )
  ],
  caption: [Simulated 1 Gbps DML eye diagrams under various DC bias currents on a back to back configuration. Before detection by photodiode.],
) <fig:eye_0_bef>

#figure(
  box(width: 50%)[
  #grid(
    columns: (1fr, 1fr),
    gutter: 0pt,
    image("./images/d3/eye/eye_5_20_bef.png", width: 100%),
    image("./images/d3/eye/eye_15_20_bef.png", width: 100%),
    image("./images/d3/eye/eye_40_20_bef.png", width: 100%),
    image("./images/d3/eye/eye_90_20_bef.png", width: 100%),
  )
  ],
  caption: [Simulated 1 Gbps DML eye diagrams under various DC bias currents with 20 km of fiber. Before detection by photodiode.],
) <fig:eye_20_bef>

#figure(
  box(width: 50%)[
  #grid(
    columns: (1fr, 1fr),
    gutter: 0pt,
    image("./images/d3/eye/eye_5_0_aft.png", width: 100%),
    image("./images/d3/eye/eye_15_0_aft.png", width: 100%),
    image("./images/d3/eye/eye_40_0_aft.png", width: 100%),
    image("./images/d3/eye/eye_90_0_aft.png", width: 100%),
  )
  ],
  caption: [Simulated 1 Gbps DML eye diagrams under various DC bias currents on a back to back configuration. After detection by photodiode.],
) <fig:eye_0_aft>

#figure(
  box(width: 50%)[
    #grid(
      columns: (1fr, 1fr),
      gutter: 0pt,
      image("./images/d3/eye/eye_5_20_aft.png", width: 100%),
      image("./images/d3/eye/eye_15_20_aft.png", width: 100%),
      image("./images/d3/eye/eye_40_20_aft.png", width: 100%),
      image("./images/d3/eye/eye_90_20_aft.png", width: 100%),
    )
  ],
  caption: [Simulated 1 Gbps DML eye diagrams under various DC bias currents with 20 km of fiber. After detection by photodiode.],
) <fig:eye_20_aft>

== Dependence of $L_"max"$ in $R_b$

#figure(
  image("./images/d3/extra1-datarates.png", width: 60%),
  caption: [$L_"max"$ as a function of the datarate in Gbit/s, considering both the theoretical value, in orange, and the value obtained through Monte-Carlo simulations, in blue.],
) <fig:extra1-datarates>

== Digital equalization

#figure(
  image("./images/d3/extra2-equalization.png", width: 60%),
  caption: [$L_"max"$ as a function of the datarate in Gbit/s, considering both the theoretical value, in orange, and the value obtained through Monte-Carlo simulations, in blue.],
) <fig:extra2-equalization>
