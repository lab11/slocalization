function deconvolved = bandstitching(in_header_filename, in_data_filename, in_cal_header_filename, in_cal_data_filename)

VALID_MEAS_START_IDX = 100;
CAL_VALID_MEAS_START_IDX = 100;
SAMPLE_RATE = 25e6;
ACCUM_COUNT = 1e3;
TAG_FREQ = 256;
TAG_FREQ_PPM_ACCURACY = 50e-5;

[cal_data, cal_data_times] = readUSRPData(in_cal_header_filename,in_cal_data_filename, SAMPLE_RATE, ACCUM_COUNT);
cal_data = cal_data(:,CAL_VALID_MEAS_START_IDX:end,:,:);

%For now, let's just use the last bandstitching sweep...
cal_data = cal_data(:,:,:,end);
cal_data = squeeze(sum(cal_data,2));
cal_data_fft = fft(cal_data,[],1);

[overair_data, overair_data_times] = readUSRPData(in_header_filename,in_data_filename, SAMPLE_RATE, ACCUM_COUNT);
overair_data = overair_data(:,VALID_MEAS_START_IDX:end,:,:);
overair_data_times = overair_data_times(VALID_MEAS_START_IDX:end,:,:);

%%Find a good multiple of the tag period to provide an ending cutoff
%tag_freq_num_idxs = SAMPLE_RATE/ACCUM_COUNT/size(overair_data,1)/TAG_FREQ;
%[~,best_ending_idx] = min(rem(size(overair_data,2)-100:size(overair_data,2)-1,tag_freq_num_idxs));
%overair_data = overair_data(:,1:end-100+best_ending_idx-1,:,:);
%overair_data_times = overair_data_times(1:end-100+best_ending_idx-1,:,:);

%In order to locate the backscatter tag, we need to search across <tag_freq,quadrature_phase>
tag_freq_search_space = -TAG_FREQ_PPM_ACCURACY:5e-6:TAG_FREQ_PPM_ACCURACY;
%tag_search_corr = zeros(length(tag_freq_search_space),size(overair_data,4));
%for tag_freq_offset_idx = 1:length(tag_freq_search_space)
%    tag_freq_offset_ppm = tag_freq_search_space(tag_freq_offset_idx);
%    cur_search_tag_freq = 1/TAG_FREQ*(1+tag_freq_offset_ppm);
%    %for quadrature_phase = 1:2
%        %overair_data_times_mod = rem(overair_data_times + quadrature_phase/TAG_FREQ/4, cur_search_tag_freq);
%        %overair_data_zero_idxs = overair_data_times_mod < cur_search_tag_freq/2;
%        %overair_data_one_idxs = overair_data_times_mod >= cur_search_tag_freq/2;
%        %overair_data_temp = overair_data;
%        %overair_data_temp(:,overair_data_zero_idxs) = -overair_data_temp(:,overair_data_zero_idxs);
%        %tag_search_corr(tag_freq_offset_idx,quadrature_phase,:) = shiftdim(sum(sum(abs(sum(overair_data_temp,2)),3),1),1);
%    %end
%    mixing_signal = exp(-1i.*2.*pi./cur_search_tag_freq.*overair_data_times(:,1,1));
%    overair_data_temp = overair_data.*repmat((blackman(length(mixing_signal)).*mixing_signal).',[size(overair_data,1),1,size(overair_data,3),size(overair_data,4)]);
%    tag_search_corr(tag_freq_offset_idx,:) = sum(sum(abs(sum(overair_data_temp,2)),3),1);
%    disp(['computed tag_freq_offset_ppm = ', num2str(tag_freq_offset_ppm)])
%end
%
%%Best correlation is used
%[~,best_freq_offs_idxs] = max(tag_search_corr,[],1);
%tag_freq_offset = tag_freq_search_space(best_freq_offs_idxs);

%%Deconvolution with over-air direct (doesn't work...)
%cal_data = sum(overair_data(:,:,:,2),2);
%cal_data_fft = squeeze(fft(cal_data,[],1));

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

overair_data = overair_data.*exp(1i*repmat(shiftdim(phase_correction,-2),[size(overair_data,1),size(overair_data,2)]));

deconvolved = zeros(size(overair_data,1)/2*size(overair_data,3),size(overair_data,4),length(tag_freq_search_space));
for tag_freq_offset_idx = 1:length(tag_freq_search_space)
    tag_freq = 1./TAG_FREQ*(1+tag_freq_search_space(tag_freq_offset_idx));
    disp(['computing tag_freq=',num2str(tag_freq)])
    %mixing_signal = sign(cos(2.*pi./repmat(shiftdim(tag_freq,-1),[size(overair_data_times,1),size(overair_data_times,2),1]).*overair_data_times));
    %mixing_signal = exp(1i.*2.*pi./repmat(shiftdim(tag_freq,-1),[size(overair_data_times,1),size(overair_data_times,2),1]).*overair_data_times);
    %mixing_signal = cos(2.*pi./repmat(shiftdim(tag_freq,-1),[size(overair_data_times,1),size(overair_data_times,2),1]).*overair_data_times);
    mixing_signal = sin(2.*pi./repmat(shiftdim(tag_freq,-1),[size(overair_data_times,1),size(overair_data_times,2),1]).*overair_data_times);
    %mixing_signal = ones(size(overair_data_times));
    mixing_signal = mixing_signal.*repmat(blackman(size(mixing_signal,1)),[1,size(mixing_signal,2),size(mixing_signal,3)]);
    overair_data_temp = overair_data.*repmat(shiftdim(mixing_signal,-1),[size(overair_data,1),1,1,1]);
    %overair_data_temp = overair_data;
    blah = squeeze(max(20*log10(abs(fft(overair_data,[],2))),[],1));
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

    %keyboard;
    
    %Flatten to one dimension
    deconvolved_fft = reshape(deconvolved_fft,[size(deconvolved_fft,1)*size(deconvolved_fft,2),size(deconvolved_fft,3)]);
    
    %Load and apply window function
    deconvolved_fft = deconvolved_fft.*repmat(hamming(size(deconvolved_fft,1)),[1,size(deconvolved_fft,2)]);
    deconvolved_fft = ifftshift(deconvolved_fft,1);
    
    %Inverse FFT = CIR
    deconvolved(:,:,tag_freq_offset_idx) = ifft(deconvolved_fft,[],1);
    %keyboard;

end
