function [err, err_bits] = channel_simulation(m, g, t, syndrome_table, N0, modulation, M, c, N, equalizer)
    %%%% BCH code encoding %%%
    m_c = bch_coder(m, g);
    
    %%%% BPSK Symbol generation %%%
    
    x = bits2symbols(m_c,modulation,M);
    
    %%%% Frame generation %%%
    
    s = zeros(N,1);
    s(1:length(x)) = x;

    %%%% Channel model with noise %%%%
    noise = N0 * randn(length(s),1); %% Channel 0
    
    if c == 0
      H = eye(N);
    else
      h = response_channel(c);
      L = (length(h) - 1) / 2;
      H = toeplitz([h(1 + L) fliplr(h(1:L)) zeros(1,N - L - 1)], [h(1 + L: 2*L) zeros(1,N - L)]);
    end
    y = H*s + noise;
    
    %%%% Receiver and symbol detection
    %%%%%% Symbol Equalization
    if strcmp(equalizer, "ZF")
       y_eq = pinv(H) * y;
    elseif strcmp(equalizer, "DFE")
       [Q,R] = qr(H);
       z = Q' * y;
       y_eq = linsolve(R, z);
    else
      y_eq = y;
    end
    
    %%%%% Symbol Decoding
    [s_hat, loc] = threshold_detector(y_eq,modulation,M);
    s_hat_frame = s_hat(1:length(x));
    m_c_hat = symbols2bits(s_hat_frame,modulation,M)';
    %%%% BCH Code decoding %%%
    
    [m_hat, err] = bch_decoder(m_c_hat, g, t, syndrome_table);
    
    %%%% Total amount of error bits
    
    err_bits = sum(mod(m_hat + m, 2));
end
