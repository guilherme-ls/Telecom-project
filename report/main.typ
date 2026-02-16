#import "template.typ": project

#import "@preview/equate:0.3.2": equate
#show: equate.with(breakable: true, sub-numbering: true)
#set math.equation(numbering: "(1.1)")

#set par(
  justify: true,
  leading: 0.52em,
)

#show: project.with(
  title: "Simulation of system with ideal hardware",
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
  footer-text: "Télécom Paris",
)


= Introduction

  In this report, we model the transmit and receive nodes of a transmission chain, implementing the coding of its information, its transmission through a channel, and its subsequent decoding. @chanel shows the modelled chain.

  #figure(
    image("./assets/transmission_chain.png", width: 80%),
    caption: [Transmitter and receiver chain.],
  ) <chanel>

  The channel coding will be done through two distinct BCH codes, correcting $t=1$ and $t=2$ errors respectively. Each implemented code will have a length of $N_c = 31$ and be defined considering the Galois Field extension $"GF"(32)= "GF"(2)[x]"/"1+x^2+x^5$. Both codes will adopt the systematic form to facilitate decoding 

  In terms of the transmission channel, we consider that the transmitted symbols $s(n)$ will be linearly modulated according @eq:input_filter, where $g(n)$ is the shaping filter satisfying the square-root Nyquist condition and $T_s$ is the symbol period.

  $ x(t) = sum_n s(n) g(t-n T_s) $ <eq:input_filter>

  On the reception side, after sampling the received signal at $1"/"T_s$ intervals and performing some mathematical simplifications, it can be described by @eq:received_signal, where *H* is a Toeplitz matrix representing the frequency selective channel and *w* is the Gaussian noise.
  
  $ bold("z") = bold("H s") + bold("w") $ <eq:received_signal>

  Based on the described system, we perform in this report a simulation and evaluation of its performance considering different codes, channels and modulations, discussing the employed methods and the obtained results.

= Practical Implementation

