function [cir1_interp,  cir2_interp, cir1_toa_angle, cir2_toa_angle] = lineUpCIRs(in_cir1, in_cir2, INTERP_SIZE)

cir_len = length(in_cir1);

%interpolate the CIRs
in_cir1_fft = fft(in_cir1);
in_cir2_fft = fft(in_cir2);
in_cir1_fft_windowed = in_cir1_fft.*fftshift(hamming(cir_len));
in_cir2_fft_windowed = in_cir2_fft.*fftshift(hamming(cir_len));
in_cir1_fft_interp = [in_cir1_fft_windowed(1:cir_len/2); ...
    zeros(INTERP_SIZE-cir_len,1); ...
    in_cir1_fft_windowed(cir_len/2+1:end)];
in_cir2_fft_interp = [in_cir2_fft_windowed(1:cir_len/2); ...
    zeros(INTERP_SIZE-cir_len,1); ...
    in_cir2_fft_windowed(cir_len/2+1:end)];
cir1_interp = ifft(in_cir1_fft_interp);
cir2_interp = ifft(in_cir2_fft_interp);

%Poor man's ToA estimation: First above threshold
TOA_THRESH = 0.1;
cir1_toa = find(abs(cir1_interp) > max(abs(cir1_interp))*TOA_THRESH);
cir1_toa = cir1_toa(1);
cir2_toa = find(abs(cir2_interp) > max(abs(cir2_interp))*TOA_THRESH);
cir2_toa = cir2_toa(1);

%Subtract phase of ToA
cir1_toa_angle = angle(cir1_interp(cir1_toa));
cir2_toa_angle = angle(cir2_interp(cir2_toa));
cir1_interp = cir1_interp * exp(-1i*cir1_toa_angle);
cir2_interp = cir2_interp * exp(-1i*cir2_toa_angle);

%Put ToA at t=0
cir1_interp = circshift(cir1_interp, -cir1_toa);
cir2_interp = circshift(cir2_interp, -cir2_toa);