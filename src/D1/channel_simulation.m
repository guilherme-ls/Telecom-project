function [err, err_bits] = channel_simulation(m, g, t, syndrome_table, N0, modulation, M)
    %%%% BCH code encoding %%%
    m_c = bch_coder(m, g);
    
    %%%% BPSK Symbol generation %%%
    
    x = bits2symbols(m_c,modulation,M);
    %%%% Channel model with noise %%%%
    
    noise = N0 * randn(length(x),1);
    y = x + noise;
    %%%% BPSK Receiver and symbol detection
    
    %%%%% Symbol Decoding
    
    [s_hat, loc] = threshold_detector(y,modulation,M);
    
    m_c_hat = symbols2bits(s_hat,modulation,M)';
    %%%% BCH Code decoding %%%
    
    [m_hat, err] = bch_decoder(m_c_hat, g, t, syndrome_table);
    
    %%%% Total amount of error bits
    
    err_bits = sum(mod(m_hat + m, 2));
    
    %fprintf("Received message = %s\n", mat2str(m_hat));
    %if sum(err) != 0
    %  fprintf("Error found e = %s\n", mat2str(err));
    %else
    %  fprintf("No errors!\n");
    %end
    %
    %fprintf("%d error bits!\n", err_bits);
end
