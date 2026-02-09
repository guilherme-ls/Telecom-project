%%%%% bch_mod_g %%%%%
%%%%% Arguments:
%%%%% - m : Column vector representation of the m(x) polynimial
%%%%% - g : Column vector representation of the g(x) polynomial
%%%%% Return:
%%%%% - m_mod : Column vector representation of the result m(x) mod g(x)
function [m_mod] = bch_mod_g(m, g)
    m(1:length(m)) = m(end:-1:1); %% Reversing m(x) so it gets correctly shifted into the shift registers
    
    g_deg = size(g,1);
    m_mod = zeros(g_deg-1, 1); %% m(x) mod g(x)
    for ii=1:length(m)
        m_mod_prev = m_mod;
        m_mod(1) = mod(m(ii) + g(1) * m_mod_prev(g_deg-1), 2); %% First element of the shift register
        for jj=2:g_deg-2
            m_mod(jj) = mod(m_mod_prev(jj - 1) + g(jj) * m_mod_prev(g_deg-1), 2);
        end
        m_mod(g_deg-1) = m_mod_prev(g_deg - 2); %% Last element of the shift register
    end
end
