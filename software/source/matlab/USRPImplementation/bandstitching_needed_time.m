function [sample_limit] = bandstitching_needed_time(exp_folder, cal_folder, from, to)

in_header_filename     = [exp_folder,'/',from,'/','header_',to,'.csv'];
in_data_filename       = [exp_folder,'/',from,'/','data_',to,'.dat'];
in_cal_header_filename = [cal_folder,'/',from,'/','header_',to,'.csv'];
in_cal_data_filename   = [cal_folder,'/',from,'/','data_',to,'.dat'];
out_image_prefix       = [exp_folder,'/',from,'/','result_',to];

VALID_MEAS_START_IDX = 100;
CAL_VALID_MEAS_START_IDX = 100;
SAMPLE_RATE = 25e6;
ACCUM_COUNT = 1e3;
TAG_FREQ = 256.064;
TAG_FREQ_PPM_ACCURACY = 1000e-6;

[cal_data, cal_data_times] = readUSRPData(in_cal_header_filename,in_cal_data_filename, SAMPLE_RATE, ACCUM_COUNT);
cal_data = cal_data(:,CAL_VALID_MEAS_START_IDX:end-CAL_VALID_MEAS_START_IDX,:,:);

%For now, let's just use the last bandstitching sweep...
cal_data = cal_data(:,:,:,end);
cal_data = squeeze(sum(cal_data,2));
cal_data_fft = fft(cal_data,[],1);

[overair_data, overair_data_times] = readUSRPData(in_header_filename,in_data_filename, SAMPLE_RATE, ACCUM_COUNT);
overair_data = overair_data(:,VALID_MEAS_START_IDX:end-VALID_MEAS_START_IDX,:,:);
overair_data_times = overair_data_times(VALID_MEAS_START_IDX:end-VALID_MEAS_START_IDX,:,:);

sample_limit = 0;

figure(1);
clf();
figure(21);
clf();
figure(42);
clf();
figure(44);
clf();

%In order to locate the backscatter tag, we need to search across <tag_freq,quadrature_phase>
tag_freq_search_space = -TAG_FREQ_PPM_ACCURACY:100e-6:TAG_FREQ_PPM_ACCURACY;

noise_cfr = zeros(size(overair_data,3)*10,1);
noise_cir = zeros(size(overair_data,3)*100,1);
cfr_snr = [];
cir_snr = [];
deconvolved_fft_best = zeros(size(overair_data,1)/2,size(overair_data,3));

SAMPLE_LIMIT_STEP = 1250;
sample_limit = 1;
while sample_limit < length(overair_data)
  disp(['sample_limit=',num2str(sample_limit),' (',num2str(sample_limit/1250),' seconds)'])

  % shorten sample
  data = overair_data(:,1:sample_limit,:);
  data_times = overair_data_times(1:sample_limit,:);

  [deconvolved, deconvolved_direct, tag_freq_search_corr] = bandstitching_onezero(cal_data_fft, data, data_times,tag_freq_search_space,TAG_FREQ);

  best_cfr = 20*log10(mean(max(tag_freq_search_corr,[],1),3));
  [pks,locs] = findpeaks(best_cfr);


  %baseline noise with too little integration
  if noise_cfr(1) == 0
    noise_cfr = deconvolved;
  else
    cfr_snr = [cfr_snr, snr(deconvolved, noise_cfr)]
    figure(50);
    plot(cfr_snr);
    title('CFR SNR');
  end


  %super-resolution backscatter CIR
  backscatter_cir_fft = fft(deconvolved);
  backscatter_cir_fft_padded = [backscatter_cir_fft(1:length(backscatter_cir_fft)/2);zeros(length(backscatter_cir_fft)*9,1);backscatter_cir_fft(length(backscatter_cir_fft)/2+1:end)];
  backscatter_cir_padded = abs(ifft(backscatter_cir_fft_padded));
  backscatter_cir_normed = backscatter_cir_padded./abs(max(backscatter_cir_padded));

  %super-resolution direct CIR
  direct_cir_fft = fft(deconvolved_direct);
  direct_cir_fft_padded = [direct_cir_fft(1:length(direct_cir_fft)/2);zeros(length(direct_cir_fft)*9,1);direct_cir_fft(length(direct_cir_fft)/2+1:end)];
  direct_cir_padded = abs(ifft(direct_cir_fft_padded));
  direct_cir_normed = direct_cir_padded./abs(max(direct_cir_padded));

  %Need to eventually change indices to lengths
  cir_dists = (0:length(direct_cir_normed)-1)*.2449/10;

  %rotate everything so that the toa is around 25% through the CIR
  desired_toa_idx = floor(length(direct_cir_normed)/4);
  first_above_idx = find(direct_cir_normed > 0.3,1);
  direct_cir_normed = circshift(direct_cir_normed,-first_above_idx);
  direct_cir_normed = circshift(direct_cir_normed,desired_toa_idx);
  backscatter_cir_normed = circshift(backscatter_cir_normed,-first_above_idx);
  backscatter_cir_normed = circshift(backscatter_cir_normed,desired_toa_idx);

  %Now calculate the TDoA
  first_direct_above_time = cir_dists(find(direct_cir_normed > 0.3,1))
  first_backscatter_above_time = cir_dists(find(backscatter_cir_normed > 0.3,1))
  tdoa = first_backscatter_above_time - first_direct_above_time

  figure(21);
  hold on;
  plot(abs(backscatter_cir_fft))
  title('Backscatter CIR FFT (CFR)')
  hold off;

  figure(42);
  hold on;
  plot(abs(backscatter_cir_padded))
  title('Backscatter CIR over time')
  hold off;
  figure(43);
  plot(abs(backscatter_cir_normed))
  title('Backscatter CIR (normed)')

  figure(44);
  hold on;
  plot(abs(direct_cir_padded))
  title('Direct CIR over time')
  hold off;
  figure(45);
  plot(abs(direct_cir_normed))
  title('Direct CIR (normed)')


  %baseline noise with too little integration
  if noise_cir(1) == 0
    noise_cir = backscatter_cir_padded;
  else
    cir_snr = [cir_snr, snr(backscatter_cir_padded, noise_cir)]
    figure(51);
    plot(cir_snr);
    title('CIR SNR');
  end

  %if sample_limit > 10000
  %  keyboard;
  %end

  sample_limit = sample_limit + SAMPLE_LIMIT_STEP;
end

keyboard;
