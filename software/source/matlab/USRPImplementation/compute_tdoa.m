function ret = compute_tdoa(direct_cir, backscatter_cir)

%super-resolution backscatter CIR
backscatter_cir_fft = fft(backscatter_cir);
backscatter_cir_fft_padded = [backscatter_cir_fft(1:length(backscatter_cir_fft)/2);zeros(length(backscatter_cir_fft)*9,1);backscatter_cir_fft(length(backscatter_cir_fft)/2+1:end)];
backscatter_cir_padded = abs(ifft(backscatter_cir_fft_padded));
backscatter_cir_padded = backscatter_cir_padded./abs(max(backscatter_cir_padded));

%super-resolution direct CIR
direct_cir_fft = fft(direct_cir);
direct_cir_fft_padded = [direct_cir_fft(1:length(direct_cir_fft)/2);zeros(length(direct_cir_fft)*9,1);direct_cir_fft(length(direct_cir_fft)/2+1:end)];
direct_cir_padded = abs(ifft(direct_cir_fft_padded));
direct_cir_padded = direct_cir_padded./abs(max(direct_cir_padded));

%Need to eventually change indices to lengths
cir_dists = (0:length(direct_cir_padded)-1)*.2449/10;

%rotate everything so that the toa is around 25% through the CIR
desired_toa_idx = floor(length(direct_cir_padded)/4);
first_above_idx = find(direct_cir_padded > 0.3,1);
direct_cir_padded = circshift(direct_cir_padded,-first_above_idx);
direct_cir_padded = circshift(direct_cir_padded,desired_toa_idx);
backscatter_cir_padded = circshift(backscatter_cir_padded,-first_above_idx);
backscatter_cir_padded = circshift(backscatter_cir_padded,desired_toa_idx);

%Now calculate the TDoA
first_direct_above_time = cir_dists(find(direct_cir_padded > 0.3,1));
first_backscatter_above_time = cir_dists(find(backscatter_cir_padded > 0.3,1));

ret = first_backscatter_above_time - first_direct_above_time;
