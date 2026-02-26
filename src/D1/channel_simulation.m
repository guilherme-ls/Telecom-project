function [frame_bits] = channel_simulation(m_c_total, N0, modulation, M, c, N, equalizer)
    %% Symbol generation
    s = reshape(bits2symbols(m_c_total(:), modulation, M), N, []);
    %%%% Channel model with noise %%%%
    noise = sqrt(N0/2) * (randn(size(s, 1),size(s, 2)) + 1i*randn(size(s, 1),size(s, 2)));
    if c == 0
        H = eye(N);
    else
        h = response_channel(c);
        L = (length(h) - 1) / 2;
        H = toeplitz([h(1 + L) fliplr(h(1:L)) zeros(1,N - L - 1)], [h(1 + L: 2*L) zeros(1,N - L)]);
    end
    y = zeros(size(s, 1), size(s,2));
    y(1:end, :) = H*s(1:end, :) + noise(1:end, :);
    %%%% Receiver and symbol detection
    %%%%%% Symbol Equalization
    if strcmp(equalizer, "ZF")
        y_eq = pinv(H) * y(1:end, :);
        [s_hat, ~] = reshape(threshold_detector(y_eq(:), modulation, M), N, []);
    elseif strcmp(equalizer, "DFE")
        [Q,R] = qr(H);
        z = Q' * y;
        s_hat = zeros(N, size(s, 2));
        for ii = N:-1:1
            y_eq = (z(ii, :) - R(ii,ii+1:N) * s_hat(ii+1:N, :)) / R(ii,ii);
            [s_hat(ii, :), ~] = threshold_detector(y_eq, modulation, M);
        end
    else
        y_eq = y;
        [s_hat, ~] = reshape(threshold_detector(y_eq(:), modulation, M), N, []);
    end
    %%% TODO symbols2bits is taking the majority of the simulation simulation time 
    %%%% Maybe we can refactor it to make it faster? Depends on what is making it 
    %%%% slow in the first place
    frame_bits = reshape(symbols2bits(s_hat(:), modulation, M)', N*log2(M), []);
end
