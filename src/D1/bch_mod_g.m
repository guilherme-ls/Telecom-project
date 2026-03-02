%%%%% bch_mod_g %%%%%
%%%%% Arguments:
%%%%% - m : Column vector representation of the m(x) polynimial
%%%%%       If m is a matrix, its size(m, 2) will be executed in parallel 
%%%%% - g : Column vector representation of the g(x) polynomial
%%%%% Return:
%%%%% - m_mod : Column vector representation of the result m(x) mod g(x)
%%%%%       If m is a matrix, m_mod will be a matrix with size(m_mod, 2) = size(m, 2)
function [m_mod] = bch_mod_g(m, g)
    m(1:end, :) = m(end:-1:1, :); % Reversing m(x) so it gets correctly shifted into the shift registers
    
    g_deg = size(g, 1) - 1;
    m_mod = zeros(g_deg, size(m, 2)); %% m(x) mod g(x)
    for ii=1:size(m, 1)
        % Perform the shift in m_mod
        shifted_temp = circshift(m_mod, 1);
        
        % Use the temporary variable to perform the feedback step and add new entry
        m_mod = [m(ii, :); shifted_temp(2:end, :)] + m_mod(g_deg, :) .* g(1:g_deg);
    end
    m_mod = mod(m_mod, 2);
end
