function [sample_limit] = bandstitching_needed_time(exp_folder, cal_folder, from, to, TAG_FREQ)

in_header_filename     = [exp_folder,'/',from,'/','header_',to,'.csv'];
in_data_filename       = [exp_folder,'/',from,'/','data_',to,'.dat'];
in_cal_header_filename = [cal_folder,'/',from,'/','header_',to,'.csv'];
in_cal_data_filename   = [cal_folder,'/',from,'/','data_',to,'.dat'];
out_image_prefix       = [exp_folder,'/',from,'/','result_',to];
out_cirs               = [exp_folder,'/',from,'/','cirs_',to,'.mat'];

VALID_MEAS_START_IDX = 100;
CAL_VALID_MEAS_START_IDX = 100;
SAMPLE_RATE = 25e6;
ACCUM_COUNT = 1e3;
%TAG_FREQ = 256.0630;
TAG_FREQ_PPM_ACCURACY = 300e-6;

[cal_data, cal_data_times] = readUSRPData(in_cal_header_filename,in_cal_data_filename, SAMPLE_RATE, ACCUM_COUNT);
cal_data = cal_data(:,CAL_VALID_MEAS_START_IDX:end-CAL_VALID_MEAS_START_IDX,:,:);

%For now, let's just use the last bandstitching sweep...
cal_data = cal_data(:,:,:,end);
cal_data = squeeze(sum(cal_data,2));
cal_data_fft = fft(cal_data,[],1);

[overair_data, overair_data_times] = readUSRPData(in_header_filename,in_data_filename, SAMPLE_RATE, ACCUM_COUNT);
overair_data = overair_data(:,VALID_MEAS_START_IDX:end-VALID_MEAS_START_IDX,:,:);
overair_data_times = overair_data_times(VALID_MEAS_START_IDX:end-VALID_MEAS_START_IDX,:,:);

%Have an experiment where we lost the last few bands, cut off cal to match
if size(overair_data,3) ~= size(cal_data,2)
  cal_data = cal_data(:,1:size(overair_data,3));
  cal_data_fft = cal_data_fft(:,1:size(overair_data,3));
  cal_data_times = cal_data_times(:,1:size(overair_data,3));
end

sample_limit = 0;

figure(1);
clf();
%figure(21);
%clf();
figure(42);
clf();
figure(44);
clf();
figure(53);
clf();

%In order to locate the backscatter tag, we need to search across <tag_freq,quadrature_phase>
%tag_freq_search_space = -TAG_FREQ_PPM_ACCURACY:50e-6:TAG_FREQ_PPM_ACCURACY;
%
%pre-calc as it's faster
%TAG_FREQ = 256.0630
%
% 30->20
% 01 256.0630
% 02 256.0627
% 03 256.0627
% 04 256.0695
% 05 256.0630
% 06 256.0630
% 07 256.0627
% 08 256.062975
% 09 256.06315
% 10 256.06315
% 11 256.06300
% 12 256.063075
% 13 256.06270
% 13 256.06285
% 14 256.06285
% 15 256.06285
%
% 20->30
% 01 256.06300
% 02 256.06290
% 03 256.06300
% 04 256.06290
% 05 256.06290
% 06 256.06285
% 07 256.06300
% 08 256.06300
% 09 256.06270
% 10 256.06270 - broken?
% 11 256.06270 - direct CIR is crap?
% 12 256.06270
% 13 256.06270
% 14 256.06270
% 15 256.06255
%
% 30->20 NLOS
% 01 256.06285
% 05 256.06285
% 10 256.06285
% 15 256.06285
%
% 20->30 NLOS
% 01 256.06285
% 05 256.06285
% 10 256.06285
% 15 256.06285
tag_freq_search_space = 0;

%processing gain
noise_cir = zeros(size(overair_data,3)*100,1);
gain_snr = [];
%real SNR
load('~/Dropbox/benpat/slo-long/work/cir_noise.mat', 'cir_noise_padded');
%Have an experiment where we lost the last few bands, cut off to match
if size(overair_data,3)*100 ~= size(cir_noise_padded)
  cir_noise_padded = cir_noise_padded(1:size(overair_data,3)*100);
end
cir_snr = [];
%useful signal
confidence = [];
tdoas = [];

deconvolved_fft_best = zeros(size(overair_data,1)/2,size(overair_data,3));

SAMPLE_LIMIT_STEP = 1250;
%sample_limit = 1;
%sample_limit = length(overair_data)-1;
start = 1250;

%samples = 1:SAMPLE_LIMIT_STEP:length(overair_data);
samples = [ ...
  start/10:SAMPLE_LIMIT_STEP/10:start            ...
  start:SAMPLE_LIMIT_STEP/5:start*2              ...
  start*2:SAMPLE_LIMIT_STEP:length(overair_data) ...
  length(overair_data)                           ...
  ];

% [ cir ; direct,backscatter; sample count; ]
cirs = zeros(size(overair_data,3)*10,2,length(samples));

for sample_idx = 1:length(samples)
  sample_limit = samples(sample_idx);
  disp(['sample_limit=',num2str(sample_limit),' (',num2str(sample_limit/1250),' seconds)'])

  % shorten sample
  data = overair_data(:,1:sample_limit,:);
  data_times = overair_data_times(1:sample_limit,:);

  [deconvolved, deconvolved_direct, tag_freq_search_corr] = bandstitching_onezero(cal_data_fft, data, data_times,tag_freq_search_space,TAG_FREQ);

  cirs(:,1,sample_idx) = deconvolved_direct;
  cirs(:,2,sample_idx) = deconvolved;

  %best_cfr = 20*log10(mean(max(tag_freq_search_corr,[],1),3));
  %[pks,locs] = findpeaks(best_cfr);


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
  first_above_idx = find(direct_cir_normed > 0.5,1); % some crappy directs, go to .5 fix
  direct_cir_normed = circshift(direct_cir_normed,-first_above_idx);
  direct_cir_normed = circshift(direct_cir_normed,desired_toa_idx);
  backscatter_cir_normed = circshift(backscatter_cir_normed,-first_above_idx);
  backscatter_cir_normed = circshift(backscatter_cir_normed,desired_toa_idx);

  %Now calculate the TDoA
  first_direct_above_time = cir_dists(find(direct_cir_normed > 0.3,1))
  first_backscatter_above_time = cir_dists(find(backscatter_cir_normed > 0.3,1))
  tdoa = first_backscatter_above_time - first_direct_above_time
  tdoas = [tdoas, tdoa];

  %figure(21);
  %hold on;
  %plot(abs(backscatter_cir_fft))
  %title('Backscatter CIR FFT (CFR)')
  %hold off;

  figure(42);
  clf;
  hold on;
  plot(abs(backscatter_cir_padded))
  plot(abs(cir_noise_padded));
  title('Backscatter CIR and noise')
  hold off;
  figure(43);
  plot(abs(backscatter_cir_normed))
  title('Backscatter CIR (normed)')

  figure(44);
  clf;
  hold on;
  plot(abs(direct_cir_padded))
  plot(abs(cir_noise_padded));
  title('Direct CIR and noise')
  hold off;
  figure(45);
  plot(abs(direct_cir_normed))
  title('Direct CIR (normed)')


  %baseline noise with too little integration
  if noise_cir(1) == 0
    noise_cir = backscatter_cir_padded;
  else
    gain_snr = [gain_snr, snr(backscatter_cir_padded, noise_cir)];
    figure(51);
    plot(gain_snr);
    title('CIR SNR Gain');
  end

  cir_snr = [cir_snr, snr(backscatter_cir_padded, cir_noise_padded)];
  figure(52);
  plot(samples(1:length(cir_snr))/1250,cir_snr);
  title('CIR SNR');

  confidence = [confidence, 20*log10(max(backscatter_cir_padded)/prctile(cir_noise_padded,95))];
  figure(53);
  hold on
  plot(samples(1:length(cir_snr))/1250,confidence);
  plot(samples(1:length(cir_snr))/1250,tdoas);
  plot([0 20], [3 3]) % 3 dB
  ylim([-2 20]);
  hold off
  title('Confidence, also tdoa');

  %if sample_limit > 10000
  %  keyboard;
  %end
  %keyboard;

  sample_limit = sample_limit + SAMPLE_LIMIT_STEP;
end

keyboard;
save(out_cirs, 'cirs', 'samples', 'confidence', 'tdoas');

%keyboard;
