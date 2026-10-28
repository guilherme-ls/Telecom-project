function [P_dBm] = minimum_power(photo_detector)

S = photo_detector.sensitivity;
Be = photo_detector.electrical_bw;
Rload = photo_detector.r_load;
n_th = photo_detector.n_th;

Q = 4.75; % for 10^-6 error rate
noise_factor = n_th * Be / Rload;

P_lin = 2 * Q / S * sqrt(noise_factor);

P_dBm = 10 * log10(P_lin * 1000);

end