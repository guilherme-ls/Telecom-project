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
  title: "Radio-frequency system and hardware modeling",
  subtitle: "Optical point-to-point system performance",
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

In this report, we develop a fiber-link simulator for the communication between servers and a basestation. In this context, we start by modelling a standard singlemode fiber (SSF), considering the loss and chromatic dispersion it introduces in the signals that propagate through it.

Given this context, we study the system performance simulating the whole transmission chain

#figure(
  image("./assets/chain.png", width: 95%),
  caption: [Complete optical transmission chain.]
) <fig:SNR_dist>

= Conclusion

Throughout this report we discussed in detail two parallel approaches to the study of RF communication systems. In the first part we modelled a full communication system through detailed matlab simulations representing all the individual blocks of a Homodyne TX and RX. This permitted a deep understanding of the underlying theory behind each components' behavior, and also gave an overview of how these components integrate and interact with each other. And all this information was used in choosing the parameters for each component of the chain that would guarantee the desired performance while still minimizing the total power consumed.

Second, we took a more physical approach, using the AD9363 RF transceiver circuit in the ADALM-PLUTO board to empirically implement a transmission chain, focusing both in the evaluation of how changing the gain and DAC scale parameters affected performance, and on how to synchronise and decode modulated symbols that were transmitted through real non-ideal channels. This gives more of an idea on how RF systems readily available in the market perform in practice and on how to use their many features.

Comparing the measurement results from both systems, we can see an equivalence in the fact that the simulation shows a decrease in output signal quality as the distance increases, while the ADALM-PLUTO board shows a decrease in signal quality as the TX gain or the scale factor decrease, which is in a certain way equivalent. We must also consider that the AD9363 was not working at its full capacity with the gain and scale used.

Therefore, each section of this project had a complementary purpose. However, we can still compare both systems. Compared to the simulation implementation, the AD9363 circuit is much more robust, promoting 12 bit ADCs and DACs, a sampling rate of up to $61.44 "MSPS"$, programmable gain, among other useful tools that permit a greater versatility.

We can specially highlight the Automatic Gain Control in the board, which permits an increase on the gain of the LNA and the baseband amplifier when the signal is too attenuated to reach the ADC full-scale. This was impossible in the simulation, and led to the fact that the maximum power signal would always limit the gain of the chain, making it impossible to sufficiently increase the power of the more attenuated signals.

To finalize the analysis, even if the simulation implemented many non-linearities of different components, it was still mostly idealized in terms of the transmission channel and the noise modelling. This is great when theoretically parametrizing the components of the chain to achieve the desired performance, but also fails to capture many difficulties that were only seen when using the pluto board. Thus, both approaches have its merits.

Besides the communication chain aspects discussed until now, many measuring sessions were conducted during the project, characterizing PAs and LNAs. This permitted an experimental view on how to determine gain, IIP3, IM3, ACPR, and noise figure from different components using tools such as a VNA and an SDR.

