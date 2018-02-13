function [deconvolved, deconvolved_direct, tag_freq_search_corr] = bandstitching_onezero(cal_data_fft,overair_data,overair_data_times,tag_freq_search_space, TAG_FREQ)
%function [deconvolved, deconvolved_direct, tag_freq_search_corr] = bandstitching_onezero(exp_folder, cal_folder, from, to, sample_limit)
%function [deconvolved, deconvolved_direct] = bandstitching_pn(in_header_filename, in_data_filename, in_cal_header_filename, in_cal_data_filename)
%[experiment_folder_name,'/30_tx/header_192.168.20.14.csv'],[experiment_folder_name,'/30_tx/data_192.168.20.14.dat'],[cal_folder_name,'/30_tx/header_192.168.20.14.csv'],[cal_folder_name,'/30_tx/data_192.168.20.14.dat']

VALID_MEAS_START_IDX = 100;
CAL_VALID_MEAS_START_IDX = 100;
SAMPLE_RATE = 25e6;
ACCUM_COUNT = 1e3;
%TAG_FREQ = 256.064;
%TAG_FREQ_PPM_ACCURACY = 250e-6;
START_FREQ = 3.15e9;
END_FREQ = 4.35e9;
STEP_FREQ = SAMPLE_RATE;




%Due to 25 MHz steps and 100 MHz reference, we observe a random pi/2 slip each retuning
phase_correction = zeros(size(overair_data,3),size(overair_data,4));

%Phase slip of first is our reference and set to zero
cand_phase_corrs = (0:7)*pi/4;
for ii=2:size(overair_data,3)
    for jj=1:size(overair_data,4)
        prev_step_ts = sum(overair_data(:,:,ii-1,jj),2).*exp(1i*phase_correction(ii-1,jj));
        prev_step_fft = fftshift(fft(prev_step_ts)./cal_data_fft(:,ii-1));
        cur_step_ts = sum(overair_data(:,:,ii,jj),2);
        cur_step_fft = fftshift(fft(cur_step_ts)./cal_data_fft(:,ii));

        %Try all phase offsets and pick the one with lowest quadrant magnitude
        cand_bandstitched_combinations_fft = repmat([prev_step_fft(2:2:end);cur_step_fft(2:2:end)].*hamming(length(cur_step_fft)),[1,length(cand_phase_corrs)]).*[ones(length(prev_step_fft)/2,length(cand_phase_corrs));repmat(exp(1i*cand_phase_corrs),[length(cur_step_fft)/2,1])];
        cand_bandstitched_combinations_ts = ifft(ifftshift(cand_bandstitched_combinations_fft,1),[],1);
        num_bins_per_quadrant = floor(size(cand_bandstitched_combinations_ts,1)/4);
        quadrants_ts = reshape(abs(cand_bandstitched_combinations_ts(1:num_bins_per_quadrant*4,:)),[num_bins_per_quadrant,4,size(cand_bandstitched_combinations_ts,2)]);
        min_quadrants = min(squeeze(sum(quadrants_ts,1)),[],1);
        [~,which_corr] = min(sum(sum(quadrants_ts,1),2));%min(min_quadrants);
        phase_correction(ii,jj) = cand_phase_corrs(which_corr);
    end
end

center_freqs = START_FREQ:STEP_FREQ:END_FREQ;
possible_pll_offset_times = 0:1/400e6:19/400e6;
possible_phase_offsets = exp(1i*2*pi*repmat(center_freqs.',[1,length(possible_pll_offset_times)]).*repmat(possible_pll_offset_times,[length(center_freqs),1]));
cand_deconvolved = zeros(size(overair_data,1)/2*size(overair_data,3),size(overair_data,4),size(possible_phase_offsets,2));
for ii=1:size(possible_phase_offsets,2)
    overair_data_temp = overair_data;

    overair_data_temp = overair_data_temp.*repmat(shiftdim(possible_phase_offsets(:,ii),-2),[size(overair_data,1),size(overair_data,2),1,size(overair_data,4)]);

    overair_data_temp = squeeze(sum(overair_data_temp,2));
    overair_data_fft = fft(overair_data_temp,[],1);
    deconvolved_fft = overair_data_fft./repmat(cal_data_fft,[1,1,size(overair_data_fft,3)]);
    deconvolved_fft = fftshift(deconvolved_fft,1);
    deconvolved_fft = deconvolved_fft(2:2:end,:,:);
    deconvolved_fft = reshape(deconvolved_fft,[size(deconvolved_fft,1)*size(deconvolved_fft,2),size(deconvolved_fft,3)]);
    deconvolved_fft = deconvolved_fft.*repmat(hamming(size(deconvolved_fft,1)),[1,size(deconvolved_fft,2)]);
    deconvolved_fft = ifftshift(deconvolved_fft,1);
    cand_deconvolved(:,:,ii) = ifft(deconvolved_fft,[],1);
end
%phase_correction = repmat([repmat([0;3*pi/2;2*pi/2;pi/2],[12,1]);0],[1,size(phase_correction,2)]);
%phase_correction = repmat([repmat(phase_correction(11:20,1),[4,1]);phase_correction(11:19,1)],[1,size(phase_correction,2)]);
[~,best_offset] = min(sum(abs(cand_deconvolved(:,1,:)),1));
deconvolved_direct = cand_deconvolved(:,:,best_offset);
overair_data = overair_data.*repmat(shiftdim(possible_phase_offsets(:,best_offset),-2),[size(overair_data,1),size(overair_data,2),1,size(overair_data,4)]);

%deconvolved_direct = 0; %silence error




tag_freq_search_corr = zeros(8,length(tag_freq_search_space),size(overair_data,3));
deconvolved_fft_cands = zeros(8,length(tag_freq_search_space),size(overair_data,1)/2,size(overair_data,3));

deconvolved = zeros(size(overair_data,1)/2*size(overair_data,3),size(overair_data,4));%length(pn_code)*8);
%deconvolved = zeros(size(overair_data,1)/2*size(overair_data,3),size(overair_data,4),length(tag_freq_search_space),8);%length(pn_code)*8);
%deconvolved = zeros(16*size(overair_data,3),size(overair_data,4),length(tag_freq_search_space),8);%length(pn_code)*8);
tic;
for tag_time_offset_idx = 1:8%length(pn_code)*8
    disp(['computing tag_time=',num2str(tag_time_offset_idx)])
    for tag_freq_offset_idx = 1:length(tag_freq_search_space)
        tag_freq = 1./TAG_FREQ*(1-tag_freq_search_space(tag_freq_offset_idx));
        mixing_signal = cos(2.*pi./repmat(shiftdim(tag_freq,-1),[size(overair_data_times,1),size(overair_data_times,2),1]).*repmat(overair_data_times(:,1),[1,size(overair_data_times,2)])+tag_time_offset_idx*pi/8);
        %mixing_signal = ones(size(overair_data_times));
        mixing_signal = mixing_signal.*repmat(blackman(size(mixing_signal,1)),[1,size(mixing_signal,2),size(mixing_signal,3)]);
        overair_data_temp = overair_data.*repmat(shiftdim(mixing_signal,-1),[size(overair_data,1),1,1,1]);
        %overair_data_temp = overair_data;
        tag_freq_search_corr(tag_time_offset_idx,tag_freq_offset_idx,:) = squeeze(sum(abs(sum(overair_data_temp,2)),1));
        %keyboard;
    
        %Average across time...
        overair_data_temp = squeeze(sum(overair_data_temp,2));
    
        %Change everything to the frequency domain...
        overair_data_fft = fft(overair_data_temp,[],1);
    
        %TODO: This is here because if we re-lock, we get a random reference phase offset... It's not always going to be this...
        %overair_data_fft(:,1:2:end,:) = overair_data_fft(:,1:2:end,:).*repmat(exp(1i*pi),size(overair_data_fft(:,1:2:end,:)));
        
        %Deconvolution is a simple division...
        deconvolved_fft = overair_data_fft./repmat(cal_data_fft,[1,1,size(overair_data_fft,3)]);
        %keyboard;
        
        %Center DC...
        deconvolved_fft = fftshift(deconvolved_fft,1);
        
        %For now, DC and -BW/2 are unusable, so only choose every other bin for now...
        deconvolved_fft = deconvolved_fft(2:2:end,:,:);
        %deconvolved_fft = deconvolved_fft([2:9,13:end],:,:);
    
        %keyboard;
        deconvolved_fft_cands(tag_time_offset_idx,tag_freq_offset_idx,:,:) = deconvolved_fft;
    end
end
blah = squeeze(max(20*log10(abs(fft(overair_data,[],2))),[],1));
toc

f1 = figure(1);
hold on;
plot(TAG_FREQ*(1+tag_freq_search_space),20*log10(mean(max(tag_freq_search_corr,[],1),3)))
title('Correlation vs. tag frequency estimate');
%saveas(f1, [out_image_prefix,'corr-freq-est','.png']);
hold off;
f2 = figure(2);
imagesc(tag_freq_search_corr(:,:,1))
%saveas(f2, [out_image_prefix,'tag-corr-heat','.png']);
%keyboard;


deconvolved_fft_best = zeros(size(overair_data,1)/2,size(overair_data,3));

% stitch with best each band
for band_idx = 1:length(tag_freq_search_corr)
    tf_band = tag_freq_search_corr(:,:,band_idx);
    [maxes,idxs] = max(tf_band(:));
    [time_offset,freq_offset] = ind2sub(size(tf_band),idxs);

    deconvolved_fft_best(:,band_idx) = deconvolved_fft_cands(time_offset,freq_offset,:,band_idx);
end

%Flatten to one dimension
stitched = reshape(deconvolved_fft_best,[size(deconvolved_fft_best,1)*size(deconvolved_fft_best,2),size(deconvolved_fft_best,3)]);

%Load and apply window function
windowed = stitched.*repmat(hamming(size(stitched,1)),[1,size(stitched,2)]);
shifted = ifftshift(windowed,1);

%Inverse FFT = CIR
deconvolved(:,:) = ifft(shifted,[],1);
%keyboard;

