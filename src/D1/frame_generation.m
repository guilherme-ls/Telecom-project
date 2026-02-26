function [m_c_total, m_total] = frame_generation(n, k, g, M, frame_size, bch_code_option)
    number_bits = log2(M) * frame_size; % number of bits in a frame
    n_words = floor(number_bits / n); % number of words in a frame
    m_c_total = zeros(number_bits,1);
    m_total = zeros(n_words * k,1);

    %% Creates the necessary amount of words to fill a frame
    for ii = 1:n_words
        m = randi([0 1], k, 1);

        %% BCH code encoding
        if bch_code_option ~= 0
            m_c = bch_coder(m, g);
        else
            m_c = m;
        end

        %% Stores coded and non-coded words
        m_c_total((ii-1)*n + 1:ii * n) = m_c;
        m_total((ii-1)*k + 1:ii * k) = m;
    end
end
