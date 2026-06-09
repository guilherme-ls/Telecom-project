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
  caption: [Complete optical transmission chain.]
) <fig:chain>

We then finalize our analysis by suggesting different solutions to transmit at $10$ Gbit/s over $100$ km with an uncorrected BER lower than $10^(-3)$.


= System Implementation

== Simulation of linear propagation in a lossy and dispersive fiber

We start by implementing the equations detailed in the previous section. Considering values for a standard singlemode fiber (described in the G.652 specification) in the reference wavelength $lambda_0 = 1550 "nm"$ , we have that $alpha = 0.2 "dB/km"$, $D_(lambda_0) = 17 "ps/nm/km"$ and $S = 0.056 " ps/nm"^2"/km"$.

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
  image("./assets/fiber_2ps.png", width: 95%),
  caption: [Complete optical transmission chain.]
) <fig:fiber_2ps>

Comparing the pulse spreads, we get that the expected spread determined analytically is $Delta tau_a = 30.5 "ps"$, while the one measured in the simulation is $Delta tau_s = 30.65 "ps"$. The difference is less than $1\%$, showing that the simulated fiber performs as predicted in theory.

Testing again with a pulse width of $5 "ps"$, the resulting pulses can be seen in @fig:fiber_5ps. Comparing the spreads, we expected from theory $Delta tau_a = 12.2 "ps"$ and got $Delta tau_s = 13.2 "ps"$. This increase can be explained by the influence of the input pulse's own width, which is not negligible compared to the spread in this case.

#figure(
  image("./assets/fiber_5ps.png", width: 95%),
  caption: [Complete optical transmission chain.]
) <fig:fiber_5ps>

Therefore, we can conclude that the fiber simulation is properly implemented and proceed with the system simulation.

== Back-to-back performance with external modulation

== Transmission performance with external modulation

== Performance with direct modulation

== Solutions for higher datarates and reach

= Conclusion

Throughout this report we discussed in detail two parallel approaches to the study of RF communication systems. In the first part we modelled a full communication system through detailed matlab simulations representing all the individual blocks of a Homodyne TX and RX. This permitted a deep understanding of the underlying theory behind each components' behavior, and also gave an overview of how these components integrate and interact with each other. And all this information was used in choosing the parameters for each component of the chain that would guarantee the desired performance while still minimizing the total power consumed.

Second, we took a more physical approach, using the AD9363 RF transceiver circuit in the ADALM-PLUTO board to empirically implement a transmission chain, focusing both in the evaluation of how changing the gain and DAC scale parameters affected performance, and on how to synchronise and decode modulated symbols that were transmitted through real non-ideal channels. This gives more of an idea on how RF systems readily available in the market perform in practice and on how to use their many features.

Comparing the measurement results from both systems, we can see an equivalence in the fact that the simulation shows a decrease in output signal quality as the distance increases, while the ADALM-PLUTO board shows a decrease in signal quality as the TX gain or the scale factor decrease, which is in a certain way equivalent. We must also consider that the AD9363 was not working at its full capacity with the gain and scale used.

Therefore, each section of this project had a complementary purpose. However, we can still compare both systems. Compared to the simulation implementation, the AD9363 circuit is much more robust, promoting 12 bit ADCs and DACs, a sampling rate of up to $61.44 "MSPS"$, programmable gain, among other useful tools that permit a greater versatility.

We can specially highlight the Automatic Gain Control in the board, which permits an increase on the gain of the LNA and the baseband amplifier when the signal is too attenuated to reach the ADC full-scale. This was impossible in the simulation, and led to the fact that the maximum power signal would always limit the gain of the chain, making it impossible to sufficiently increase the power of the more attenuated signals.

To finalize the analysis, even if the simulation implemented many non-linearities of different components, it was still mostly idealized in terms of the transmission channel and the noise modelling. This is great when theoretically parametrizing the components of the chain to achieve the desired performance, but also fails to capture many difficulties that were only seen when using the pluto board. Thus, both approaches have its merits.

Besides the communication chain aspects discussed until now, many measuring sessions were conducted during the project, characterizing PAs and LNAs. This permitted an experimental view on how to determine gain, IIP3, IM3, ACPR, and noise figure from different components using tools such as a VNA and an SDR.

