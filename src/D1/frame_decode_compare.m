function [errors] = frame_decode_compare(m_total, frame_bits, g, t, syndrome_table, n, k)
    %% Symbol Decoding
    number_bits = length(frame_bits); % number of bits in a frame
    n_words = floor(number_bits / n);
    m_total_hat = zeros(n_words * k,1);

    %% Separates bits into words and decode them
    for ii = 1:n_words
        m_c_hat = frame_bits((ii-1)*n + 1:ii * n);

        %% BCH code decoding
        if t ~= 0
            [m_hat, ~] = bch_decoder(m_c_hat, g, t, syndrome_table);
        else
            m_hat = m_c_hat;
        end

        m_total_hat((ii-1)*k + 1:ii * k) = m_hat;
    end

    %%%% Total amount of error bits
    
    errors = sum(mod(m_total_hat + m_total, 2)) / length(m_total);
end
