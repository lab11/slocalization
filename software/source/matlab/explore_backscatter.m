clear all;

gold_codes = [];
gold_code = [0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 1, 0, 0, 0, 1, 0, 1, 0, 0, 1, 1, 1, 1, 0, 1, 0, 0, 0, 1, 1, 1, 0, 0, 1, 0, 0, 1, 0, 1, 1, 0, 1, 1, 1, 0, 1, 1, 0, 0, 1, 1, 0, 1, 0, 1, 0, 1, 1, 1, 1, 1, 1]; %0
gold_codes = [gold_codes;gold_code];
gold_code = [0, 0, 0, 0, 0, 1, 1, 1, 1, 0, 0, 1, 0, 0, 1, 0, 1, 0, 1, 0, 0, 1, 1, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1, 1, 0, 1, 1, 1, 1, 1, 1, 0, 1, 0, 1, 1, 1, 0, 0, 0, 1, 1, 0, 0, 1, 1, 1, 0, 1, 1]; %1
gold_codes = [gold_codes;gold_code];
gold_code = [0, 0, 0, 0, 0, 0, 1, 1, 1, 0, 1, 0, 0, 0, 1, 1, 1, 1, 1, 0, 1, 0, 0, 1, 1, 1, 0, 0, 0, 0, 1, 1, 0, 1, 1, 1, 1, 1, 1, 0, 0, 1, 0, 0, 1, 1, 1, 0, 1, 1, 1, 1, 0, 0, 1, 1, 0, 0, 0, 0, 1, 0, 0]; %2
gold_codes = [gold_codes;gold_code];
gold_code = [1, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 1, 1, 0, 1, 0, 1, 1, 0, 0, 1, 0, 0, 0, 1, 0]; %3
gold_codes = [gold_codes;gold_code];
gold_code = [1, 1, 0, 0, 0, 1, 0, 1, 1, 1, 0, 1, 0, 1, 0, 1, 1, 1, 1, 0, 0, 1, 1, 0, 1, 1, 1, 0, 0, 1, 1, 0, 0, 0, 1, 1, 0, 0, 1, 1, 0, 1, 0, 0, 0, 1, 1, 0, 0, 1, 0, 0, 0, 1, 0, 0, 1, 1, 1, 0, 0, 0, 1]; %4
gold_codes = [gold_codes;gold_code];
gold_code = [0, 1, 1, 0, 0, 1, 0, 0, 1, 1, 0, 0, 0, 0, 1, 1, 0, 0, 0, 1, 1, 0, 1, 1, 1, 0, 0, 1, 0, 1, 1, 1, 1, 0, 1, 0, 1, 1, 1, 0, 1, 1, 0, 0, 0, 1, 0, 1, 1, 0, 0, 0, 1, 1, 0, 1, 1, 0, 1, 1, 0, 0, 0]; %5
gold_codes = [gold_codes;gold_code];
gold_code = [1, 0, 1, 1, 0, 1, 0, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 1, 1, 0, 0, 1, 0, 1, 0, 0, 1, 0, 1, 1, 1, 1, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 1, 1, 0, 1, 0, 0, 1, 0, 0, 0, 1, 1, 0, 0]; %6
gold_codes = [gold_codes;gold_code];
gold_code = [1, 1, 0, 1, 1, 1, 0, 0, 0, 0, 0, 0, 1, 1, 0, 1, 1, 1, 0, 1, 1, 0, 1, 0, 0, 1, 1, 1, 0, 0, 1, 1, 0, 0, 0, 0, 0, 1, 1, 1, 0, 1, 1, 0, 0, 1, 0, 0, 1, 0, 0, 1, 1, 0, 1, 1, 0, 1, 0, 0, 1, 1, 0]; %7
gold_codes = [gold_codes;gold_code];
gold_codes = gold_codes*2-1;
gold_len = size(gold_codes,2);
num_gold_codes = size(gold_codes,1);

num_valid_cir_points = 128;
repetition_rate = 0.025; % Approximate number of seconds between beacon transmissions
chip_rate = 1; % Modulation rate of slocalization tag
data_segment_len = 8 + 512 + 2 + 2 + 4 + 4;
timestamp_to_one_second = 1*499.2e6*128;
num_diversity_antennas = 3;

%Apply fixed (measured) tag crystal offset
tag_clock_offset = 0.99975;
timestamp_to_one_second = timestamp_to_one_second*tag_clock_offset;

file_name = 'out.bin';
file_info = dir(file_name);
file_size = file_info.bytes;
num_data_segments = floor(file_size/data_segment_len);
timestamps = zeros(num_data_segments,1);

fid = fopen(file_name,'r');

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

%Maximum number of CIRs for each antenna, antenna pair, per chip
max_cirs_per_chip = ceil(chip_rate/repetition_rate/num_diversity_antennas/num_diversity_antennas);

gold_corrs_full = zeros(num_diversity_antennas, num_diversity_antennas, num_gold_codes, 4, gold_len, num_valid_cir_points);
max_num = 0;
for time_idx = 0:3
	% OPTIONAL: Cut off excess?
	gold_accum = zeros(num_diversity_antennas,num_diversity_antennas,ceil(num_data_segments/gold_len*repetition_rate/chip_rate/2+1),gold_len,num_valid_cir_points);
	gold_accum_final = zeros(num_diversity_antennas,num_diversity_antennas,gold_len,num_valid_cir_points);
	gold_accum_num = zeros(num_diversity_antennas,num_diversity_antennas,gold_len,1);
	rxpaccs = zeros(num_data_segments,1);
	round_nums = zeros(num_data_segments,1);
	tx_antenna_idxs = zeros(num_data_segments,1);
	rx_antenna_idxs = zeros(num_data_segments,1);
	fp_idxs = zeros(num_data_segments,1);
	cirs = zeros(num_data_segments,num_valid_cir_points);
	bit_period_median_filter = zeros(num_diversity_antennas, num_diversity_antennas, max_cirs_per_chip, num_valid_cir_points);
	bit_period_chips = zeros(num_diversity_antennas, num_diversity_antennas, max_cirs_per_chip,1);
	bit_period_num = zeros(num_diversity_antennas, num_diversity_antennas);
	last_bit_number = 1;
	time_offset = time_idx * 0.5;
	for ii=0:num_data_segments-1
		fseek(fid,ii*data_segment_len+8,'bof');
		cur_cir_data = fread(fid,num_valid_cir_points*2,'int16');
		cur_cir_data = cur_cir_data(1:2:end) + 1i*cur_cir_data(2:2:end);
		fseek(fid,(ii+1)*data_segment_len-12,'bof');
		round_nums(ii+1) = fread(fid,1,'uint32');
		fp_idxs(ii+1) = fread(fid,1,'uint16');
		tx_antenna = fread(fid,1,'uint8') + 1;
		tx_antenna_idxs(ii+1) = tx_antenna;
		rx_antenna = fread(fid,1,'uint8') + 1;
		rx_antenna_idxs(ii+1) = rx_antenna;
		finfo = fread(fid,1,'uint32');
		rxpaccs(ii+1) = bitand(finfo,hex2dec('FFF00000'))/2^20;
	
		%%UNSYNCHRONIZED: Rotate CIRs back to t = 0
		%cur_cir_data_fft = fft(cur_cir_data);
		%cur_cir_data_fft = cur_cir_data_fft.*exp(1i*2*pi*fftshift(0:num_valid_cir_points-1).*fp_idx./64./num_valid_cir_points).';
		%cur_cir_data = ifft(cur_cir_data_fft);
	
		%Normalize by the magnitude of leading edge
		%norm_factor = abs(cur_cir_data(4));%sum(abs(cur_cir_data(754:764)));%
		if(rxpaccs(ii+1) < 260)
			continue;
		end
		%cur_cir_data = cur_cir_data.*exp(-1i*angle(cur_cir_data(6)));
		%cur_cir_data = cur_cir_data./abs(cur_cir_data(6));
		cur_cir_data = abs(cur_cir_data);
		norm_factor = rxpaccs(ii+1);
		%norm_factor = max(abs(cur_cir_data));
		
	
		cur_cir_data = cur_cir_data./norm_factor;

		%if(cur_cir_data(3) < 65)
		%	continue
		%end

		cirs(ii+1,:) = cur_cir_data;
	
		chip_number = floor((timestamps(ii+1) - timestamps(1))/timestamp_to_one_second + time_offset) + 1;
		bit_number = floor((chip_number-1)/2) + 1;

		% Check to see if we've transitioned a bit, in which case we need to go back, median filter, and extract manchester-encoded 
		% bit CIRs
		if bit_number > last_bit_number
			bit_number_mod = mod(bit_number-1,gold_len)+1;
			last_bit_number = bit_number;
			for tx_antenna_idx = 1:num_diversity_antennas
				for rx_antenna_idx = 1:num_diversity_antennas
					median_bit_period = median(bit_period_median_filter(tx_antenna_idx,rx_antenna_idx,1:bit_period_num(tx_antenna_idx,rx_antenna_idx),:),1);
					zero_chip_idxs = find(bit_period_chips(tx_antenna_idx,rx_antenna_idx,1:bit_period_num(tx_antenna_idx,rx_antenna_idx)) == 0);
					one_chip_idxs = find(bit_period_chips(tx_antenna_idx,rx_antenna_idx,1:bit_period_num(tx_antenna_idx,rx_antenna_idx)) == 1);
					median_zero_chips = median(squeeze(bit_period_median_filter(tx_antenna_idx,rx_antenna_idx,zero_chip_idxs,:)),1);% - median_bit_period;
					median_one_chips = median(squeeze(bit_period_median_filter(tx_antenna_idx,rx_antenna_idx,one_chip_idxs,:)),1);% - median_bit_period;
					if any(isnan([median_zero_chips,median_one_chips]))
						continue;
					end
					gold_accum(tx_antenna_idx,rx_antenna_idx,gold_accum_num(tx_antenna_idx,rx_antenna_idx,bit_number_mod)+1,bit_number_mod,:) = gold_accum(tx_antenna_idx,rx_antenna_idx,gold_accum_num(tx_antenna_idx,rx_antenna_idx,bit_number_mod)+1,bit_number_mod,:) + shiftdim(median_zero_chips,-3) - shiftdim(median_one_chips,-3);
					gold_accum_num(tx_antenna_idx,rx_antenna_idx,bit_number_mod) = gold_accum_num(tx_antenna_idx,rx_antenna_idx,bit_number_mod) + 1;
				end
			end
			bit_period_num = zeros(num_diversity_antennas);
		end
		bit_period_num(tx_antenna, rx_antenna) = bit_period_num(tx_antenna, rx_antenna) + 1;
		bit_period_median_filter(tx_antenna, rx_antenna, bit_period_num(tx_antenna, rx_antenna),:) = cur_cir_data;
		bit_period_chips(tx_antenna, rx_antenna, bit_period_num(tx_antenna, rx_antenna)) = mod(chip_number-1,2);
		max_num = max(bit_period_num(:),max_num);
	end
	
	%Normalize to the number of accumulated CIRs in each set
	for ii=1:gold_len
		for tx_antenna_idx = 1:num_diversity_antennas
			for rx_antenna_idx = 1:num_diversity_antennas
				gold_accum_final(tx_antenna_idx,rx_antenna_idx,ii,:) = squeeze(median(gold_accum(tx_antenna_idx,rx_antenna_idx,1:gold_accum_num(tx_antenna_idx,rx_antenna_idx,ii),ii,:),3));
			end
		end
	end
	%gold_accum = gold_accum-repmat(median(gold_accum,1),[gold_len,1]);
	%gold_accum = abs(gold_accum);
	%gold_accum = gold_accum-repmat(median(gold_accum),[gold_len,1]);
	
	for jj=1:size(gold_codes,1)
		gold_code = gold_codes(jj,:);
		%Perform cross correlation across accumulated CIRs
		gold_corrs = zeros(num_diversity_antennas, num_diversity_antennas, gold_len, num_valid_cir_points);
		for ii=0:gold_len-1
			gold_rotated = circshift(gold_code.',ii);
			pn_ones = find(gold_rotated == 1);
			pn_zeros = find(gold_rotated == -1);
			pn_ones_mean = sum(gold_accum_final(:,:,pn_ones,:),3);
			pn_zeros_mean = sum(gold_accum_final(:,:,pn_zeros,:),3);
			
			gold_corrs(:,:,ii+1,:) = pn_zeros_mean - pn_ones_mean;%sum(gold_accum.*repmat(gold_rotated,[1,num_valid_cir_points]),1);
		end
		gold_corrs_full(:,:,jj,time_idx+1,:,:) = gold_corrs;
	end
end
keyboard;
for ii=1:num_gold_codes
	max_idx = 1;
	max_val = 0;
	for jj=1:4
		cur_max_val = max(max(abs(gold_corrs_full(ii,jj,:,:))));
		if max_val < cur_max_val
			max_idx = jj;
			max_val = cur_max_val;
		end
	end
	subplot(num_gold_codes,1,ii);
	imagesc(squeeze(abs(gold_corrs_full(ii,max_idx,:,:))))
end

return;
