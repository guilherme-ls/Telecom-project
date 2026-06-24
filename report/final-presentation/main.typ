#import "@preview/diatypst:0.9.1": *

#show: slides.with(
  title: "D4 Network simulation and global performance",
  date: "2025-2026",
  authors: (
  ),
  ratio: 16/9,
  count: "dot-section",
  layout: "medium",
  title-color: blue.darken(60%),
  toc: true,
)

= Introduction

== System model

- A *cellular network* where the base station is only a *relay*: it forwards the signal to a remote *server* over an *optical fiber*, and the server does the heavy processing (*C-RAN*).
- Users share the channel with *TDMA* (one time frame per user).
- Each user has a *Quality of Service*: a fixed rate $R_ell$, a maximum frame error rate $F_"max"$, and a maximum transmit energy.
- The link quality is set by the *path loss* (Friis), plus a frequency-selective channel drawn at random for each user:

$ "PL"_"dB" (d) = 20 log_10((4 pi d) / lambda) $

= Single cell: access control

== Rejection rate — method

- A user is *rejected* (in outage) when, even at full power $P_"max"$, it cannot reach the minimum $E_s/N_0$ required for the target $F_"max"$.
- We build a *Look-Up Table*: for each constellation, channel and equalizer, the smallest $E_s/N_0$ that reaches the target, using
$ "FER" = 1 - (1 - "BER")^(k N) $
- The *rejection rate* is the fraction of users in outage, averaged over many random user positions (Monte-Carlo).

== Rejection rate — results

#grid(
  columns: (1.7fr, 1fr),
  gutter: 14pt,
  figure(
    image("images/d4/rejection_rate_per_user_amount.png", width: 100%),
    caption: [Rejection rate versus number of users $K$ for the eight mode–equalizer configurations.],
  ),
  [
    - Around 7% rejected even for small $K$: the *edge* users, with the worst path loss.
    - The rate *jumps* when a denser constellation is forced (8-QAM, then 16-QAM), since the threshold goes up.
    - *DFE beats ZF*: ZF inverts the channel and amplifies the noise; the DFE avoids this.
    - High-rate modes saturate the cell much earlier than low-rate modes.
  ],
)



= Multi-cell interference

== Three-cell model

- Three adjacent cells $cal(C)_(-1), cal(C)_0, cal(C)_1$, one BPSK user each; we follow the *central* user.
- The server stacks the three received samples into one linear system:

$ bold(Y) = bold(H) bold(S) + bold(W) $

- $bold(S) = [s_(-1), s_0, s_1]^T$ are the user symbols, $bold(H)$ is the $3 times 3$ matrix of channel gains (diagonal = useful signal, off-diagonal = interference), $bold(W)$ is the noise.
- A *joint Zero-Forcing* receiver inverts $bold(H)$ to separate the users.

== Interference treated as noise

#grid(
  columns: (1.4fr, 1fr),
  gutter: 14pt,
  figure(
    image("images/d4/performance_in_multicell_interference.jpg", width: 100%),
    caption: [BER of the central user when the inter-cell interference is left unmanaged.],
  ),
  [
    - Each base station works *alone* and treats the neighbours as noise.
    - The BER hits a *floor* : more power does *not* help.
    - The useful signal and the interference scale together, so the system is *interference-limited*.
  ],
)

== Joint processing at the server (ZF)

#grid(
  columns: (1.4fr, 1fr),
  gutter: 14pt,
  figure(
    image("images/d4/performance_forward.jpg", width: 100%),
    caption: [BER of the central user with a joint Zero-Forcing receiver at the server.],
  ),
  [
    - The server has the three signals: $hat(bold(S)) = bold(H)^(-1) bold(Y) = bold(S) + bold(H)^(-1) bold(W)$.
    - The *floor disappears*: the BER falls. 
    - Interference removed, so the system is *noise-limited* again and more power helps.
    - *This is the quantitative justification of C-RAN.*
  ],
)

== Realistic propagation ($1/d^4$)

#grid(
  columns: (1.4fr, 1fr),
  gutter: 14pt,
  figure(
    image("images/d4/performance_with_heavy_attenuation.jpg", width: 100%),
    caption: [Same joint ZF receiver with a $1/d^4$ path loss, powers from 40 to 70 dBm.],
  ),
  [
    - Stronger attenuation makes the neighbours relatively weaker, so $bold(H)$ is almost diagonal and well-conditioned.
    - The receiver still works (no floor) and the curve is *smoother*.
    - The high powers only pay for the *link budget*, not for interference cancellation.
  ],
)

= Conclusion

== Conclusion

- *Access / receiver:* the DFE rejects fewer users than the ZF, because it does not amplify the noise.
- *Multi-cell (main result):* if we do not manage the interference, the BER cannot go below; with a *joint ZF* receiver, the server lowers it to about $10^(-3)$ — this is the main advantage of C-RAN.
- *Realistic $1/d^4$:* the joint receiver still works; the only cost is a higher transmit power to close the link.



#pagebreak()
#page(header: none, footer: none)[
  #align(center + horizon)[
    #text(size: 30pt, weight: "bold", fill: blue.darken(60%))[Thank you for your attention]
  ]
]
