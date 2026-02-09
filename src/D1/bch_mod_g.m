function [m_mod] = bch_mod_g(m, g)
    m_rev = zeros(length(m), 1);
    m_rev(1:length(m)) = m(end:-1:1);
    
    g_deg = size(g,1);
    m_mod = zeros(g_deg-1, 1);
    for ii=1:length(m)
        m_mod_prev = m_mod;
        m_mod(1) = mod(m_rev(ii) + g(1) * m_mod_prev(g_deg-1), 2);
        for jj=2:g_deg-2
            m_mod(jj) = mod(m_mod_prev(jj - 1) + g(jj) * m_mod_prev(g_deg-1), 2);
        end
        m_mod(g_deg-1) = m_mod_prev(g_deg - 2);
    end
end
