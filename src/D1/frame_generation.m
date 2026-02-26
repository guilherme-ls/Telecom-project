function [m_c_total, m_total] = frame_generation(n, k, g, M, frame_size, bch_code_option)
    number_bits = log2(M) * frame_size; % number of bits in a frame
    n_words = floor(number_bits / n); % number of words in a frame
    m_c_total = zeros(number_bits, 1);
    m_total = zeros(n_words * k, 1);

    %% Creates the necessary amount of words to fill a frame
    
    m = randi([0 1], k, n_words);
    %% BCH code encoding
    if bch_code_option ~= 0
        m_c = resize(bch_coder(m, g), n_words * k, 1);
    else
        m_c = resize(m, n_words * k, 1);
    end
    m_c_total(1:size(m_c, 1)) = m_c;
    m_total = resize(m, n_words * k, 1);
end
