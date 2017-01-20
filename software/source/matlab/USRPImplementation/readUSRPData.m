function ret = readUSRPData(header_csv_filename, data_filename)

%testscan is the best bet for reading in the corresponding data found in the header file
fid = fopen(header_csv_filename,'r');
header_data = textscan(fid, '%d%d%s%f%d%d%s%f%s%f%d','headerlines',1,'Delimiter',',');
fclose(fid);

%nbytes (column 5) tells us how many bytes are in each frequency range
nbytes = header_data{5};
cum_bytes = cumsum(nbytes(1:end-1));
cum_cplx_idxs = cum_bytes/8; %complex = 8 bytes (float, float)

%nitems (column 1) tells us how many vectors are in each frequency range
nitems = header_data{1};
min_observations = min(nitems(1:end-1));
ncplx_per_vec = nbytes(1)/nitems(1)/8;

%rx_freq (column 8) gives the current tuning frequency
rx_freq = header_data{8};
num_freq_bins = find(rx_freq(2:end) == rx_freq(1),1);
num_reps = floor(length(rx_freq)/num_freq_bins);

%read in the data file
fid = fopen(data_filename,'r');
data = fread(fid,'float');
fclose(fid);
data = data(1:2:end) + 1i*data(2:2:end);

%Reorganize data into (ncplx_per_vec,min_observations,num_freq_bins,num_reps)
seg_data = zeros(ncplx_per_vec,min_observations,num_freq_bins,num_reps);
cur_bin_idx = 1;
for ii=1:num_reps
    for jj=1:num_freq_bins
        seg_data(:,:,jj,ii) = reshape(data(cum_cplx_idxs(cur_bin_idx)-ncplx_per_vec*min_observations+1:cum_cplx_idxs(cur_bin_idx)),[ncplx_per_vec,min_observations]);
        cur_bin_idx = cur_bin_idx + 1;
    end
end

%Remove last observation since it may be corrupted by a frequency change
seg_data = seg_data(:,1:end-1,:,:);

ret = seg_data;