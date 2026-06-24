#import "@preview/diatypst:0.9.1": *

#show: slides.with(
  title: "Performance Analysis of a realistic Cloud Radio Access Network (C-RAN)",
  subtitle: "Deliverables D1, D2, D3 and D4",
  date: "2025-2026",
  authors: (
    "LOUROSA RECH Bernardo",
    "LORETE SCHMIDT Guilherme",
    "PANCHENIAK FILHO Ivan Roberto Wagner",
  ),
  ratio: 16 / 9,
  count: "dot-section",
  layout: "medium",
  title-color: blue.darken(60%),
  toc: false,
)

= Complete Communication Chain Model

#figure(
  image("./images/c-ran-model.png", height: 90%),
  caption: [Model of the whole C-RAN chain.],
)

#include "./section/d1.typ"

#include "./section/d2.typ"

#include "./section/d3.typ"

#include "./section/d4.typ"

#pagebreak()
#page(header: none, footer: none)[
  #align(center + horizon)[
    #text(size: 30pt, weight: "bold", fill: blue.darken(60%))[Thank you for your attention]
  ]
]
