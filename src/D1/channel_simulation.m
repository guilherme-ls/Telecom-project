function [frame_bits] = channel_simulation(m_c_total, N0, modulation, M, c, N, equalizer)
    %% Symbol generation
    s = bits2symbols(m_c_total, modulation, M);

    %%%% Channel model with noise %%%%
    noise = sqrt(N0/2) * (randn(length(s),1) + 1i*randn(length(s),1));
    
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
        [s_hat, ~] = threshold_detector(y_eq, modulation, M);
    elseif strcmp(equalizer, "DFE")
        [Q,R] = qr(H);
        z = Q' * y;
        s_hat = zeros(N,1);
        for ii = N:-1:1
            y_eq = (z(ii) - R(ii,ii+1:N) * s_hat(ii+1:N)) / R(ii,ii);
            [s_hat(ii), ~] = threshold_detector(y_eq, modulation, M);
        end
    else
        y_eq = y;
        [s_hat, ~] = threshold_detector(y_eq, modulation, M);
    end

    frame_bits = symbols2bits(s_hat, modulation, M)';
end
