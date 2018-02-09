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

%In order to locate the backscatter tag, we need to search across <tag_freq,quadrature_phase>
tag_freq_search_space = -TAG_FREQ_PPM_ACCURACY:100e-6:TAG_FREQ_PPM_ACCURACY;

tag_freq_search_corr = zeros(8,length(tag_freq_search_space),size(overair_data,3));

tic;
for tag_time_offset_idx = 1:8%length(pn_code)*8
    for tag_freq_offset_idx = 1:length(tag_freq_search_space)
        tag_freq = 1./TAG_FREQ*(1-tag_freq_search_space(tag_freq_offset_idx));
        mixing_signal = cos(2.*pi./repmat(shiftdim(tag_freq,-1),[size(overair_data_times,1),size(overair_data_times,2),1]).*repmat(overair_data_times(:,1),[1,size(overair_data_times,2)])+tag_time_offset_idx*pi/8);
        %mixing_signal = ones(size(overair_data_times));
        mixing_signal = mixing_signal.*repmat(blackman(size(mixing_signal,1)),[1,size(mixing_signal,2),size(mixing_signal,3)]);
        overair_data_temp = overair_data.*repmat(shiftdim(mixing_signal,-1),[size(overair_data,1),1,1,1]);
        %overair_data_temp = overair_data;
        tag_freq_search_corr(tag_time_offset_idx,tag_freq_offset_idx,:) = squeeze(sum(abs(sum(overair_data_temp,2)),1));
        %keyboard;
    
    end
    disp(['computing tag_time=',num2str(tag_time_offset_idx)])
end
blah = squeeze(max(20*log10(abs(fft(overair_data,[],2))),[],1));
toc

f1 = figure(1);
plot(TAG_FREQ*(1+tag_freq_search_space),20*log10(mean(max(tag_freq_search_corr,[],1),3)))
title('Correlation vs. tag frequency estimate');
saveas(f1, [out_image_prefix,'corr-freq-est','.png']);
f2 = figure(2);
imagesc(tag_freq_search_corr(:,:,1))
saveas(f2, [out_image_prefix,'tag-corr-heat','.png']);
keyboard;
