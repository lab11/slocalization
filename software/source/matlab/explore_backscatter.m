clear all;

gold_code = [0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 1, 0, 0, 0, 1, 0, 1, 0, 0, 1, 1, 1, 1, 0, 1, 0, 0, 0, 1, 1, 1, 0, 0, 1, 0, 0, 1, 0, 1, 1, 0, 1, 1, 1, 0, 1, 1, 0, 0, 1, 1, 0, 1, 0, 1, 0, 1, 1, 1, 1, 1, 1]*2-1;
gold_len = length(gold_code);

num_valid_cir_points = 1016;
data_segment_len = 8 + 1024*4 + 2 + 4 + 4;
timestamp_to_one_second = 1*499.2e6*128;

file_name = 'out.bin';
file_info = dir(file_name);
file_size = file_info.bytes;
num_data_segments = floor(file_size/data_segment_len);
timestamps = zeros(num_data_segments,1);

fid = fopen(file_name,'r');
phase_offset = 0;

% Get the first timestamp to start things off and know what to base everything off of
overflow_cumsum = 0;
for ii=0:num_data_segments-1
	fseek(fid,ii*data_segment_len,'bof');
	timestamps(ii+1) = fread(fid,1,'uint64') + overflow_cumsum;
	if ii > 0 && timestamps(ii+1) < timestamps(ii)
		timestamps(ii+1) = timestamps(ii+1) + 2^40;
		overflow_cumsum = overflow_cumsum + 2^40;
	end
end

% OPTIONAL: Cut off excess?
gold_accum = zeros(gold_len,num_valid_cir_points);
gold_accum_num = zeros(gold_len,1);
gold_bits = zeros(num_data_segments,1);
rxpaccs = zeros(num_data_segments,1);
round_nums = zeros(num_data_segments,1);
for ii=0:num_data_segments-1
	fseek(fid,ii*data_segment_len+8,'bof');
	cur_cir_data = fread(fid,num_valid_cir_points*2,'int16');
	cur_cir_data = cur_cir_data(1:2:end) + 1i*cur_cir_data(2:2:end);
	fseek(fid,(ii+1)*data_segment_len-10,'bof');
	round_nums(ii+1) = fread(fid,1,'uint32');
	fp_idx = fread(fid,1,'uint16');
	finfo = fread(fid,1,'uint32');
	rxpaccs(ii+1) = bitand(finfo,hex2dec('FFF00000'))/2^20;

	cur_cir_data = cur_cir_data./rxpaccs(ii+1);

	time_offset = (timestamps(ii+1) - timestamps(1))/timestamp_to_one_second+0.5;
	cur_gold_bit = mod(floor(time_offset),gold_len)+1;
	gold_accum(cur_gold_bit,:) = gold_accum(cur_gold_bit,:) + cur_cir_data.';
	gold_accum_num(cur_gold_bit) = gold_accum_num(cur_gold_bit) + 1;
	gold_bits(ii+1) = cur_gold_bit;
end

%Normalize to the number of accumulated CIRs in each set
gold_accum = gold_accum./repmat(gold_accum_num,[1,num_valid_cir_points]);
%gold_accum = abs(gold_accum);
%gold_accum = gold_accum-repmat(median(gold_accum),[gold_len,1]);

%Perform cross correlation across accumulated CIRs
gold_corrs = zeros(gold_len, num_valid_cir_points);
for ii=0:gold_len-1
	gold_rotated = circshift(gold_code.',ii);
	pn_ones = find(gold_rotated == 1);
	pn_zeros = find(gold_rotated == -1);
	pn_ones_mean = sum(gold_accum(pn_ones,:),1)./length(pn_ones);
	pn_zeros_mean = sum(gold_accum(pn_zeros,:),1)./length(pn_zeros);
	
	gold_corrs(ii+1,:) = pn_ones_mean - pn_zeros_mean;%sum(gold_accum.*repmat(gold_rotated,[1,num_valid_cir_points]),1);
end
return;

INTERP_SIZE = 2^16;
%TOA_THRESH = 0.5;

disp('Reading CIRs from file...')
[cirs, packet_idxs] = readBackScatterData('backscatter_test4_stationary.csv');

disp('Correlating CIRs...')
result_len = floor(size(cirs,2)/2)-2;
diff_plus_two = zeros(INTERP_SIZE,result_len);
diff_plus_one = zeros(INTERP_SIZE,result_len);
diff_angle_two = zeros(result_len,1);
diff_angle_one = zeros(result_len,1);
phase_corrections = zeros(result_len, 4);
backscatter_toas = zeros(result_len,1);
expected_phase_angle_error = zeros(result_len,1);

cirs_aligned = zeros(INTERP_SIZE, size(cirs,2));
pops = zeros(size(cirs,2),1);
for ii=2:size(cirs,2)
    [poa1, poa2, pop1, pop2] = lineUpCIRs(cirs(:,1),cirs(:,ii),INTERP_SIZE);
    cirs_aligned(:,1) = poa1;
    cirs_aligned(:,ii) = poa2;
    [max_abs,max_idx] = max(abs(poa2));
    pops(ii) = max_abs;
end

gold_corrs = zeros(INTERP_SIZE,size(cirs,2)-gold_len);
for ii=1:size(cirs,2)-gold_len
    disp(['ii = ',num2str(ii)])
    
    gold_corr = zeros(INTERP_SIZE,1);
    for jj=1:gold_len
        gold_corr = gold_corr + cirs_aligned(:,ii+jj-1)*gold_code(jj);
    end
    gold_corrs(:,ii) = gold_corr;
%     cir = cirs(:,ii);
%     cir_plus_1 = cirs(:,ii+1);
%     cir_plus_2 = cirs(:,ii+2);
%     [poa1, poa2, pop1, pop2] = lineUpCIRs(cir,cir_plus_1,INTERP_SIZE);
%     [pta1, pta2, ptp1, ptp2] = lineUpCIRs(cir,cir_plus_2,INTERP_SIZE);
%     
%     poa1 = poa1/max(abs(poa1));
%     poa2 = poa2/max(abs(poa2));
%     pta1 = pta1/max(abs(pta1));
%     pta2 = pta2/max(abs(pta2));
%     angle_error_cand(1) = mod((ptp2 + ptp1) / 2 - pop2 + pi,2*pi) - pi;
%     angle_error_cand(2) = mod((ptp2 + ptp1) / 2 - pop2 + 2*pi,2*pi) - pi;
%     angle_diff_cand(1) = (ptp2 + ptp1) / 2;
%     angle_diff_cand(2) = (ptp2 + ptp1) / 2 + pi;
%     [expected_phase_angle_error(jj), min_idx] = min(abs(angle_error_cand));
%     
%     diff_plus_one(:,jj) = (pta1+poa1)/2-poa2*exp(1i*pop2)*exp(-1i*angle_diff_cand(min_idx));
%     diff_plus_two(:,jj) = pta2-pta1;
%     diff_angle_one(jj) = pop2-pop1;
%     diff_angle_two(jj) = ptp2-ptp1;
%     phase_corrections(jj,:) = [pop1, pop2, ptp1, ptp2];
%     above_thresh = find(abs(diff_plus_one(:,jj)) > max(abs(diff_plus_one(:,jj)))*TOA_THRESH);
%     backscatter_toas(jj) = above_thresh(1);
%    
%    jj=jj+1;
end
