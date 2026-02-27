function [errors, errors_per_bit] = frame_decode_compare(m_total, frame_bits, g, t, syndrome_table, n, k)
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
    errors = sum(mod(m_hat(:) + m_total(:), 2));
    errors_per_bit = errors / length(m_total);
end
