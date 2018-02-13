function [deconvolved, deconvolved_direct] = bandstitching_onezero(exp_folder, cal_folder, from, to)
%function [deconvolved, deconvolved_direct] = bandstitching_pn(in_header_filename, in_data_filename, in_cal_header_filename, in_cal_data_filename)
%[experiment_folder_name,'/30_tx/header_192.168.20.14.csv'],[experiment_folder_name,'/30_tx/data_192.168.20.14.dat'],[cal_folder_name,'/30_tx/header_192.168.20.14.csv'],[cal_folder_name,'/30_tx/data_192.168.20.14.dat']

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
START_FREQ = 3.15e9;
END_FREQ = 4.35e9;
STEP_FREQ = SAMPLE_RATE;

[cal_data, cal_data_times] = readUSRPData(in_cal_header_filename,in_cal_data_filename, SAMPLE_RATE, ACCUM_COUNT);
cal_data = cal_data(:,CAL_VALID_MEAS_START_IDX:end-CAL_VALID_MEAS_START_IDX,:,:);

%For now, let's just use the last bandstitching sweep...
cal_data = cal_data(:,:,:,end);
cal_data = squeeze(sum(cal_data,2));
cal_data_fft = fft(cal_data,[],1);

[overair_data, overair_data_times] = readUSRPData(in_header_filename,in_data_filename, SAMPLE_RATE, ACCUM_COUNT);
overair_data = overair_data(:,VALID_MEAS_START_IDX:end-VALID_MEAS_START_IDX,:,:);
overair_data_times = overair_data_times(VALID_MEAS_START_IDX:end-VALID_MEAS_START_IDX,:,:);

%Shorten sample
%overair_data = overair_data(:,1:10000,:);
%overair_data_times = overair_data_times(1:10000,:);

%Break sample into ranges
SAMPLEN = 12350*2;
overair_starts = 1:SAMPLEN:length(overair_data);
%Drop last, incomplete
overair_starts = overair_starts(1:end-1);

%In order to locate the backscatter tag, we need to search across <tag_freq,quadrature_phase>
%tag_freq_search_space = -TAG_FREQ_PPM_ACCURACY:100e-6:TAG_FREQ_PPM_ACCURACY;

%tag_freq_search_corr = zeros(8,length(tag_freq_search_space),size(overair_data,3));
phase_steps = 64;
tag_freq_search_corr = zeros(phase_steps,1,size(overair_data,3));

step_idxs = zeros(length(overair_starts),size(overair_data,3));

tic;
for overair_start_idx = 1:length(overair_starts)
    overair_start = overair_starts(overair_start_idx);
    disp(['computing ',num2str(overair_start),'-',num2str(overair_start+SAMPLEN)])
    data = overair_data(:,overair_start:overair_start+SAMPLEN,:);
    data_times = overair_data_times(overair_start:overair_start+SAMPLEN,:);
    for tag_time_offset_idx = 1:phase_steps
        tag_freq = 1./TAG_FREQ;
        mixing_signal = cos(2.*pi.*TAG_FREQ.*data_times+tag_time_offset_idx*pi/phase_steps);
        %mixing_signal = ones(size(data_times));
        mixing_signal = mixing_signal.*repmat(blackman(size(mixing_signal,1)),[1,size(mixing_signal,2),size(mixing_signal,3)]);
        data_temp = data.*repmat(shiftdim(mixing_signal,-1),[size(data,1),1,1,1]);
        %data_temp = data;
        tag_freq_search_corr(tag_time_offset_idx,1,:) = squeeze(sum(abs(sum(data_temp,2)),1));
        %keyboard;
    end

    %f1 = figure(1);
    %imagesc(tag_freq_search_corr(:,:,1))
    %f2 = figure(2);
    %imagesc(tag_freq_search_corr(:,:,2))
    %f3 = figure(3);
    %imagesc(tag_freq_search_corr(:,:,3))

    [phase,phase_idx] = max(tag_freq_search_corr,[],1);
    step_idxs(overair_start_idx,:) = squeeze(phase_idx);

    %keyboard;
end
%blah = squeeze(max(20*log10(abs(fft(overair_data,[],2))),[],1));
toc

%f1 = figure(1);
%plot(TAG_FREQ*(1+tag_freq_search_space),20*log10(mean(max(tag_freq_search_corr,[],1),3)))
%title('Correlation vs. tag frequency estimate');
%saveas(f1, [out_image_prefix,'corr-freq-est','.png']);
%f1 = figure(1);
%imagesc(tag_freq_search_corr(:,:,1))
%f2 = figure(2);
%imagesc(tag_freq_search_corr(:,:,2))
%f3 = figure(3);
%imagesc(tag_freq_search_corr(:,:,3))
%saveas(f2, [out_image_prefix,'tag-corr-heat','.png']);

figure(1);
plot(step_idxs(:,1));
ylim([0,64]);
title([TAG_FREQ,1])

figure(2);
plot(step_idxs(:,2));
ylim([0,64]);
title([TAG_FREQ,2])

figure(3);
plot(step_idxs(:,3));
ylim([0,64]);
title([TAG_FREQ,3])

keyboard;
