%%%%% Frame Decoding and Comparison %%%%%%
%%%%% Arguments:
%%%%% - m_total : Vector with the expected message of the frame sent. If it is a matrix, size(m_total, 2) is executed in parallel. 
%%%%% - frame_bits : Vector with the coded message of a received frame. If it is a matrix, size(frame_bits, 2) is executed in parallel. 
%%%%% - g : Vector with the polynomial coeficients of the BCH code . 
%%%%% - t : Amount of errors that the BCH code can fix. 
%%%%% - syndrome_table : The syndrome table of the BCH code. 
%%%%% - n : The size of the coded word. 
%%%%% - k : The size of the message. 
%%%%% Return:
%%%%% - errors_per_frame : Vector with the amount of error for each frame compared. 
%%%%% - errors_per_bit : Value of the BER of all the compared frames. 
%%%%% - amount_of_errors : Vales of the amount of bit errors in total. 
function [errors_per_frame, errors_per_bit, amount_of_errors] = frame_decode_compare(m_total, frame_bits, g, t, syndrome_table, n, k)
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
    m_hat = reshape(m_hat, [], size(frame_bits, 2));
    errors_per_frame = sum(mod(m_hat + m_total, 2), 1);
    amount_of_errors = sum(errors_per_frame);
    errors_per_bit = amount_of_errors / length(m_total(:));
end
