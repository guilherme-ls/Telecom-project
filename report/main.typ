#import "template.typ": project

#import "@preview/equate:0.3.2": equate
#import "@preview/lilaq:0.5.0" as lq

// LTeX: language=en-US
// LTeX: statusBatItem=true 
//
#show: equate.with(breakable: true, sub-numbering: false)
#set math.equation(numbering: "(1.1)")

// Ploting semilog from csv function
//#let (bpsk_0_x, bpsk_0_y) = lq.load-txt(read("./graphs/bpsk-0.csv"))

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
    caption: [Transmitter and receiver chain.]
  ) <chanel>

  The channel coding will be done through two distinct BCH codes, correcting $t=1$ and $t=2$ errors respectively. Each implemented code will have a length of $N_c = 31$ and be defined considering the Galois Field extension $"GF"(32)= "GF"(2)[x]"/"1+x^2+x^5$. Both codes will adopt the systematic form to facilitate decoding 

  In terms of the transmission channel, we consider that the transmitted symbols $s(n)$ will be linearly modulated according @eq:input_filter, where $g(n)$ is the shaping filter satisfying the square-root Nyquist condition and $T_s$ is the symbol period.

  $ x(t) = sum_n s(n) g(t-n T_s) $ <eq:input_filter>

  On the reception side, after sampling the received signal at $1"/"T_s$ intervals and performing some mathematical simplifications, it can be described by @eq:received_signal, where *H* is a Toeplitz matrix representing the frequency selective channel and *w* is the Gaussian noise.
  
  $ bold("z") = bold("H s") + bold("w") $ <eq:received_signal>

  Based on the described system, we perform in this report a simulation and evaluation of its performance considering different codes, channels and modulations, discussing the employed methods and the obtained results.

= System Simulation

== BCH Implementation

 Two distinct BCH codes will be implemented in this section, both in the $"GF"(32)$ extension field, correcting $t=1$ and $t=2$ errors respectively.

=== Determining the Generator Polynomials and Code Rates

  To implement the desired BCH codes we must first determine their corresponding generator polynomials. For a given number of errors $t$ that the BCH code must correct, its generator polynomial must have $2t$ consecutive roots $alpha^i$ ($i = 1...t$), powers of the primitive element $alpha$ and also roots of $x^(31)-1$. For each root $alpha^i$ there is a corresponding minimal polynomial $mu_(alpha^i) (x)$, and $g(x)$ will be given by lowest common multiplier between the minimal polynomials of its roots:

  $ g(x) = L C M(mu_(alpha^1)(x), ..., mu_(alpha^(2t))(x) ) $

  Therefore, starting with the code capable of correcting one error, $g(x)$ must have as roots ${alpha^1, alpha^2}$. To determine the corresponding minimal polynomials, we must highlight the fact that a power of two of a root is also root, and that $alpha^(32) = alpha$. This lets us describe the minimal polynomial $mu_(alpha^1)(x)$ in @eq:primitive_poly and show that both $alpha^1$ and $alpha^2$ will have the same minimal polynomial.

  $ mu_(alpha^1) (x) = (alpha - 1)(alpha^2 - 1)(alpha^4 - 1)(alpha^8 - 1)(alpha^16 - 1) = mu_(alpha^2) (x) $ <eq:primitive_poly>

  To find its value, we must notice that $alpha$ is one of the roots of the primitive polynomial of the $"GF"(32)$ extension field, which in our case is $1+x^2+x^5$. Therefore, we conclude that $mu_(alpha^1) (x) = mu_(alpha^2) (x) = 1+x^2+x^5$.

  Thus according to the previously stated theory, the LCM of both polynomials gives us $g(x) = 1+x^2+x^5$. Now to calculate the code's efficiency, we must first determine its length $n$ and dimension $k$. The length will be given by $n=2^m-1$, where $m=5$ for $"GF"(32)$, leading to $n=31$. Concerning the dimension, a fundamental property of cyclic codes tells us that for each to be unique the equality $d^o g(x) = n - k$ must hold. Since $d^o g(x) = 5$ for the first BCH code, its dimension must be $k = 26$. Finally, the code rate for the BCH code where $t=1$ will be $R=26"/"31$.

  We now proceed with the second code. It is capable of correcting $t=2$ errors, such that the roots of its generator polynomial will be ${alpha^1, alpha^2, alpha^3, alpha^4}$. From @eq:primitive_poly we conclude that $mu_(alpha^1) (x) = mu_(alpha^2) (x)= mu_(alpha^4) (x) = 1+x^2+x^5$. @eq:primitive_poly3 shows $mu_(alpha^3) (x)$.

  $ mu_(alpha^3) (x) &= (alpha^3 - 1)(alpha^6 - 1)(alpha^12 - 1)(alpha^24 - 1)(alpha^17 - 1) #<equate:revoke> \
  &= 1 + x + x^2 + x^3 + x^4 + x^5 $ <eq:primitive_poly3>

  Therefore, we get that the generator polynomial is $g(x) = x^(10) + x^9 + x^8 + x^6 + x^5 + x^3 + 1$. From this, we can again deduce that the code length is $n = 2^m - 1 = 31$ and its dimension is $k = n - d^o g(x) = 21$. Thus, the code rate for the BCH code capable of correcting $t=2$ errors is $R=21"/"31$.

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
    m(1:length(m)) = m(end:-1:1); % Reversing m(x)
    g_deg = size(g,1) - 1;
    m_mod = zeros(g_deg, 1); % m(x) mod g(x)
    for ii=1:length(m)
        m_mod_prev = m_mod;
        m_mod(1) = mod(m(ii) + g(1) * m_mod_prev(g_deg), 2);
        for jj=2:g_deg
            m_mod(jj) = mod(m_mod_prev(jj - 1) + g(jj) ...
              * m_mod_prev(g_deg), 2);
        end
    end
  end
  ```

  For the generation of the coded word $c(x)$, we inserted the shifted information word $x^(n-k)m(x)$ in the encoder to get the parity bits, and them built a vector of size $n=31$ by concatenating first the parity bits and them the information word $m(x)$. This finalizes the coding operation.

  ```matlab
  g_deg = length(g);
  shifted_m = [zeros(g_deg - 1, 1); m]; % m(x) shifted by n - k 
  parity_bits = bch_mod_g(shifted_m, g);
  y = [parity_bits; m];
  ```

  We highlight that the encoder depends on $g(x)$ and is therefore distinct for each code.

=== Implementing Optimal ML Decoding

  Under a theoretical Binary Symmetric Channel (BSC) hypothesis, one can show that the optimal ML decoding consists in minimizing the Hamming distance between the sent $c(x)$ and received $r(x)$ messages, which is equivalent to minimizing the Hamming weight of the error $e(x)$ added to the received message ($R(x) = c(x) + e(x)$).

  In practice, this decoding is done through syndromes, which in the case of cyclic codes consists in the modulo $g(x)$ of the received message $r(x)$ (Equation @eq:syndrome1). 

  $ s(x) = r(x)"mod"g(x) $ <eq:syndrome1>
  
  Since the received message is given in function of the sent message and some error ($r(x) = c(x) + e(x)$) and the sent message is a multiple of $g(x)$ ($c(x)"mod"g(x) = 0$), we can show that the syndrome is directly related to the modulo of the error (@eq:mod_error).

  $ s(x) = c(x)"mod"g(x) + e(x)"mod"g(x) = e(x)"mod"g(x) $ <eq:mod_error>

  Therefore, to each syndrome we can relate an error polynomial of minimal weight that generates it, which can be stored in a look-up table. And for correcting the errors in $r(x)$, one can simply sum the error $e(x)$ corresponding to its syndrome, letting us recuperate $c(x)$ (this is valid because each polynomial coefficient belongs to $"GF"(2)$).

  In the code, we first implement the syndrome look-up table, going through all the error polynomials possible for $t=1$ and $t=2$ errors, depending on the BCH code, and calculating the respective syndrome using the modulo operation previously implemented in the encoder. Each pair error-syndrome is then saved in memory.

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

  One important observation is that for the case of the BCH code where $t=2$ there are more syndromes than error polynomials with 1 and 2 errors, implying that some possible syndromes would lead to polynomials with 3 or more errors. However, since the code is not consistently capable of correcting more than 2 errors, we chose to ignore these syndromes and employ a default case where we do not correct any errors.

  The decoder itself is then implemented as a code that first calculates the syndrome of the received message through the previous modulo function and finds the respective error in the syndrome look-up table. Then it sums the error to the received message bit by bit to get the original coded message. Ta finalize the decoding, since the systematic encoding is being employed, we remove the parity bits at the start of the message to leave only the information bits.

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

  With all the BCH coding aspects implemented, we now use the code provided to build the modulation and demodulation systems and to simulate the transmission channel itself.

  Discuss asymptotic gain.

== Frequency Selective Channels

=== Implementation


=== BER Plots and Discussions

  Suggested analysis.

  Mention that ZF for non-unitary H matrices increases noise.
  
  Mention that DFE does not increase noise, but if you make a bad decision on a symbol at the start the error will be compounded throughout the demodulation.

//#figure(
//  lq.diagram(
//    width: 15cm,
//    height: 10cm,
//    lq.plot(bpsk_0_x, bpsk_0_y, label: [BPSK $alpha = 0%$],
//            mark: "x", stroke:(thickness: 1pt, dash: "solid")),
//      title: [BER / $"SNR"_b$ for not coded OFDM.], 
//    yscale: "log",
//    ylabel: [BER],
//    xlabel: [$E_b / N_0$],
//    xaxis: (subticks: none),    
//    legend: (position: right + top)
//  ),
//  caption: [Plot of the BER versus the SNR per bit in a semilog scale for a BPSK and a 4-QAM
//  constellation for different values of $alpha in {0, 0.25, 0.5, 0.75}$ in the studied system using 
//  an OFDM with $N_("carriers") = 64$ and $N_("prefix") = 1$.],
//
//) <OFDM-not-coded>
