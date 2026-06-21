#import "template.typ": project
#import "template.typ": project

//#import "graph_plots.typ" : *

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
  title: "Network simulation and global performance",
  subtitle: "Performance Analysis of a realistic
Cloud Radio Access Network (C-RAN)",
  authors: (
    "LOUROSA RECH Bernardo",
    "LORETE SCHMIDT Guilherme",
    "PANCHENIAK FILHO Ivan Roberto Wagner"
  ),
  school-logo: image("./images/logo_telecom_ipparis.png", width: 8cm, height:4.0cm), 
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
In this report, we build a simulator to study the global performance of a cellular network in which the base station works as a relay toward a remote server. We start by modelling a standard cell, then we add the access control that decides which users can be served, and finally we study what happens when several cells interfere with each other. We first consider a standard cellular network. We place $K$ active users at random, with a uniform distribution, inside a square cell of side $D_"max"$, and we put the base station at the center. The users share the channel with Time-Division Multiple Access (TDMA), and each user has a fixed target rate that matches one of four technology modes, from 2G/GPRS at 40 kbit/s up to 4G at 40 Mbit/s. The quality of each link mainly depends on the path loss, which we compute with the Friis equation.
In this equation, $P_t$ is the transmit power, $P_r$ is the received power,
$lambda$ is the wavelength and $d$ is the distance between the user and the base station; the antenna gains are set to 1. On top of this path loss, we apply a frequency-selective channel chosen at random for each user. We then study the whole system as a Cloud Radio Access Network (C-RAN). The base station does not process the signal alone anymore: it relays it to a remote server over an optical fiber, either by decoding and re-encoding the user streams (Decode and Forward) or by quantizing the raw received signal (Quantize and Forward).
Finally, we look at a three-cell case with BPSK transmission. We first measure the bit
error rate of the central user when the inter-cell interference is left unmanaged and
simply treated as noise, and then when the three base stations forward their samples to
the server, which collects the received vector given by @eq-system and applies a joint
Zero-Forcing receiver to separate the symbols.
$ bold(Y) = bold(H) bold(S) + bold(W) $ <eq-system>
In this model, $bold(Y) = [y_(-1), y_0, y_1]^T$ holds the samples of the three base stations, $bold(S) = [s_(-1), s_0, s_1]^T$ holds the BPSK symbols of the three users, $bold(H)$ contains the channel amplitude gains and $bold(W)$ is the noise. A Zero-Forcing receiver then inverts $bold(H)$ to separate the symbols. We finalize our analysis by computing the rejection rate against $K$ for eight mode–equalizer configurations, by comparing the data rate that the optical fiber needs for the DF and QF strategies, and by measuring the bit error rate of the central user with and without multi-cell processing, including the case of a stronger $1 \/ d^4$ path loss.

= System Implementation

== Relationship between FER and BER

A frame fails if at least one of its $N_b = k dot N$ bits is in error, where $k$ is the number of bits per symbol ($k = 1$ for BPSK, $k = 3$ for 8-QAM, $k = 4$ for 16-QAM) and $N$ is the frame size. Assuming independent bit errors, which is reasonable after equalization, the probability that the whole frame is correct is $(1 - "BER")^(k N)$. Taking the complement gives:

$ "FER" = 1 - (1 - "BER")^(k N) $

To build the Look-Up Table we invert this expression and obtain the maximum tolerable BER for a target $F_"max"$:

$ "BER"_"max" = 1 - (1 - F_"max")^(1 \/ (k N)) $

For each combination of constellation, channel, and equalizer, we then read from the D1 curves the smallest $E_s\/N_0$ that reaches this BER. This value is the entry of the Look-Up Table.

== Maximum $E_s$ and available $E_s\/N_0$ at the transmitter

The average transmit power is the symbol energy divided by the symbol period, so the maximum symbol energy allowed by the power constraint is:

$ P = E_s \/ T_s arrow.r.double E_s^"max" = P_"max" dot T_s $

Dividing by the noise spectral density gives the maximum available $E_s\/N_0$ at the transmitter side:

$ (E_s \/ N_0)_"TX"^"max" = (P_"max" dot T_s) / N_0 $

The signal reaches the basestation attenuated by the channel. With unit antenna gains, the Friis equation gives the pathloss as a function of distance $d$ and wavelength $lambda = c \/ f_0$:

$ "PL"_"dB" (d) = 20 log_10 ((4 pi d) / lambda) $

Since the energy is scaled by the same factor, the available $E_s\/N_0$ at the receiver side (in dB) is:

$ (E_s \/ N_0)_"RX"^"max" = (E_s \/ N_0)_"TX"^"max" - "PL"_"dB" (d) $

A user located at distance $d$ is in outage if, even at full power $P_"max"$, it cannot reach the minimum $E_s\/N_0$ stored in the Look-Up Table:

$ (E_s \/ N_0)_"TX"^"max" - "PL"_"dB" (d) < (E_s \/ N_0)_"min"^"LUT" arrow.r.double "outage" $

The rejection rate is the fraction of users in outage, averaged over many random realizations of the user positions.

== Inter-cell interference treated as noise

We consider three cells $cal(C)_(-1)$, $cal(C)_0$, $cal(C)_1$ with one BPSK user each.
The central basestation receives the signal of its own user plus the leakage from the
two neighbours. Since channel 0 is flat, each link is described only by its amplitude
gain $h_(0,j)$, which depends on the pathloss between user $j$ and basestation 0:

$ y_0 = h_(0,0) s_0 + underbrace(h_(0,-1) s_(-1) + h_(0,1) s_1, "interference") + w_0 $

The interfering terms $s_(-1)$ and $s_1$ are BPSK symbols, so they take discrete values
and are not Gaussian noise. For this reason we do not use a closed-form BER expression
here. Instead, the interfering symbols are generated and added explicitly, exactly as
written above, and the BER of the central user is measured by Monte-Carlo simulation
over many random user positions.

The behaviour observed in the results has a simple explanation. When the transmit power
$P$ increases, the useful signal and the interference grow by the same factor, because
they share the same power scaling. The ratio between them therefore stays almost
constant, and increasing the power no longer helps. The system becomes
interference-limited, so the BER-versus-power curve flattens into a floor instead of
decreasing indefinitely.

== Joint processing at the server with a ZF receiver

Now the three basestations forward their samples to the server without errors. For a
given time index, the server holds $bold(Y) = [y_(-1), y_0, y_1]^T$. Stacking the three
observations gives a linear system:

$ bold(Y) = bold(H) bold(S) + bold(W), quad bold(S) = [s_(-1), s_0, s_1]^T $

where $bold(H)$ is the $3 times 3$ matrix of amplitude gains, with entry
$H_(i,j) = h_(i,j)$ equal to the amplitude of the link from user $j$ to basestation $i$:

$ bold(H) = mat(h_(-1,-1), h_(-1,0), h_(-1,1); h_(0,-1), h_(0,0), h_(0,1); h_(1,-1), h_(1,0), h_(1,1)) $

The diagonal contains the useful signals, while the off-diagonal terms represent the
cross-interference. A Zero-Forcing receiver inverts the channel:

$ hat(bold(S)) = bold(H)^(-1) bold(Y) = bold(S) + bold(H)^(-1) bold(W) $

The interference is fully removed, but at the cost of noise amplification. The noise on
the estimate of $s_0$ is the central row of $bold(H)^(-1) bold(W)$ (the row associated
with cell $cal(C)_0$), with variance:

$ sigma_0^2 = N_0 norm([bold(H)^(-1)]_("central row"))^2 $

The effective SNR and the BER of the central user are then:

$ "SNR"_0^"ZF" = E_s / (N_0 norm([bold(H)^(-1)]_("central row"))^2), quad
  "BER"_0 = Q(sqrt(2 "SNR"_0^"ZF")) $

As in the previous case, the BER reported here is not computed from this formula. The
received vector $bold(Y)$ is built with the real BPSK symbols, the ZF receiver is
applied by inverting $bold(H)$, and the BER of the central user is measured by
Monte-Carlo simulation. The formula above is used only to predict the behaviour. Unlike
the previous case, the SNR now grows linearly with $E_s$, so there is no floor: the ZF
receiver removes the interference, and with enough power the BER keeps decreasing
normally. This is exactly what we observe in the results.

== The $1 \/ d^4$ case (powers between 40 and 70 dBm)

Replacing the Friis law ($1 \/ d^2$) by a $1 \/ d^4$ law makes the attenuation fall much faster with distance. Since the neighbouring users are farther from the central basestation than its own user, the relative interference $h_(0, plus.minus 1) \/ h_(0,0)$ becomes much smaller. The matrix $bold(H)$ is then almost diagonal and well-conditioned. As a consequence, even treating the interference as noise works reasonably well, and the ZF receiver suffers from negligible noise amplification. The higher powers (40 to 70 dBm) are only needed to compensate for the much stronger attenuation in absolute terms.
== Simulation's Parameters

#figure(
  table(
    columns: (auto, auto, auto),
    align: (center, center, left),
    stroke: 0.5pt,

    table.header(
      [*Parameter*], [*Symbol*], [*Value*],
    ),

    [Maximum transmit power],   [$P_"max"$],   [ 20 dBm],
    [Maximum error rate],       [$F_"max"$],   [$10^(-2)$],
    [Maximum distance],         [$D_"max"$],   [2 km],
    [Bandwidth],                [$B$],         [30 MHz],
    [Roll-off factor],          [$rho$],       [0.5],
    [Symbol period],            [$T_s$],       [0.05 µs],
    [Carrier frequency],        [$f_0$],       [2.4 GHz],
    [Noise spectral density],   [$N_0$],       [−174 dBm/Hz],
  ),
  caption: [System Parameters],
)
 == Experimental Results 
 Firstly, we study the global performance of a cellular network using a TDMA access scheme. The objective is to evaluate how the number of active users affects the percentage of users that cannot be served by the base station.

The main performance metric is the rejection rate. It is defined as the ratio between the number of rejected users and the total number of active users:

$
"Rejection Rate" = ("Number of rejected users") / ("Total number of users")
$

A user is rejected when the required transmission power is higher than the maximum allowed power:

$
P_"max" = 20 " dBm"
$

This power constraint is imposed in order to satisfy the target frame error rate:

$
F_"max" = 10^(-2)
$

In this simulation, we compare different user rates and two receiver structures: ZF and DFE.
 #figure(
  image("./images/rejection_rate_per_user_amount.png", width: 100%),
  caption: [Experiment results],
)
 The users are randomly placed inside a square cell. The base station is located at the center of the cell. For each user, the distance between the user and the base station is computed. This distance is then used to calculate the path loss using Friis' equation.

The channel is frequency-selective. This means that the channel does not affect all frequency components of the signal in the same way. Because of multipath propagation, the received signal may contain delayed versions of the transmitted signal. These delayed components create inter-symbol interference.

For each user, one channel impulse response is randomly selected among three possible channel models. Then, this channel is scaled according to the path loss between the user and the base station.

Since the system uses TDMA, the users transmit in separate time slots and do not
interfere with each other inside the cell. The access decision for each user therefore
depends only on whether its required transmit power fits within $P_max$.

In every configuration, all users share the same mode and the same receiver, so the constellation
of a given curve is fixed and does not change with $K$. For a fixed bandwidth $B$, a higher target rate $R_ell$ requires more bits per symbol,
which forces a higher-order constellation: BPSK is enough for the lowest rate, while the
highest rates need 8-QAM or 16-QAM. A higher-order constellation needs a larger
$E_s\/N_0$ to reach the same error performance, so the minimum value stored in the
Look-Up Table is higher. This is why the high-rate modes sit at a higher rejection rate
and reach their power limit for much smaller user counts: each curve has its own
maximum $K$ that depends on the mode.

Within a single curve, the rejection rate grows with $K$ because the cell becomes more
crowded. With more users placed at random, the probability that at least one of them
falls far from the base station and exceeds the power constraint $P_max$ increases. Each
user that needs more than $P_max$ to satisfy the target FER is rejected, so the fraction
of rejected users rises.

The graph also shows that the DFE receiver generally gives a lower rejection rate than
the ZF receiver. This is consistent with theory. The ZF receiver inverts the channel, so
when the frequency-selective channel strongly attenuates some frequencies, it amplifies
the noise and needs more transmit power. The DFE receiver reduces inter-symbol
interference by using previous decisions, without amplifying the noise as strongly. It
therefore needs less power to satisfy the same FER constraint, which lowers the
rejection rate.

