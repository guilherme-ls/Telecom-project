#import "template.typ": project

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
  title: "Optical point-to-point system performance",
  subtitle: "Performance Analysis of a realistic
Cloud Radio Access Network (C-RAN)",
  authors: (
    "LOUROSA RECH Bernardo",
    "LORETE SCHMIDT Guilherme",
    "PANCHENIAK FILHO Ivan Roberto Wagner",
  ),
  school-logo: image("./assets/logo_telecom_ipparis.png", width: 8cm, height: 4.0cm),
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

In this report, we develop a fiber-link simulator for the communication between servers and a basestation. Given this context, we start by modelling a standard singlemode fiber (SSF), considering the loss and chromatic dispersion it introduces in the signals that propagate through it. Therefore, we start by defining the transfer function of the fiber, given by equation @eq:transfer.

$
  H_"CD" (Delta omega)
  = exp(-alpha L -i ((beta_2 Delta omega^2)/2 + (beta_3 Delta omega^3)/6) L)
$ <eq:transfer>

In this equation, $alpha$ is the attenuation constant, $beta_2$ and $beta_3$ are the second and third order terms of the Taylor expansion of the propagation constant of the fiber around $Delta omega$ (@eq:b_exp), $Delta omega$ is the frequency offset (@eq:omega) and $L$ is the fiber length.

$
  beta(omega) = beta_0 + beta_1 Delta omega + beta_2 / 2 Delta omega^2 + beta_3 / 6 Delta omega^3 + ...
$ <eq:b_exp>

$
  Delta omega = omega - omega_0 = 2 pi Delta f
$ <eq:omega>

And $beta_2$ and $beta_3$ are given by @eq:b2 and @eq:b3, respectively.

$
  beta_2 = - (D_lambda lambda^2)/(2 pi c)
$ <eq:b2>

$
  beta_3 = (S lambda^4)/(4 pi^2 c^2)
$ <eq:b3>

Now, $lambda$ is the wavelength, $c$ is the speed of light, $D$ is the dispersion at a given wavelength and $S$ is the dispersion slope. The dispersion $D$ can be calculated by @eq:D.

$
  D_(lambda) = D_(lambda_0) + S(lambda - lambda_0)
$ <eq:D>

Implementing the fiber simulation through this set of equations, we proceed to study the system performance simulating the section marked in red in the transmission chain in @fig:chain. We perform tests considering external modulation and direct modulation, using different data rates, distinct fiber lengths, and varying the polarization current of the laser.

#figure(
  image("./assets/chain.png", width: 95%),
  caption: [Complete optical transmission chain.],
) <fig:chain>

We then finalize our analysis by suggesting different solutions to transmit at $10$ Gbit/s over $100$ km with an uncorrected BER lower than $10^(-3)$.


= System Implementation

== Simulation of linear propagation in a lossy and dispersive fiber

We start by implementing the equations detailed in the previous section. Considering values for a standard singlemode fiber (described in the ITU G.652 specification) in the reference wavelength $lambda_0 = 1550 "nm"$ , we have that $alpha = 0.2 "dB/km"$, $D_(lambda_0) = 17 "ps/nm/km"$ and $S = 0.056 " ps/nm"^2"/km"$.

Effectively, according to our laboratory measurements, the laser emits at the wavelength $lambda = 1554 "nm"$, which lets us determine $D_lambda$, $beta_2$ and $beta_3$ using the equations in the introduction. This is implemented in the simulation code.

This is sufficient to simulate the optical fiber behavior. However, we seek to compare the simulation results with an analytical solution of the pulse spread $Delta tau$ (through @eq:disp_ana), to validate the code.

$
  Delta tau = L D Delta lambda
$ <eq:disp_ana>

To determine the spectral occupation $Delta lambda$, we must first define which pulse to emit with the laser. In this section, we consider a Gaussian pulse of full width half maximum (FWHM) $T$ in the time domain. Then, calculating its FWHM in the frequency domain, it is found to be $Delta f = 0.44 / T_0$. The FWHM is measured from the intensity profiles.

Using this result, the spectral occupation can be calculated as $Delta lambda = (Delta f lambda^2) / c$. Letting us determine the expected pulse spread.

Continuing with the description of the code, we implemented a function that generates a vector of samples of a Gaussian with its intensity FWHM as a chosen $T_0$, also calculating a sampling frequency that leads to minimal amount of aliasing. This Gaussian vector is then passed to the fiber simulation function, which performs an FFT to get its baseband frequency domain representation.

Then, it calculates the transfer function (described in @eq:transfer) value at every frequency bin of the resulting vector, considering that the Gaussian is centered at $lambda = 1554 "nm"$. Lastly, it multiplies the frequency domain Gaussian by the transfer function, performing the IFFT and obtaining the output pulse, which can then be measured to determine the pulse spread.

Thus, we test the code first considering a Gaussian pulse of width $2 "ps"$ transmitted over a fiber of $1 "km"$, with the same physical properties as detailed in the beginning of the section. @fig:fiber_2ps shows the input and output pulses, where we can clearly notice the effects of chromatic dispersion.

#figure(
  image("./assets/Fiber_2ps.png", width: 95%),
  caption: [Gaussian pulse intensity as a function of time at the input of the fiber and at its output. Considers a pulse of width $T_0 = 2 "ps"$.],
) <fig:fiber_2ps>

Comparing the pulse spreads, we get that the expected spread determined analytically is $Delta tau_a = 30.5 "ps"$, while the one measured in the simulation is $Delta tau_s = 30.65 "ps"$. The difference is less than $1\%$, showing that the simulated fiber performs as predicted in theory.

Testing again with a pulse width of $5 "ps"$, the resulting pulses can be seen in @fig:fiber_5ps. Comparing the spreads, we expected from theory $Delta tau_a = 12.2 "ps"$ and got $Delta tau_s = 13.2 "ps"$. This increase can be explained by the influence of the input pulse's own width, which is not negligible compared to the spread in this case.

#figure(
  image("./assets/Fiber_5ps.png", width: 95%),
  caption: [Gaussian pulse intensity as a function of time at the input of the fiber and at its output. Considers a pulse of width $T_0 = 5 "ps"$.],
) <fig:fiber_5ps>

Therefore, we can conclude that the fiber simulation is properly implemented and proceed with the system simulation.

As a final addendum, @fig:phase shows the phase and magnitude of the transfer function simulating the optical fiber's behavior. Observe that the phase quickly increases as $Delta omega$ increases, while the magnitude is constant.

#figure(
  image("./assets/phase.png", width: 95%),
  caption: [Transfer function of the optical fiber.],
) <fig:phase>

== Back-to-back performance with external modulation

Now, we proceed with the testing of the back to back performance of the system, considering an externally modulated laser transmitting directly into a photodiode. In this setup, the transmission link does not employ optical fiber, such that the signal experiences neither optical attenuation nor chromatic dispersion (and consequently, no Inter-Symbol Interference). The emitter uses a Non Return to Zero (NRZ) On Off Keying (OOK) modulation scheme.

The simulations will be performed considering datarates of $R_b = 2.5 "Gb/s"$ and $R_b = 10 "Gb/s"$. The aim is to determine the minimum necessary optical power $P_"min"$ to achieve a BER of $10^(-3)$ and $10^(-6)$ in each case.

=== Analytical Considerations

Under this project's conditions, the Bit Error Rate (BER) is directly related to the noise added at the receiver. For a PIN photodiode without optical pre-amplification operating at low received optical powers, as is the case here, the dominant noise source is the thermal noise of the receiver photodiode.

Therefore, the thermal noise added by the photodiode has variance $sigma_"th"^2$, given by @eq:thermal_noise.

$
  sigma_"th"^2 = (N_"th" dot B_e) / R_"load"
$ <eq:thermal_noise>

In this equation, $N_"th" = 4 k_B T$ is the thermal noise power spectral density, $B_e$ is the electrical bandwidth of the receiver filter, and $R_"load"$ is the load resistance. To limit the thermal noise, $B_e$ is set equal to the bit rate $R_b$ in each simulation. The temperature is considered $T = 290 "K"$ and the load resistance is $R_"load" = 50 space Omega$.

Continuing the analysis, the binary error rate can be calculated through @eq:ber, where the factor Q can be determined from @eq:Q_factor. Observe that $I_1$ is the photocurrent and $sigma_1$ is the noise standard deviation when a bit 1 is transmitted, while $I_0$ and $sigma_0$ correspond to a bit 0.

$
  "BER" = 1/2 text("erfc")(Q / sqrt(2))
$ <eq:ber>

$
  Q = (I_1 - I_0) / (sigma_1 + sigma_0)
$ <eq:Q_factor>

Since we employ OOK modulation, we may consider $I_1 = S P_"peak"$ and $I_0 = 0$, where $S = 1 "A/W"$ is the photodiode's sensitivity and $P_"peak"$ is the peak optical power. Similarly, we consider that the thermal noise acts symmetrically on both bits, such that $sigma_0 = sigma_1 = sigma_"th"$.

Since we search the minimum optical power necessary to achieve a certain BER, we rewrite everything as @eq:optical_power.

$ P_"peak" = (2 Q) / S sqrt((4 k_B T B_e) / R_"load") $ <eq:optical_power>

Now, we proceed to analytically find the necessary powers. From @eq:ber we determine that the necessary Q factor to achieve a $10^(-3)$ error rate is $Q approx 3.09$, while to achieve a $10^(-6)$ error rate we need $Q approx 4.75$.

Then, solving @eq:optical_power for both datarates and BERs, we get @tab:power_solve.

#figure(
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
) <tab:power_solve>

=== Simulation

Having determined the expected values from theory, we now implement the simulation that will calculate the BER for a series of power levels, permitting us to determine the necessary power for the desired BERs.

The simulation is conducted by generating a random vector of bits, inputting it into the `TX_optical_eml` to generate the modulated OOK optical signal, and upsampling the signal such that it better approximates a continuous signal. Then, we convolve the result with a rectangle function with the same size as the upsampling factor (guaranteeing NRZ), representing the pulses sent when the bit is 1. At last, this transmitted signal passes onto the `RX_photodetector` function, generating an electrical signal vector, which is sampled to determine the received bits.

At last, the sent and received bits are compared, and the errors measured. A loop repeats the process until the BER measure is sufficiently precise, and for each desired power level. The respective code is in the `extern_mod_main` file.

The graph of BER per Power generated by the algorithm is shown in @fig:BER_power. Observe that the datarates of $R_b = 2.5 "Gb/s"$, in blue, and $R_b = 10 "Gb/s"$, in orange, differ in $3 "dB"$ because of the different electrical bandwidths used at the photodiode.

#figure(
  image("./assets/BER_power2.png", width: 95%),
  caption: [BER as a function of the laser power in dBm, considering datarates of $R_b = 2.5 "Gb/s"$, in blue, and $R_b = 10 "Gb/s"$, in orange.],
) <fig:BER_power>

Analyzing the simulation results, they agree almost exactly with the expected analytical values.

Thus, we may conclude that the optical system was accurately implemented in the code.

== Transmission performance with external modulation

In this section, we fix a certain power level for the laser and vary the length of optical fiber between the transmitter and the receiver, seeking to evaluate the impact of chromatic dispersion on the BER. We employ the same two datarates as before ($2.5 "Gb/s"$ and $10 "Gb/s"$).

A general upper limit to the chromatic dispersion, before it significantly affects the signal, is defined as $Delta tau << T/4$, where $T$ is the symbol period. Therefore, we can use @eq:disp_ana to find a theoretical maximum length $L_"max"$ for the fiber before chromatic dispersion leads to an increase in BER. This limit is shown in @eq:length_max.

$
  L_"max" = c / (2 D lambda^2 Delta f^2)
$ <eq:length_max>

Therefore, considering that a rectangle pulse has a spectral occupation $Delta f = 2/T$, and substituting the known values in the above equation, we may calculate $L_"max"$ for both datarates. Thus, for $10 "Gbps"$ we expect $L_"max" = 9 "km"$, while for $2.5 "Gbps"$ we expect $L_"max" = 146 "km"$, 16 times higher.

However, Optical Networks: A Practical Perspective by Ramaswami, Sivarajan and Sasaki propose an empirical limit given by $R_b^2 L < 3607 space "Gbps"^2"km"$, considering a $2 "dB"$ power penalty with respect to the BER in an externally modulated NRZ OOK laser. This gives $L_"max" approx 36 "km"$ for 10 Gbps or $L_"max" approx 577 "km"$ for 2.5 Gbps. The calculation method is effectively the same, but considering that spectral occupation is the same as the datarate and that the upper limit for $Delta tau$ is $approx T/2$ instead of $T/4$ for the 2 dB penalty.

Finally, we can proceed with the simulations. The laser power is fixed at -21 dBm for the 2.5 Gbps datarate and -17 dBm for the 10 Gbps datarate. The fiber attenuation is set to 0, such that the laser power is conserved for all distances and does not influence the results.

In this context, the optical chain is simulated for fiber lengths between 0 and 100 km, calculating the BER at each. The results are shown in @fig:BER_length.

#figure(
  image("./assets/BER_length2.png", width: 95%),
  caption: [BER as a function of the fiber optic length in km, considering datarates of $R_b = 2.5 "Gb/s"$, in orange, and $R_b = 10 "Gb/s"$, in blue.],
) <fig:BER_length>

From the graph, we observe that the fiber length (within the 100 km bound) does not influence the 2.5 Gbps in any way, agreeing with the theoretical $L_"max"$ we previously calculated. However, for the 10 Gbps datarate, we observe that the BER pronouncedly starts to increase at 30 km, spiking upwards a few kilometers after.

This shows us that the assumptions that led us to define $L_"max" = 9 "km"$ for the 10 Gbps case were too conservative, but still within the right magnitude since we truly observe a spike in BER within the observation window. This discrepancy can be attributed to, among other factors, the shaping filter we applied on the square pulse for this simulation (motivated by the terrible properties we observed when submitting the square pulse to chromatic dispersion in our tests).

Adopting the 2 dB penalty definition, $L_"max" approx 80 "km"$ in our simulations. Even if distinct from the theory, our results mostly agree with the commonly adopted max range of the ITU G.652 fiber without dispersion compensation.

== Performance with direct modulation

As the last simulation, we employ a directly modulated laser (DML) with an OOK signal of 1 Gbps, on a back to back configuration and using a 20 km fiber. The objective is to study how different bias currents $I_"DC"$ impact on the modulation and, consequently, on the system performance.

To achieve this end, we simulate the transmission of random symbols using this configuration and generate an eye diagram with the output signal, letting us see how the bias current affects the signal modulation. Thus, the simulation consists of generating a vector of currents based on the symbols we wish to send, using the `TX_optical_dml` function then generate the optical signal, passing it through the fiber, and then detecting it with the `RX_photodetector`, generating the eye diagram at last.

As a practical note, the threshold current in the laser employed is $approx 7 "mA"$. Therefore, we will use 4 currents in the analyses that cover a range from bellow the threshold to many times above it: 5 mA, 15 mA, 40 mA and 90 mA. The modulation current used is $I_"mod" = 30 "mA"$.

Bellow we present the simulation results. @fig:eye_0_bef presents the eye diagram generated directly by the optical signal before entering the photodiode, letting us see its unfiltered version.

#figure(
  box(width: 70%)[
    #grid(
      columns: (1fr, 1fr),
      gutter: 0pt,
      image("./assets/eye/eye_5_0_bef.png", width: 100%), image("./assets/eye/eye_15_0_bef.png", width: 100%),
      image("./assets/eye/eye_40_0_bef.png", width: 100%), image("./assets/eye/eye_90_0_bef.png", width: 100%),
    )
  ],
  // Add your caption text directly inside the figure container
  caption: [Simulated 1 Gbps DML eye diagrams under various DC bias currents on a back to back configuration. Before detection by photodiode.],
) <fig:eye_0_bef>

First, we can observe that each signal exhibits relaxation oscillations, characterized by the rapid variations after a rising edge before reaching a steady state. We observe that the oscillations are much smaller (dampened) when the bias current increases, as supported by the theory.

Then, observing the $I_"DC" = 5 "mA"$, below the threshold current, its rising edge varies a lot in time and the signal has a significant amount of jitter. This effect may be explained by the fact that since the bias current is bellow threshold, it needs to first increase the carrier density before it starts to lase. This would generate a variable turn on delay for the DML.

We proceed to observe @fig:eye_20_bef, which also shows the eye diagram generated directly by the optical signal before entering the photodiode, but considering that the signal travelled through 20 km of optical fiber (now with attenuation).

#figure(
  box(width: 70%)[
    #grid(
      columns: (1fr, 1fr),
      gutter: 0pt,
      image("./assets/eye/eye_5_20_bef.png", width: 100%), image("./assets/eye/eye_15_20_bef.png", width: 100%),
      image("./assets/eye/eye_40_20_bef.png", width: 100%), image("./assets/eye/eye_90_20_bef.png", width: 100%),
    )
  ],
  // Add your caption text directly inside the figure container
  caption: [Simulated 1 Gbps DML eye diagrams under various DC bias currents with 20 km of fiber. Before detection by photodiode.],
) <fig:eye_20_bef>

The most interesting point to observe in this figure is the effect that chromatic dispersion has on the rising and falling edges. As the transient chirp occurring in these edges increase their spectral width, they become heavily affected by chromatic dispersion, with each frequency suffering different delays. This generates the great oscillating patterns we now observe at each edge. Since the effect is compounded by the relaxation oscillations, higher bias currents suffer less aggressive distortions.

We now proceed to observe the eye diagram from the signal coming from the photodiode output, after the electrical filter it applies, and what is used in practice. @fig:eye_0_aft shows the signal from the back to back configuration.

At first, we notice that all signals look much clearer without the high frequency components. However, we can still observe that the signal with bias current below threshold suffers from jitter, as seem by the variation in its rising and falling edges.

On the other hand, all the other currents generate similar signals, differentiated only small increases in the aperture of the eye as the bias current increases. However, this comes at the cost of a big increase in average power.

#figure(
  box(width: 70%)[
    #grid(
      columns: (1fr, 1fr),
      gutter: 0pt,
      image("./assets/eye/eye_5_0_aft.png", width: 100%), image("./assets/eye/eye_15_0_aft.png", width: 100%),
      image("./assets/eye/eye_40_0_aft.png", width: 100%), image("./assets/eye/eye_90_0_aft.png", width: 100%),
    )
  ],
  // Add your caption text directly inside the figure container
  caption: [Simulated 1 Gbps DML eye diagrams under various DC bias currents on a back to back configuration. After detection by photodiode.],
) <fig:eye_0_aft>

Proceeding with @fig:eye_20_aft, it shows the signal that passed through 20 km of fiber is attenuated but mostly unchanged in its shape. The only notable change is the degradation of the first low current signal, which had its jitter increased and its eye close further.

#figure(
  box(width: 70%)[
    #grid(
      columns: (1fr, 1fr),
      gutter: 0pt,
      image("./assets/eye/eye_5_20_aft.png", width: 100%), image("./assets/eye/eye_15_20_aft.png", width: 100%),
      image("./assets/eye/eye_40_20_aft.png", width: 100%), image("./assets/eye/eye_90_20_aft.png", width: 100%),
    )
  ],
  // Add your caption text directly inside the figure container
  caption: [Simulated 1 Gbps DML eye diagrams under various DC bias currents with 20 km of fiber. After detection by photodiode.],
) <fig:eye_20_aft>

Therefore, we may conclude that a bias current below threshold is highly inadvisable, and that a bias current of 15 mA performs excellently for only a fraction of the power of the following signals.

== Solutions for higher data rates and reach

=== Higher Data Rates

Until now, the studied system used a simple OOK modulation to transmit the data. While this is a solid
modulation schema, producing a good BER for the range of SNR studied, it doesn't allow for a high data rate,
unless we change other parameters like the symbol period.

With that in mind, a better modulation type can be used. Ideally, modulations that can use phase an amplitude would be
best, like a PSK or a QAM. But, coherent modulation at great distances isn't easy neither cheap, requiring both a
external modulator to modulate phase, and a complex demodulator.

Nevertheless, we can still modulate the amplitude to increase our throughput, without requiring hardware that much more complex.
For example, instead of using $I_"laser" = I_"DC"$ for the bit '1' and $I_"laser" = 0$ for the bit '0', we could
divide the range to package multiple bits in symbols, like $I_"laser" = I_"DC"$ for the symbol '11', $I_"laser" = 0.66 I_"DC"$ for the symbol '10',
$I_"laser" = 0.3 I_"DC"$ for the symbol '01', and finally $I_"laser" = 0$ for '00'.

By doing this, we can increase the data rate, while only requiring a more complex symbol coding and decoding schema.

=== Longer Reach

As we have seen in the studied systems, as the length of our fiber increases, we end up having a worse reception in the
receiver end, be it because of symbol being lost by attenuation, or by chromatic dispersion, causing Inter-Symbol Interference (ISI).

To mitigate the first case (attenuation), a simple combo of an amplifier following some length of fiber can make sure that the receiver will
receive the photon pulses inside an expected attenuation level.

Meanwhile, to fix chromatic dispersion, there are a multitude of ways. The first, and most "unrealistic" one, is to use "zero dispersion" fibers.
While they do "exist", they present other problems that make their use impractical, but they would eliminate the dispersion.

The second way would be to numerically revert the effects of the dispersion, but that adds some overhead to the receiver.

The third way is by using negative dispersion fibers to compensate the dispersion caused by the "main" transmission fiber. By adding a certain length of DCF fiber to the end o the "main" one, it effectively reverses the chromatic dispersion and eliminates the inter symbol interference. This way,
from the point of view of the receiver, the pulse doesn't have any major dispersion, not requiring this additional overhead from the previous solution.
But, these types of fibers may not integrate well into the system in place, and attention needs to be taken to make sure there is good coupling when going from the "main" fiber to the "compensation" one.

As an example, we implemented the simulation `extern_mod_main_compensation` that sends a 10 Gbps NRZ OOK signal using an EML with -18 dBm of power through 100 km of ITU G.652 fiber, followed by 17 km of DCF with $D = -100 "ps/nm/km"$. The resulting BER is $2.8 times 10^(-6)$, showing that the concept indeed works in simulation.

== Extra credit - Study the dependence of $L_"max"$ in $R_b$

In this section, we study the dependency of $L_"max"$ on the datarate both from an analytical point of view, through @eq:length_max, and an experimental one, through Monte-Carlo simulations. Starting by the analytical analysis, we know that the spectral occupation term $Delta f$ is proportional to the datarate, such that any increase in the datarate decreases $L_"max"$ quadratically. In this case, we adopted the convention $Delta f = 2 R_b$ for square pulses.

Now, in the experimental aspect, we defined $L_"max"$ as the distance at which the BER becomes $10^(-3)$ in the transmission. For each datarate we calculated the power necessary to achieve a $10^(-6)$ BER in a back-to-back configuration (using @eq:optical_power) and adopted it as the laser power. Thus $L_"max"$ corresponds to a drop of $10^3$ in the BER.

#figure(
  image("./assets/extra1-datarates.png", width: 95%),
  caption: [$L_"max"$ as a function of the datarate in Gbit/s, considering both the theoretical value, in orange, and the value obtained through Monte-Carlo simulations, in blue.],
) <fig:extra1-datarates>

Both an analytical and experimental curve presenting $L_"max"$ as a function of the datarate are shown in @fig:extra1-datarates. Analyzing it, we observe that both curves have the same general shape, verifying the quadratic inverse relation between $L"max"$ and $R_b$ in the two cases. Additionally, we notice a vertical offset between the two curves (equivalent to a multiplicative factor in linear scale), with the analytical curve being much lower, suggesting that the theoretical value calculated earlier is too conservative when compared to what is seen in practice.

== Extra credit - Study the performance of digital equalization and error correction

We start by implementing in this optical transmission chain the coding schemes developed in D1, studying their performance. The characteristics of the BCH codes implemented here can be found in @tab:code_information.

#figure(
  caption: [Generator polynomials and code rates of the studied BCH codes.],
  table(
    columns: (1fr, 2fr, 1fr),
    inset: 9pt,
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
) <tab:code_information>

Therefore, after generating a random vector of information bits, we now encode the information using the chosen BCH code before upsampling the symbols vector and convolving it with the square pulse to send it in the fiber. Similarly, at reception, right after obtaining the output symbols from the threshold detector applied in the electrical signal, we perform the decoding and compare the result with the original random vector to measure the BER. The coding and decoding functions used were taken directly from D1.

Importantly, the laser power used in these experiments were normalized to take into account the code rate of the codes used, such that the coded case does not have an unfair advantage in terms of energy. Therefore, the simulation results can be found in @fig:extra2-codes, where uncoded (code 0) and coded performances are compared for a fiber length of $L = 100 "km"$, which presents a considerable level of ISI
to be later discussed.

As in D1, we notice that for low laser powers (and thus low SNR) the codes introduce a loss in performance, since the loss in bit energy leads to an increase in BER and the number of errors is still well beyond the error correcting capacity of the code. However, for higher laser power, the coded cases present an improved performance with respect to the uncoded case, and BCH code 2 (with a higher error correcting capacity) eventually takes the lead.

#figure(
  image("./assets/extra2-codes.png", width: 95%),
  caption: [BER as a function of the laser power, considering a non-coded case, and two coded cases, with distinct BCH codes.],
) <fig:extra2-codes>

Then, we extended the analysis by proposing a digital equalization scheme to be applied on signal outputted by the photodetector. To this end, we implemented coherent detection (extracting the two quadratures) to obtain the signal's phase information. This way, since the transfer function describing the dispersion in the fiber is already known, the equalization can be performed by reverting the phase shifts it introduces in the frequency domain.

Thus, our proposed digital equalizer takes the electric signal outputted by the coherent photodetector (in theory sampled by an ADC), applies an FFT, multiplies it by the transfer function of the fiber but with contrary phases (to revert the phase shift), and then performs an IFFT, finalizing by downsampling the signal to detect the symbols.

@fig:extra2-equalization shows the BER versus laser power considering the base case and the equalized case. Observe that the equalization indeed permits a considerable performance gain by reverting most of the inter-symbol-interference generated by the chromatic dispersion introduced by the fiber.

#figure(
  image("./assets/extra2-equalization.png", width: 95%),
  caption: [BER as a function of the laser power, considering a non-coded case with (in orange) and without (in blue) equalization.],
) <fig:extra2-equalization>

As a side note, we tried to determine the impulse response $h$ of the fiber empirically (by sending a single pulse through it and measuring the output) and using it to perform ZF and DFE in the direct detection case. However, the results were not satisfactory.

= Conclusion

Throughout this report, we analyzed different properties and behaviors that appear in optical communication systems.
In it, we studied the effects of chromatic dispersion, and created a fiber model that was later used to further study the
effects of it in both direct and external modulation communication schemas.

That resulted in us observing a greater BER degradation
in higher data rates, as that would decrease the pulse period, which in turn increased the effects of chromatic dispersion, allowing
for more Inter-Symbol Interference. In addition, we concluded that a bias current bellow threshold for a DML has catastrophic results for the signal integrity, while a current many times above it also has diminishing returns.

Furthermore, we later discussed ways to reduce the effects of chromatic dispersion, and then how to take advantage of this higher BERs by using modulations that are more complex than OOK, but that don't use phase like PSK and QAM, allowing for higher data rates without raw decrease of pulse period.

