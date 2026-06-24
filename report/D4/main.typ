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
== Decode-and-Forward versus Quantize-and-Forward

With *Decode-and-Forward (DF)*, the base station first understands the message: it
decodes the user bits and sends only these information bits over the fiber. The
fiber then carries just the useful information, so its rate is low, but the base
station has to do the heavy decoding work. This rate is highest with the densest
constellation, 16-QAM:

$ R_"fiber"^"DF" <= log_2(M) dot 1/T_s = 4 times 20 "Mbit/s" = 80 "Mbit/s". $

With *Quantize-and-Forward (QF)*, the base station does not try to understand the
signal at all. It simply measures the received samples, represents each one with
$q$ bits, and sends these raw numbers. Since the signal is complex, each sample has
two real parts and costs $2q$ bits. The rate is then fixed and does not depend on
the channel:

$ R_"fiber"^"QF" = 2 q dot 1/T_s = 2 times 10 times 20 "Mbit/s" = 400 "Mbit/s". $
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
 === Rejection rate per user amount 
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

=== Performance in multicell interference
In this experiment we study the effect of inter-cell interference when it is
left unmanaged. We consider three adjacent cells, each one serving a single
user with BPSK modulation, and we focus on the user of the central cell. Its
base station receives the useful signal from its own user together with the
leakage coming from the two neighbouring users, and it treats this leakage
simply as extra noise, without any joint processing. For each transmit power
$P$ from $0$ to $20$ dBm, we place the users at random, build the received
signal with the actual interfering symbols, and measure the bit error rate
(BER) of the central user by Monte-Carlo simulation. The curve below shows
this BER of the central user as a function of $P$.
 #figure(
  image("./images/performance in multicell interference.jpg", width: 100%),
  caption: [Experiment results],
)
The curve confirms this interference-limited behaviour. At low power the BER
decreases a little, because the useful signal is still weak compared with the
noise, so adding power helps at first. Very quickly, however, the curve stops
falling and settles into a floor at around 7%. Beyond this point, increasing
the transmit power brings almost no improvement. The reason is that the useful
signal and the interference share the same power scaling: when $P$ grows, both
grow by the same factor, so the ratio between them stays almost constant. The
performance is therefore limited by the interference and not by the noise, and
a single base station acting on its own cannot remove it. This is exactly the
limitation that motivates the next experiment, where the three base stations
forward their samples to the server so that a joint receiver can separate the
users and cancel the interference.
=== Performance in fowarding multicell system
In this experiment we study the same three-cell scenario, but now the inter-cell
interference is managed by the network. Instead of letting each base station work
on its own, the three base stations forward their received samples to the remote
server over the optical fiber. For a given time index, the server then holds the
three observations stacked together as $bold(Y) = bold(H) bold(S) + bold(W)$,
where $bold(S)$ contains the BPSK symbols of the three users and $bold(H)$ is the
$3 times 3$ matrix of channel gains: its diagonal carries the useful signals and
its off-diagonal terms carry the cross-interference. Having all three signals at
once, the server applies a joint Zero-Forcing receiver, which inverts the channel
matrix to separate the symbols of the three users. As before, for each transmit
power $P$ from $0$ to $20$ dBm we place the users at random, build the received
vector with the actual BPSK symbols, apply the Zero-Forcing receiver, and measure
the bit error rate (BER) of the central user by Monte-Carlo simulation. The curve
below shows this BER as a function of $P$.
 #figure(
  image("./images/performance forward.jpg", width: 100%),
  caption: [Experiment results],
)
The curve shows a completely different behaviour from the unmanaged case: there
is no floor anymore. The BER decreases steadily over the whole range, from about
18% at $0$ dBm down to roughly $10^(-3)$ at $20$ dBm, and it keeps falling as the
power grows. The reason is visible in the Zero-Forcing estimate
$hat(bold(S)) = bold(H)^(-1) bold(Y) = bold(S) + bold(H)^(-1) bold(W)$: by
inverting the channel matrix, the receiver cancels the cross-interference exactly,
and only a noise term remains. The interference that created the floor in the
previous experiment is therefore removed. This separation is not completely free,
because inverting $bold(H)$ also amplifies the noise, the noise on the central
user is the central row of $bold(H)^(-1) bold(W)$, whose power depends on how
well-conditioned the matrix is. The key difference is that this residual noise no
longer scales with the transmit power: the effective SNR of the central user now
grows linearly with $E_s$, so the system is limited by noise again and not by
interference. That is why adding power keeps helping and the BER decreases
normally. The small irregularities along the curve come from this noise
amplification, since the random user positions occasionally produce a
badly-conditioned matrix $bold(H)$ that increases the noise for that realization;
averaging over many realizations keeps these fluctuations small. Comparing the two
experiments at the same power makes the gain explicit: at $20$ dBm the unmanaged
receiver is stuck around 7%, while the joint Zero-Forcing receiver reaches about
$10^(-3)$, an improvement of several orders of magnitude. This is the quantitative
justification of the C-RAN architecture: by collecting the samples of all the
cells at a central server, the system can jointly process them and remove the
interference that a single base station, acting alone, simply cannot handle.
=== Performance with heavy attenuation
In this last experiment we reuse exactly the same three-cell scenario with joint
Zero-Forcing processing at the server, and we change only the propagation model.
The free-space Friis law, in which the path loss is proportional to $d^(-2)$, is
replaced by a stronger law proportional to $d^(-4)$, which is a more realistic
model for dense environments where the signal decays faster with distance. Because
this law attenuates the signal much more, the transmit power $P$ is now swept over
a higher range, from $40$ to $70$ dBm, so that the received signal stays usable;
apart from the propagation exponent and this power range, the simulation is
identical to the previous one. As before, for each power we place the users at
random, build the received vector $bold(Y) = bold(H) bold(S) + bold(W)$ with the
actual BPSK symbols, apply the Zero-Forcing receiver, and measure the bit error
rate (BER) of the central user by Monte-Carlo simulation. The curve below shows
this BER as a function of $P$.
#figure(
  image("./images/performance with heavy attenuation.jpg", width: 100%),
  caption: [Experiment results],
)
Two things stand out in this curve. First, there is again no floor: the BER
decreases steadily over the whole range, from about 40% at $40$ dBm down to roughly
$8 times 10^(-3)$ at $70$ dBm. The Zero-Forcing receiver therefore keeps removing
the interference under this harsher propagation, exactly as in the Friis case.
Second, and more interesting, the receiver works here in very good conditions. With
a $d^(-4)$ law the attenuation grows very quickly with distance, and the two
neighbouring users are farther from the central base station than its own user. The
relative interference $h_(0, plus.minus 1) \/ h_(0,0)$ is therefore much smaller
than before, which makes the channel matrix $bold(H)$ almost diagonal and
well-conditioned. Its inverse is then close to a diagonal matrix, the central row of
$bold(H)^(-1)$ is close to $1 \/ h_(0,0)$, and the noise amplification caused by the
inversion is almost negligible. This is also why the curve is smoother than in the
previous experiment: a well-conditioned $bold(H)$ rarely produces the large noise
spikes that appear when the matrix is badly conditioned.

The high transmit powers should not be misread as a sign that the receiver performs
poorly. The $40$ to $70$ dBm range is needed only to compensate for the much
stronger attenuation in absolute terms: the link budget collapses under the
$d^(-4)$ law, so a large transmit power is required simply to deliver enough energy
to the receiver. The contrast with the Friis experiment makes this explicit. There,
the joint receiver reached about $10^(-3)$ already at $20$ dBm, while here a
comparable error rate needs roughly $40$ to $50$ dB more power. In other words, the
quality of the interference cancellation is not the limiting factor under realistic
propagation — the power budget is. The joint C-RAN processing still does its job and
removes the interference; what becomes expensive is simply closing the link over a
fast-decaying channel.
= Conclusion
In this project we built a simulator to study the global performance of a
realistic C-RAN, from a single cell up to a multi-cell system with joint
processing at the server. The access study showed that the DFE receiver always
rejects fewer users than the ZF, because the ZF inverts the channel and amplifies
the noise on frequency-selective channels, while the DFE avoids this penalty. The
fronthaul comparison showed that the optical fiber is not the bottleneck: DF needs
at most $80$ Mbit/s per cell and QF about $400$ Mbit/s, both far below the capacity
of a real optical link. The most important result came from the multi-cell case:
when the inter-cell interference is treated as noise, the BER saturates at a floor
around $7%$ and adding power does not help, whereas a joint Zero-Forcing receiver
at the server removes the interference and brings the BER down to about $10^(-3)$.
Collecting the signals of all the cells at a central server is therefore the core
advantage of C-RAN. Finally, the realistic $1 / d^4$ case confirmed that the joint
receiver still works under stronger attenuation, the only cost being a higher
transmit power to close the link.
