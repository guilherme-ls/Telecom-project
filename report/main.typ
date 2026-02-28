#import "template.typ": project

#import "@preview/equate:0.3.2": equate
#import "@preview/lilaq:0.5.0" as lq

// LTeX: language=en-US
// LTeX: statusBatItem=true 
//
#show: equate.with(breakable: true, sub-numbering: false)
#set math.equation(numbering: "(1.1)")

#let filter-positive(xdata, ydata) = {
  let pairs = xdata.zip(ydata)
  let filtered = pairs.filter(p => p.at(1) > 0)
  (
    filtered.map(p => p.at(0)),
    filtered.map(p => p.at(1)),
  )
}

#let load-eq(mod, eq, ch) = {
  let file = "./graphs/eq_sims/" + mod + "_" + eq + "_" + str(ch) + ".csv"
  let (x, y) = lq.load-txt(read(file))
  filter-positive(x, y)
}

// Ploting semilog from csv function
#let (bpsk_0_x, bpsk_0_y) = lq.load-txt(read("./graphs/bch_sims/bch0.csv"))
#let (bpsk_0_x_f, bpsk_0_y_f) = filter-positive(bpsk_0_x, bpsk_0_y)
#let (bpsk_1_x, bpsk_1_y) = lq.load-txt(read("./graphs/bch_sims/bch1.csv"))
#let (bpsk_1_x_f, bpsk_1_y_f) = filter-positive(bpsk_1_x, bpsk_1_y)
#let (bpsk_2_x, bpsk_2_y) = lq.load-txt(read("./graphs/bch_sims/bch2.csv"))
#let (bpsk_2_x_f, bpsk_2_y_f) = filter-positive(bpsk_2_x, bpsk_2_y)


#let create_resp_channel_fig(ch) = {
  let file = "./graphs/response-channel-" + str(ch) + ".csv"
  let (resp_chan_l_raw, resp_chan_h_raw) = lq.load-txt(read(file))
  //let resp_chan_h_abs = resp_chan_h_raw.map(calc.abs)
  //let (resp_chan_l, resp_chan_h) = filter-positive(resp_chan_l_raw, resp_chan_h_abs)
  figure(
    lq.diagram(
      width: 12cm,
      height: 9cm,

      lq.stem(
        resp_chan_l_raw, resp_chan_h_raw,
        mark: "o",
        stroke: (thickness: 1pt)
      ),
      title: [
        Coefficients of $h(m)$ for Channel #ch. 
      ],

      //yscale: lq.scale.scale(x => calc.log(calc.abs(x + 0.1)), x => x), //"log",
      //xscale: "linear",
      ylabel: [$h(m)$],
      xlabel: [$m$],
      xaxis: (subticks: none),
      legend: (position: left + bottom)
    ),

    caption: [
      Plot of the coefficients of $h(m)$ for Channel #ch from $-L$ to $L$.
    ],
  ) 
}

#set par(
  justify: true,
  leading: 0.52em,
)

#let create-ber-figure(mod, ch) = {
  let (x_none, y_none) = load-eq(mod, "none", ch)
  let (x_zf,   y_zf)   = load-eq(mod, "ZF", ch)
  let (x_dfe,  y_dfe)  = load-eq(mod, "DFE", ch)

  figure(
    lq.diagram(
      width: 15cm,
      height: 7cm,

      lq.plot(
        x_none, y_none,
        label: [No equalization],
        mark: "x",
        stroke: (thickness: 1pt)
      ),

      lq.plot(
        x_zf, y_zf,
        label: [ZF equalization],
        mark: "o",
        stroke: (thickness: 1pt)
      ),

      lq.plot(
        x_dfe, y_dfe,
        label: [DFE],
        mark: "+",
        stroke: (thickness: 1pt)
      ),

      title: [
        BER versus $E_b"/"N_0$ for distinct equalizations with #mod modulation in channel #ch
      ],

      yscale: "log",
      ylabel: [BER],
      xlabel: [$E_b"/"N_0 ("dB")$],
      xaxis: (subticks: none),
      legend: (position: left + bottom)
    ),

    caption: [
      Plot of the BER versus the SNR per bit in a semilogarithmic scale for a #mod constellation in channel #ch using three distinct equalizations: no equalization, Zero Forcing and Decision Feedback Equalization.
    ],
  )
}

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
  footer-text: "PRJ_4TE05_TP",
)


= Introduction

  In this report, we model the transmit and receive nodes of a transmission chain, implementing the coding of its information, its transmission through a channel, and its subsequent decoding. @chanel shows the modelled chain.

  #figure(
    image("./assets/transmission_chain.png", width: 80%),
    caption: [Transmitter and receiver chain.]
  ) <chanel>

  The channel coding will be done through two distinct BCH codes, correcting $t=1$ and $t=2$ errors respectively. Each implemented code will have a length of $N_c = 31$ and be defined considering the Galois Field extension $"GF"(32)= "GF"(2)[x]"/"1+x^2+x^5$. Both codes will adopt the systematic form to facilitate decoding. 

  In terms of the transmission channel, we consider that the transmitted symbols $s(n)$ will be linearly modulated according to @eq:input_filter, where $g(n)$ is the shaping filter satisfying the square-root Nyquist condition and $T_s$ is the symbol period.

  $ x(t) = sum_n s(n) g(t-n T_s) $ <eq:input_filter>

  On the reception side, after sampling the received signal at $1"/"T_s$ intervals and performing some mathematical simplifications, it can be described by @eq:received_signal, where *H* is a Toeplitz matrix representing the multipath channel and *w* is the Gaussian noise.
  
  $ bold("z") = bold("H s") + bold("w") $ <eq:received_signal>

  Based on the described system, we perform in this report a simulation and evaluation of its performance considering different codes, channels and modulations, discussing the employed methods and the obtained results.

= System Simulation

== BCH Implementation

 Two distinct BCH codes will be implemented in this section, both in the $"GF"(32)$ extension field, correcting $t=1$ and $t=2$ errors respectively.

=== Determining the Generator Polynomials and Code Rates

  To implement the desired BCH codes, we must first determine their corresponding generator polynomials. For a given number of errors $t$ that the BCH code must correct, its generator polynomial must have $2t$ consecutive roots $alpha^i$ ($i = 1...t$), powers of the primitive element $alpha$ and also roots of $x^(31)-1$. For each root $alpha^i$ there is a corresponding minimal polynomial $mu_(alpha^i) (x)$, and $g(x)$ will be given by the lowest common multiplier between the minimal polynomials of its roots:

  $ g(x) = L C M(mu_(alpha^1)(x), ..., mu_(alpha^(2t))(x) ) $

  Therefore, starting with the code capable of correcting one error, $g(x)$ must have as roots ${alpha^1, alpha^2}$. To determine the corresponding minimal polynomials, we must highlight the fact that a power of two of a root is also root, and that $alpha^(32) = alpha$. This lets us describe the minimal polynomial $mu_(alpha^1)(x)$ in @eq:primitive_poly and show that both $alpha^1$ and $alpha^2$ will have the same minimal polynomial.

  $ mu_(alpha^1) (x) = (alpha - 1)(alpha^2 - 1)(alpha^4 - 1)(alpha^8 - 1)(alpha^16 - 1) = mu_(alpha^2) (x) $ <eq:primitive_poly>

  To find its value, we must notice that $alpha$ is one of the roots of the primitive polynomial of the $"GF"(32)$ extension field, which in our case is $1+x^2+x^5$. Therefore, we conclude that $mu_(alpha^1) (x) = mu_(alpha^2) (x) = 1+x^2+x^5$.

  Thus according to the previously stated theory, the LCM of both polynomials gives us $g(x) = 1+x^2+x^5$. Now to calculate the code's efficiency, we must first determine its length $n$ and dimension $k$. The length will be given by $n=2^m-1$, where $m=5$ for $"GF"(32)$, leading to $n=31$. Concerning the dimension, a fundamental property of cyclic codes tells us that for each to be unique the equality $d^o g(x) = n - k$ must hold. Since $d^o g(x) = 5$ for the first BCH code, its dimension must be $k = 26$. Finally, the code rate for the BCH code where $t=1$ will be $R=26"/"31$.

  We now proceed with the second code. It is capable of correcting $t=2$ errors, such that the roots of its generator polynomial will be ${alpha^1, alpha^2, alpha^3, alpha^4}$. From @eq:primitive_poly, we know that $mu_(alpha^1) (x) = mu_(alpha^2) (x)= mu_(alpha^4) (x) = 1+x^2+x^5$. @eq:primitive_poly3 shows $mu_(alpha^3) (x)$.

  $ mu_(alpha^3) (x) &= (alpha^3 - 1)(alpha^6 - 1)(alpha^12 - 1)(alpha^24 - 1)(alpha^17 - 1) #<equate:revoke> \
  &= 1 + x + x^2 + x^3 + x^4 + x^5 $ <eq:primitive_poly3>

  Therefore, we get that the generator polynomial is $g(x) = x^(10) + x^9 + x^8 + x^6 + x^5 + x^3 + 1$. From this, we can again deduce that the code length is $n = 2^m - 1 = 31$ and its dimension is $k = n - d^o g(x) = 21$. Thus, the code rate for the BCH code capable of correcting $t=2$ errors is $R=21"/"31$.

  @tab:code_information gives the code rates and generator polynomials of each studied BCH code.

#figure(
  caption: [Generator polynomials and code rates of the studied BCH codes.],
  table(
    columns: (1fr, 2fr, 1fr),
    inset: 12pt,
    align: center,
    stroke: 0.6pt,

    table.header(
      [$"Error Capability"$],
      [$g(x)$],
      [$R$],
    ),

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


=== Implementing the Standard Coding Operation

  Proceeding to the next step, we now seek to implement the encoder. With the aim of facilitating the decoding, we will describe the code in its systematic form, where the first $n - k$ bits of the codeword $c(x)$ are the parity bits and the following $k$ bits are the original information $m(x)$, as shown in @eq:systematic_code.

  $ c(x) = x^(n-k)m(x) + t(x) " where " t(x) = x^(n-k) m(x)"mod"g(x) $ <eq:systematic_code>

  The encoder here implemented will calculate $t(x)$, that is, perform the $"mod"g(x)$ operation. It adopts the form of linear feedback shift registers, as shown in @encoder, where the generator polynomial's coefficients determine the feedback components (considering $g(x) = g_0 + g_1 x + ... + g_m x^m$).

  #figure(
    image("./assets/coding_scheme.png", width: 90%),
    caption: [Encoder architecture.]
  ) <encoder>

  The encoding process consists in initializing the shift registers as 0 and consecutively inserting the coefficients of $m(x)$ one at a time, from the highest order to the lowest until the word ends. The values at the shift register at the end will be the result of the modulo operation.

  In the matlab code, the encoder was dully implemented as a function that first reverses the order of the input word's coefficients and then performs a loop that consecutively inserts these coefficients into an empty vector of size $n-k$, shifting the values forward and adding the feedback components at each step.

  ```matlab
  function [m_mod] = bch_mod_g(m, g)
    m(1:end, :) = m(end:-1:1, :); % Reversing m(x)
    g_deg = size(g, 1) - 1;
    m_mod = zeros(g_deg, size(m, 2)); %% m(x) mod g(x)
    for ii=1:size(m, 1)
        % Perform the shift in m_mod
        shifted_temp = circshift(m_mod, 1);
        
        % Use the temporary variable to perform 
        % the feedback step and add new entry
        m_mod = [m(ii, :); shifted_temp(2:end, :)] ...
                + m_mod(g_deg, :) .* g(1:g_deg);
    end
    m_mod = mod(m_mod, 2);
  end
  ```

  For the generation of the coded word $c(x)$, we inserted the shifted information word $x^(n-k)m(x)$ in the encoder to get the parity bits, and them built a vector of size $n=31$ by concatenating first the parity bits and them the information word $m(x)$. This finalizes the coding operation.

  ```matlab
  g_deg = length(g);
  shifted_m = [zeros(g_deg - 1, size(m, 2)); m]; % m(x) shifted by n - k 
  parity_bits = bch_mod_g(shifted_m, g);
  y = [parity_bits; m];
  ```

  We highlight that the encoder depends on $g(x)$ and is therefore distinct for each code.

=== Implementing Optimal ML Decoding

  Under a theoretical Binary Symmetric Channel (BSC) hypothesis, one can show that the optimal ML decoding consists in minimizing the Hamming distance between the sent $c(x)$ and received $r(x)$ messages, which is equivalent to minimizing the Hamming weight of the error $e(x)$ added to the received message ($R(x) = c(x) + e(x)$).

  In practice, this decoding is done through syndromes, which in the case of cyclic codes consists in the modulo $g(x)$ of the received message $r(x)$ (@eq:syndrome1). 

  $ s(x) = r(x)"mod"g(x) $ <eq:syndrome1>
  
  Since the received message is given in function of the sent message and some error ($r(x) = c(x) + e(x)$) and the sent message is a multiple of $g(x)$ ($c(x)"mod"g(x) = 0$), we can show that the syndrome is directly related to the modulo of the error (@eq:mod_error).

  $ s(x) = c(x)"mod"g(x) + e(x)"mod"g(x) = e(x)"mod"g(x) $ <eq:mod_error>

  Therefore, for each syndrome, we can relate an error polynomial of minimal weight that generates it, which can then be stored in a look-up table. By doing this, for correcting the errors in $r(x)$, one can simply sum the error $e(x)$ corresponding to the calculated syndrome, letting us recuperate $c(x)$ (this is valid as each polynomial coefficient belongs to $"GF"(2)$).

  In the code, we first implement the syndrome look-up table, going through all the error polynomials possible for $t=1$ and $t=2$ errors, depending on the BCH code, and then calculating the respective syndrome using the modulo operation previously implemented in the encoder. Each pair error-syndrome is then saved in memory.

  ```matlab
  %% Calculates all error vectors given a max error number
  err_mat = bch_error_vector_gen(n, error_num);
  %% Loops over error vectors
  for ii=1:size(err_mat,2)
      e = err_mat(:,ii); % Gets error collumn vector from error matrix
      %% Syndrome calculation
      synd = bch_mod_g(e, g);
      synd_int = bi2de(synd', "left-msb"); % Converts vector into index
      %% Associating syndrome to error vector and storing
      synd_table{synd_int} = e;
  end
  ```

  One important observation is that for the case of the BCH code where $t=2$, there are more syndromes than error polynomials with 1 and 2 errors, implying that some possible syndromes would lead to 
  polynomials with 3 or more errors. However, since the code is not consistently capable of correcting more than 2 errors, we chose to ignore these syndromes and employ a default case where we do not
  attempt to correct any errors ($e(x) = 0$).

  The decoder itself is then implemented as a code that first calculates the syndrome of the received message through the previous modulo function, and then finds the respective error in the syndrome 
  look-up table. After this, it sums the error with the received message bit by bit to get the corrected coded message. To finalize the decoding, since the systematic encoding is being employed, we remove the 
  parity bits that were previously added to the start of the message, leaving only the information bits.

  ```matlab
  %% Calculates syndrome and turn it into a integer representation
  syndrome = bch_mod_g(y,g);
  syndrome_int = bi2de(syndrome', "left-msb");

  % Error calculation
  if syndrome == 0 % No errors
      err = zeros(length(y), 1);
  else % Get the error from the syndrome table
      err = syndrome_table{syndrome_int};
  end
  if isempty(err) % Default case (>2 errors)
      err = zeros(length(y), 1);
  end

  y_hat = mod(y + err, 2); %% Error elimination
  m_hat = y_hat(length(g):1:end); %% Removes parity bits
  ```

=== BER Analysis on BPSK Modulation

  With all the BCH coding aspects implemented, we now use the code provided to build the modulation and demodulation systems and to simulate the transmission channel itself. In fact, first we take the bits that compose the coded (or not) message and pass them through the ``` bits2symbols``` function to get the modulated signal (BPSK in this section).
  
  Then, considering that the provided codes need the bit energy to be normalized at $E_b = 1$, we calculate instead the noise variance necessary to achieve a desired $E_b"/"N_0$ value as $N_0 = (1/10)^((S N R_b)/10) $. Taking into account the code rate, we must divide the variance by $R$.

  This variance is then used to create a complex circular white noise to apply to the symbols as they are passing the transmission channel. The resulting noisy signal then passes through 
  a threshold detector, estimating the symbols received, and is demodulated through the ``` symbols2bits``` function, proceeding through the decoding and finally measuring the Bit Error Rate for plotting.
  For the simulations, at each SNR step we performed the error averaging over approximately $10^8$ bits at maximum and stopped the simulations at 100 detected errors, 
  since it already gives a good level of precision.

#figure(
  lq.diagram(
    width: 15cm,
    height: 10cm,
    lq.plot(bpsk_0_x_f, bpsk_0_y_f, label: [BPSK - not coded],
            mark: "x", stroke:(thickness: 1pt, dash: "solid")),
    lq.plot(bpsk_1_x_f, bpsk_1_y_f, label: [BPSK - BCH code $t=1$],
            mark: "o", stroke:(thickness: 1pt, dash: "solid")),
    lq.plot(bpsk_2_x_f, bpsk_2_y_f, label: [BPSK - BCH code $t=2$],
            mark: "+", stroke:(thickness: 1pt, dash: "solid")),
    title: [BER versus $E_b"/"N_0$ for distinct coding schemes with BPSK modulation.], 
    yscale: "log",
    ylabel: [BER],
    xlabel: [$E_b"/"N_0 ("dB")$],
    xaxis: (subticks: none),
    legend: (position: right + top)
  ),
  caption: [Plot of the BER versus the SNR per bit in a semilog scale for a BPSK constellation and three distinct channel coding schemes: a not coded base case, a BCH code correcting $t=1$ error, and a BCH code correcting $t=2$ errors.],
) <BPSK-coded>

  @BPSK-coded shows us the BER versus $E_b"/"N_0$ curve comparison between the not coded case and the two implemented BCH codes, using a BPSK modulation and an AWGN channel on all cases. First, we observe that for low SNR the performance of the coded case is bellow the not coded one, indicating that the decrease in the energy per bit as a result of the reduced code rate outweighs the increase in performance due to the error correction. Indeed, for low SNRs the error frequency tends to be so high that the code is rarely capable of correcting all of them.

  However, from an SNR of $4 "dB"$ onwards, the coded cases start performing better than the non-coded one, indicating that the error correcting capacity of the code becomes increasingly relevant in reducing the BER. The coding gain becomes highly perceptible for high SNRs.

  From this graph we can identify the empirical coding gain of both the implemented BCH codes and compare them to the theory. The theoretical coding gain considering an Additive White Gaussian Noise (AWGN) channel and a hard decision, as is our case, is given by $gamma_(d B) = 10 "log"(R(t+1))$, therefore the first BCH code must have a coding gain of $gamma_(1 d B) = 10 "log"(26/31 times 2) = 2.25 "dB"$ and the second code $gamma_(1 d B) = 10 "log"(21/31 times 3) = 3.08 "dB"$.
  
  Note that the graph does not capture the asymptotic coding gains, as that would require an extreme amount of computational resources. However, we can still analyze the gain measured at the BER of $times 10^(-5)$ to get empirical gains of approximately $1.6 "dB"$ for the first code and $2.2 "dB"$ for the second one. Even if it is significantly lower than the theoretical gains, we can see that the curves show a tendency in increasing the coding gain and reaching its asymptotic value as they continue.

== Multipath Channels

  Furthering the analysis, we seek to study how distinct multipath channels, in addition to the AWGN, may affect performance. These multipath channels are described by @eq:multipath, being characterized by a sum of attenuated and delayed Nyquist filters representing the different paths the signal might take.

  $ tilde(h) (t) = sum_(k=0)^M A_k tilde(g)(t - tau_k) $ <eq:multipath>

  In our analysis the attenuations $bold(A)$ and delays $tau$ that characterize the channel are given bellow. Observe that channel 0 corresponds to the pure AWGN case. Also note that $T_s = 0.05 mu s$.

  - Channel 0: $bold(A) = [1], tau = [0] times T_s, (M = 0),$
  - Channel 1: $bold(A) = [1, 0.1, 0.1, 0.1, 0.1], tau = [0, 0.5, 1, 1.5, 2] times T_s, (M = 4),$
  - Channel 2: $bold(A) = [1, 0.8, 0.6, 0.4, 0.2], tau = [0, 0.5, 1, 1.5, 2] times T_s, (M = 4),$
  - Channel 3: $bold(A) = [1, 0.8, 0.8, 0.8, 0.8], tau = [0, 0.5, 1, 1.5, 2] times T_s, (M = 4),$

  Considering that the symbols being transmitted stay the same for a period $T_s$, we may sample the $tilde(h) (t)$ at $T_s$ intervals (@eq:channel_filter). The resulting filter is also normalized so that $Sigma_(m=-L)^L ||h(m)||^2=1$.

  $ h(m) = tilde(h) (m T_s) = sum_(k=0)^M A_k tilde(g)(m T_s - tau_k) $ <eq:channel_filter>

  With this, we can arrive at the coefficients of $h(m)$ for each channel, which are plotted in @h_channel_1, @h_channel_2 and @h_channel_3.

  Observe that in the first channel, shown by @h_channel_1, most of the power is concentrated in the current symbol, making intersymbol interference (ISI) not very strong. In contrast, channel 2 (@h_channel_2) has half its power in the middle signal and almost half in the following one, which will lead to a strong level of intersymbol interference that will have consequences shown and discussed in next section. Finally, @h_channel_3 shows channel's 3 coefficients and how most of the power does not belong to the current symbol and is mostly spread across neighboring symbols, resulting in severe intersymbol interference and poor performance in the absence of equalization.

  #create_resp_channel_fig(1) <h_channel_1>
  #create_resp_channel_fig(2) <h_channel_2>
  #create_resp_channel_fig(3) <h_channel_3>

  This lets us describe the channel through a Toeplitz matrix, as represented in @eq:toeplitz, which allow us to conveniently analyze the digital transmission chain following the matrix framework given by @eq:matrix_framework. $bold("w")$ represents the added white gaussian noise, $bold("s")$ the signal sent through the channel and $bold("z")$ the received signal.

  $ bold("z") = bold("Hs") + bold("w") $ <eq:matrix_framework>

  $
  bold("H") = mat(
    h(0), h(1), dots, h(L), 0, dots, 0;
    h(-1), h(0), h(1), dots, h(L), 0, dots;
    dots, 0, h(-L), dots, h(-1), h(0), h(1);
    0, dots, 0, h(-L), dots, h(-1), h(0);
  ) $ <eq:toeplitz>

  For this to work the symbols to be sent were organized in frames of size $N=100$, which is also the size of the matrix $bold("H")$.

  To deal with the distortions introduced by the multipath channels we will employ two distinct approaches. The first is the Zero Forcing (ZF) equalizer, which multiplies $bold("z")$ by the pseudoinverse $bold("H")^\#$ of the channel matrix $bold("H")$, eliminating the intersymbol interference on the signal $bold("z")'_(Z F) = bold("s") + bold("H")^\#bold("w")$. After the equalization, a threshold detector is applied.

  Observe that in this equalization scheme the noise is multiplied by $bold("H")$. If $bold("H")$ is not a unitary matrix, this will lead to an amplification of the noise power. Thus, even if intersymbol interference is eliminated, the noise increases.

  The second is given by the Decision-Feedback Equalizer (DFE), which applies QR decomposition on $bold("H")$ so that $bold("H") = bold("VT")$, where $bold("V")$ is a unitary matrix and $bold("T")$ is superior triangular. Multiplying $bold("z")$ by $bold("V")^H$ gives us @eq:dfe, where $bold("w")'$ has the same distribution as $bold("w")$. $bold("z")'_(D F E)$ is determined by performing backwards substitution on the linear system given by $bold("Ts")$ and applying a threshold detector on the newly determined component at each step.

$ bold("z")'_(D F E) = bold("Ts") + bold("w")' $ <eq:dfe>

  Observe that this equalization scheme does not change the power of the noise, since it multiplies the received symbols by a unitary matrix. However, its performance depends on the correctness of past decisions. If an incorrect decision occurs early in the detection process, that error is fed back into the equalizer and propagates to subsequent symbols, which may lead to bursts of errors.

=== Implementation

  The implementation of these multipath channels started by dividing the data into frames. Since at first we are dealing only with the case where there is no channel coding, it suffices to separate the message bits into groups of size $N"log"_2M$, where $M$ is the size of the constellation employed and $N$ the frame size, and then convert these groups of bits into symbols, which will compose the desired frames.

  Continuing, the multipath channels were implemented by first taking samples from $h(m)$ (given by the provided function ``` response_channel```) and then building a Toeplitz matrix of size $N times N$ from these samples. Finally, the AWGN is added.

```matlab
  if c == 0 % c is the channel number
      H = eye(N);
  else
      h = response_channel(c);
      L = (length(h) - 1) / 2;
      H = toeplitz([h(1 + L) fliplr(h(1:L)) zeros(1,N - L - 1)], ...
          [h(1 + L: 2*L) zeros(1,N - L)]);
  end
  y = H*s + noise;
  ```

  As a last step, the different equalizers are all implemented following the equations described in the previous section.

  ```matlab
  if strcmp(equalizer, "ZF") % Zero Forcing using the pseudoinverse
      y_eq = pinv(H) * y;
      [s_hat, ~] = threshold_detector(y_eq, modulation, M);
  elseif strcmp(equalizer, "DFE") % Decision-Feedback Equalizer
      [Q,R] = qr(H);
      z = Q' * y; % Applies adjoint of unitary matrix
      s_hat = zeros(N,1);
      for ii = N:-1:1 % Performs backward substitution and decision
          y_eq = (z(ii) - R(ii,ii+1:N) * s_hat(ii+1:N)) / R(ii,ii);
          [s_hat(ii), ~] = threshold_detector(y_eq, modulation, M);
      end
  else % No equalization
      y_eq = y;
      [s_hat, ~] = threshold_detector(y_eq, modulation, M);
  end
  ```

  This finalizes the multipath channels and equalization implementations.

=== BER Plots and Discussions

  We start the analysis by plotting the BER versus SNR curves of a BPSK modulated signal using both of the equalization methods discussed and comparing to a non equalized signal, repeating the analysis for each channel.

  @2PSK_channel1 shows the performance gains that can be obtained through equalization. The application of either ZF equalization or DFE promotes a significant drop in BER for the same SNR when compared to the non-equalized case. This drop in SNR increases as the noise decreases, showing that as noise becomes decreasingly relevant as a source of errors, the relevancy of the intersymbol interference relatively increases. Additionally, we observe that both equalization schemes have almost the same performance in this low interference environment.
  
  #create-ber-figure("PSK2", 1) <2PSK_channel1>

  #create-ber-figure("PSK2", 2) <2PSK_channel2>

  Observe that without equalization, @2PSK_channel2 exhibits a constant BER close to 25%, which agrees with theoretical expectations for channel 2. The impulse response contains two dominant bins of nearly equal magnitude, so the received signal is approximately the sum of the current symbol and the previous one with similar weights. When two consecutive symbols are equal, their contributions add constructively and detection is correct. However, when they have opposite signs, their contributions nearly cancel, producing a received value close to zero. In these cases, the detector effectively makes a random decision because of the added Gaussian noise, resulting in a 50% error probability. Since this situation occurs with probability 1/2, the overall asymptotic BER converges to 0.25 (50% of error 50% of the time).

  This high intersymbol interference makes equalization even more important due to the fact that it completely eliminates ISI, which we can see through the performance curves of ZF and DFE. Note, however, that DFE performs significantly better than ZF equalization, which is mostly due to the fact that ZF increases the noise power as discussed in the theoretical section. Even if DFE has its own error propagation problem, it still performs better in our simulations.

  Finally, @2PSK_channel3 shows the performance analysis for channel 3. We can once gain note that the non-equalized error rate stabilizes at 25% and that equalization is necessary. However, the higher level of interference in this channel promotes a decrease in the performances of the equalized case, especially for ZF. This means that the noise power is further increased by the new $bold("H")$ matrix in the ZF case, and that the DFE also had its error propagation problem negatively affected.

  #create-ber-figure("PSK2", 3) <2PSK_channel3>
  
  #create-ber-figure("QAM8", 1) <8QAM_channel1>
  
  Conducting the analysis now for the 8-QAM modulation, @8QAM_channel1 shows us that its lower coding gain in relation to BPSK enabled us to observe the inflection point where the errors induced by the noise cease to significantly affect performance, leaving only the asymptotic error rate due to ISI. Once again, the equalized cases perform significantly better having removed the channel interference.
  
  Now, for channel 2 (@8QAM_channel2) once again shows a constant error rate, now of 35%. The rate increases because each symbol now assumes 4 distinct values and the constellation geometry attributes distinct error rates for each possible pair of symbols interfering, the full deduction of the rate will not be done here. We again observe that equalization is essential for reducing BER and that ZF shows a slightly lower performance.
  
  #create-ber-figure("QAM8", 2) <8QAM_channel2>

  Finally, channel 3 (@8QAM_channel3) shows a continuation of the observed trends, where the non-equalized case still presents a constant BER and that the performance of the equalized cases is still slightly worse in relation to channel 2. The previously outlined reasons once again apply here.

  #create-ber-figure("QAM8", 3) <8QAM_channel3>
  
  #create-ber-figure("QAM16", 1) <16QAM_channel1>

  Through @16QAM_channel1 we observe that the lower constellation gain of 16-QAM further degrades performance. Now, the non-equalized case BER is almost constant, like for the other channels. However, equalization still shows improvement and ZF does not significantly diverge from DFE.

  Channel 2 (@16QAM_channel2) shows that a new constant BER of 38% is observed, once again attributed to the 16 values the constellation can adopt and to its geometry. Equalization still shows itself essential for the decoding process, presenting good performance in face of the heavy interference. DFE stays better preforming than ZF.
  
  Finally, @16QAM_channel3 shows that channel3 still experiences the performance degradation in equalized cases seem in other instances. 

  #create-ber-figure("QAM16", 2) <16QAM_channel2>
  
  #create-ber-figure("QAM16", 3) <16QAM_channel3>

= Conclusion

As shown throughout this report, there are as many phenomena that needs to be taken into account when designing a TX/RX chain (AWGN, ISI, Multipath Channels) as there are 
ways to solve it (BCH codes, ZF and DFE equalizers, PSK and M-QAM modulations). 

We saw how in the simpler cases (no to almost no ISI) a simpler (and possibly cheaper) communication chain (no equalization in channels 0 and 1) was able to give "workable" BER values,
but limited ourselves to use a low rate modulation scheme (BPSK), with performance quickly degrading as the constellation grew, and became completely unusable with higher ISI's (channels 2 and 3).

This shows the importance of knowing how and when to use the equalization techniques shown, as they not only allows us to work in highly ISI affected channels, but adds the possibility
of using more complex modulations without a significative hit to the BER performance while increasing the bit rate. But, the complexity these equalizers add to the chain are 
a trade of that needs to be taken into account.

Thankfully, not everything needs to be done in the symbol reception side. The BCH codes studied show how we can increase the reception gain by the addition of parities bits, 
with, arguably, a lower cost than changing the modulation scheme or adding equalizers, as these can be implemented before the symbol modulation chain in software (for example).

And while the difference in BER shown in the simple AWGN with BPSK example studied isn't as big as the difference from using an equalizer in channels 1 to 3, this gain is added independently 
of the symbol-side part of the chain, allowing us to reduce constraints imposed to the TX/RX circuit, even if by $2 "dB"$. This is very important because every $"dB"$ saved in the SNR is a reduction 
in the power consumed by the circuit, or a possibility of increasing the bit rate.

= Appendix

== Notes on Matlab Code Optimizations

This section will talk about the Matlab code optimization tricks that we learned throughout the process of 
writing the simulations for this report. While it wasn't mandatory, we placed a lot of effort into it as 
we quickly noticed that we would need to optimize the code we had written, otherwise we would have to wait 
upwards of _40 minutes_ for a *single* simulation to finish (with mediocre results).

And thus, this task of executing as *quickly* as possible the *highest amount* of simulation iterations (which correlates 
to the precision of the simulation results, as they are heavily influenced by the Gaussian noise added) appeared. 

We won't go much into the details of _why_ a technic helped, but we will list _what_ helped, and try to correlate with 
some specificity of the tools (Matlab and Octave) used.


=== Vectorization Basics

Vectorization, as described by the Octave documentation 
#footnote[https://docs.octave.org/interpreter/Vectorization-and-Faster-Code-Execution.html],
is "a programming technique that uses vector operations instead of element-by-element loop-based operations".
This means that, instead of writing a loop with the "for-loop" structure, we write them as a single operation over 
a vector. 

Take for example this simple loop to add two matrices $bold(A)$ and $bold(B)$ to $bold(C)$.

```matlab 
for i = 1:n
  for j = 1:m
    c(i,j) = a(i,j) + b(i,j);
  endfor
endfor
```

As you may notice, each element of matrix $bold(C)$ only depends on a single element of $bold(A)$ and $bold(B)$.
This means that we can write this operation as an element-wise one, as showcased by the following code.

```matlab 
c = a + b;
```

You will see this idea of "find where the data dependencies are, and separate them" a lot in the following sections

=== Finding Code Bottlenecks

Before we begin talking about the changes, it is important to note that, even if a change might make a part of 
the simulation code run faster, it doesn't mean that it was the main source of the simulation slowdown.

Vectorization is a way to do code parallelization, as these mathematical tools (Matlab and Octave) were made to 
be really efficient in handling and managing matrix structures, so the more "matrix-like" the operation is, 
the better they can optimize.

This means that any speedup#footnote[https://en.wikipedia.org/wiki/Speedup] we might expect from vectorizing/parallelizing
a piece of code will be limited by Ahmdal's Law#footnote[https://en.wikipedia.org/wiki/Amdahl%27s_law]. In short, Ahmdal's 
Law says that a program can only go as fast as the serialized sections.

But not all serialized sections of code are the same, some run once per simulation cycle, while others may run for every 
bit of information. Trying to figure out which is which manually can be cumbersome and is prone to misjudgment of what is 
really impacting the performance. 

Thus, to find the bottlenecks, we can time the execution of a function, and compare its execution time with the simulation's as 
a whole. In Octave (and Matlab) this can be done my encompassing a block of code with the keywords ```matlab tic;``` and
```matlab toc```. They time how long the code was executing from the first ```matlab tic``` call to the last ```matlab toc```.

We used them in a "binary search" fashion, allowing us to quickly track down the slow parts in the simulation code. Take for example 
the following code in `frame_decode_compare.m` from commit #link("https://gitlab.telecom-paris.fr/projet-telecom/2025-2026/prj-4te05-gr6/-/blob/4a7d73722e0b02b6511a6088476d26415758bb35/src/D1/frame_decode_compare.m")[`4a7d73722e0b02b6511a6088476d26415758bb35`].

```matlab 
function [errors_per_frame, errors_per_bit, amount_of_errors] = frame_decode_compare(m_total, frame_bits, g, t, syndrome_table, n, k)
    %% Symbol Decoding
    number_bits = size(frame_bits, 1); % number of bits in a frame
    n_words = floor(number_bits / n);

    %% Separates bits into words and decode them
    m_c_hat = reshape(frame_bits(1:n_words*n, :), n, []);

    %% BCH code decoding
    if t ~= 0
        [m_hat, ~] = bch_decoder(m_c_hat, g, t, syndrome_table);
    else
        m_hat = m_c_hat;
    end

    %%%% Total amount of error bits
    m_hat = reshape(m_hat, [], size(frame_bits, 2));
    errors_per_frame = sum(mod(m_hat + m_total, 2), 1);
    amount_of_errors = sum(errors_per_frame);
    errors_per_bit = amount_of_errors / length(m_total(:));
end
```

This code was already heavily vectorized, but we can still find where the bottlenecks are by placing ```matlab tic;``` and
```matlab toc``` in the following manner. 

```matlab 
function [errors_per_frame, errors_per_bit, amount_of_errors] = frame_decode_compare(m_total, frame_bits, g, t, syndrome_table, n, k)
    tic;
    %% Symbol Decoding
    number_bits = size(frame_bits, 1); % number of bits in a frame
    n_words = floor(number_bits / n);

    %% Separates bits into words and decode them
    m_c_hat = reshape(frame_bits(1:n_words*n, :), n, []);
    toc

    tic;
    %% BCH code decoding
    if t ~= 0
        [m_hat, ~] = bch_decoder(m_c_hat, g, t, syndrome_table);
    else
        m_hat = m_c_hat;
    end
    toc

    tic;
    %%%% Total amount of error bits
    m_hat = reshape(m_hat, [], size(frame_bits, 2));
    errors_per_frame = sum(mod(m_hat + m_total, 2), 1);
    amount_of_errors = sum(errors_per_frame);
    errors_per_bit = amount_of_errors / length(m_total(:));
    toc
end
```

If we then run this modified code, we get in the output of the simulation the following lines.

```sh
$ octave main.m
...
Elapsed time is 3.31402e-05 seconds.
Elapsed time is 0.0188391 seconds.
Elapsed time is 0.000133991 seconds.
...
```

Which indicates that the middle section of the code is the one that needs our attention, as it is the one that is taking longer than the others.

This was the main technique used to find the issues in performance problems solved by the changes mentioned in the following section.

=== Code Changes

==== Vectorization of Loops

The first technique of vectorization used was turning for-loops into vector operations. As an example of where this was applied see the following code 
in `bch_mod_g.m` from commit 
#link("https://gitlab.telecom-paris.fr/projet-telecom/2025-2026/prj-4te05-gr6/-/blob/fe0499233bebcc60f843963c857790ce9d4a5d95/src/D1/bch_mod_g.m")[`fe0499233bebcc60f843963c857790ce9d4a5d95`]
#footnote[This report simulation files can be found at #link("https://gitlab.telecom-paris.fr/projet-telecom/2025-2026/prj-4te05-gr6")[https://gitlab.telecom-paris.fr/projet-telecom/2025-2026/prj-4te05-gr6]].

```matlab 
function [m_mod] = bch_mod_g(m, g)
    % Reversing m(x) so it gets correctly shifted 
    % into the shift registers
    m(1:length(m)) = m(end:-1:1); 
    
    g_deg = size(g,1) - 1;
    m_mod = zeros(g_deg, 1); %% m(x) mod g(x)
    for ii=1:length(m)
        m_mod_prev = m_mod;
        % First element of the shift register
        m_mod(1) = mod(m(ii) + g(1) * m_mod_prev(g_deg), 2); 
        for jj=2:g_deg
            m_mod(jj) = mod(m_mod_prev(jj - 1) ...
                        + g(jj) * m_mod_prev(g_deg), 2);
        end
    end
end
```

It implements the $m(x) mod g(x)$ operation for codding and decoding in the BCH code as shown in @encoder. 
As can be seen, the block of code inside the loop ```matlab for ii=1:lenght(m)``` is simply encoding @mod-vec-eq1 and @mod-vec-eq2.

$ m\_mod_(i + 1)(1) = m(i) + m\_mod_(i + 1)(d degree g) $ <mod-vec-eq1>
$ m\_mod_(i + 1)(x) = m\_mod_(i)(x - 1) + m\_mod_(i)(d degree g) dot g(x) forall x = 2,..,d degree g $ <mod-vec-eq2>

Where $d degree g$ is the degree of the polynomial $g(x)$, $m(x)$ is the message being modulated, 
and $m\_mod_(i)$ the values of the registers of this modulo operation implementation at iteration $i$.

It is important to note how the value of $m\_mod_(i + 1)(x)$ only depends on previous values of 
$m\_mod_(i)(x)$, $m(x)$ and $g(x)$, this means that, instead of calculating $m\_mod_(i + 1)(x)$ 
sequentially, we can determine it in parallel, as there is no data dependency between values of
$m\_mod_(i + 1)(x)$ from the same iteration.

And thus, we can rewrite the body of the iteration loop as the one found in commit 
#link("https://gitlab.telecom-paris.fr/projet-telecom/2025-2026/prj-4te05-gr6/-/blob/32a04fc05b6ed67d4929f9209b0e89d66d851963/src/D1/bch_mod_g.m")[`32a04fc05b6ed67d4929f9209b0e89d66d851963`].

```matlab 
function [m_mod] = bch_mod_g(m, g)
    % Reversing m(x) so it gets correctly shifted 
    % into the shift registers
    m(1:end, :) = m(end:-1:1, :); 
    
    g_deg = size(g, 1) - 1;
    m_mod = zeros(g_deg, size(m, 2)); %% m(x) mod g(x)
    for ii=1:size(m, 1)
        % Perform the shift in m_mod
        shifted_temp = circshift(m_mod, 1);
        
        % Use the temporary variable to perform 
        % the feedback step and add new entry
        m_mod = [m(ii, :); shifted_temp(2:end, :)] ...
                + m_mod(g_deg, :) .* g(1:g_deg);
    end
    m_mod = mod(m_mod, 2);
end

```

Not only this code is vectorized, but it is more compact, and less error-prone, 
as it is closer to the mathematical definition of the modulo operation (as a shift register).

==== Vectorization of Simulations

This second technique is a generalization of the first one, and is what allowed us to execute more 
simulation iterations in less time. 

Instead of limiting ourselves at searching for loops inside the simulation to parallelize, we 
looked at parallelizing multiple simulation runs. In short, instead of having, for example, 
a loop of $N$ iterations running over a vector of size $M$, we executed a single iteration 
with a matrix of size $M times N$.

As simulation iterations are independent of one another data-wise, we are free 
to execute multiple of them in parallel, taking advantage of the multiple cores modern computers 
have and the higher amount of RAM.

This meant that all the code had to be rewritten to take into account that it would receive a matrix instead of a vector,
and that it should treat each column of the matrix (in our simulation, a vector was always a column vector) independently.

But it greatly increased the throughput of our simulation, allowing us to simulate thousands of frames in less than a second.

Again, this is thanks to the fact that Matlab and Octave are already heavily optimized to work with matrices and arrays, 
meaning that once we got all our data in the correct format, we got this speedup "for free".


