#import "template.typ": project

#import "@preview/equate:0.3.2": equate
#show: equate.with(breakable: true, sub-numbering: true)
#set math.equation(numbering: "(1.1)")

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

  In this report, we model the transmit and receive nodes of a transmission chain, implemententing the coding of its information, its transmission through a channel, and its subsequent decoding. Figure @chanel shows the modelled chain.

  #figure(
    image("./assets/transmission_chain.png", width: 80%),
    caption: [Transmitter and receiver chain.],
  ) <chanel>

  The channel coding will be done through a two BCH code defined considering $"GF"(32)= "GF"(2)[x]"/"1+x^2+x^5$

= Theoretical Background



= Practical Implementation