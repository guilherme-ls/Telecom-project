%%%%% Frame Generation %%%%%%
%%%%% Arguments:
%%%%% - n : The size of the coded word. 
%%%%% - k : The size of the message. 
%%%%% - g : Vector with the polynomial coeficients of the BCH code . 
%%%%% - M : Size of the modulation constellation. 
%%%%% - frame_size : Amount of symbols in the frame. 
%%%%% - frame_number : Amount of frames to generate. 
%%%%% - bch_code_option : Selects BCH encoding. 
%%%%% Return:
%%%%% - m_total : Vector with the messages generated. If frame_number is more than 1, m_total is a matrix with size(m_total, 2) = frame_number, where each column are the messages generated for each frame. 
%%%%% - m_c_total : Vector with the codded generated messages. If frame_number is more than 1, m_c_total is a matrix with size(m_c_total, 2) = frame_number, where each column are the coded messages generated for each frame.
function [m_c_total, m_total] = frame_generation(n, k, g, M, frame_size, frame_number, bch_code_option)
    number_bits = log2(M) * frame_size; % number of bits in a frame
    n_words = floor(number_bits / n); % number of words in a frame
    m_c_total = zeros(number_bits, frame_number);
    m_total = zeros(n_words * k, frame_number);

    %% Creates the necessary amount of words to fill a frame
    
    m = randi([0 1], k, n_words * frame_number);
    %% BCH code encoding
    if bch_code_option ~= 0
        m_c = reshape(bch_coder(m, g), n_words * n, frame_number);
    else
        m_c = reshape(m, n_words * k, frame_number);
    end
    m_c_total(1:size(m_c, 1), :) = m_c;
    m_total = reshape(m, n_words * k, frame_number);
end
