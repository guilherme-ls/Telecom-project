%%%%% Channel Simulation %%%%%%
%%%%% Arguments:
%%%%% - m_c_total : Vector with the coded message in a frame. If it is a matrix, size(m_c_total, 2) is executed in parallel. 
%%%%% - N0 : Variance^2 of the Guassian noise. 
%%%%% - modulation : String with the modulation to be used. Check bits2symbols for details on supported modulations. 
%%%%% - M : Constellation size of the modulation to be used. Check bits2symbols for details on supported modulation sizes. 
%%%%% - c : The channel to be used. 0 is a channel without IES, meanwhile 1-3 have different responses. Check response_channel for details on the different available channels. 
%%%%% - N : The amount of symbols in the frame. 
%%%%% - equalizer : String with the equalizer to be used. Can be either 'ZF', 'DFE', or something else ('none') for no equalization.. 
%%%%% Return:
%%%%% - frame_bits : Vector with the received frame after demodulation. It is also a matrix if m_c_total is one, with size(frame_bits, 2) = size(m_c_total, 2). 
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
        %% TODO This is the next bottleneck, might not be solvable
        for ii = N:-1:1
            y_eq = (z(ii, :) - R(ii,ii+1:N) * s_hat(ii+1:N, :)) / R(ii,ii);
            [s_hat(ii, :), ~] = threshold_detector(y_eq, modulation, M); 
        end
    else
        y_eq = y;
        [s_hat, ~] = reshape(threshold_detector(y_eq(:), modulation, M), N, []);
    end
    frame_bits = reshape(symbols2bits(s_hat(:), modulation, M)', N*log2(M), []);
end
