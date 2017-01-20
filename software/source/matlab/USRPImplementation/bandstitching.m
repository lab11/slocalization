function deconvolved = bandstitching(in_header_filename, in_data_filename)

VALID_MEAS_START_IDX = 60;

cal_data = readUSRPData('header_overair_cal.csv','data_overair_cal.dat');
cal_data = cal_data(:,VALID_MEAS_START_IDX:end,:,:);

overair_data = readUSRPData(in_header_filename,in_data_filename);
overair_data = overair_data(:,VALID_MEAS_START_IDX:end,:,:);

%For now, let's just use the last bandstitching sweep...
cal_data = cal_data(:,:,:,end);
%overair_data = overair_data(:,:,:,end);

%Average across time...
cal_data = squeeze(sum(cal_data,2));
overair_data = squeeze(sum(overair_data,2));

%Change everything to the frequency domain...
cal_data_fft = fft(cal_data,[],1);
overair_data_fft = fft(overair_data,[],1);

%Deconvolution is a simple division...
deconvolved_fft = overair_data_fft./repmat(cal_data_fft,[1,1,size(overair_data_fft,3)]);

%Center DC...
deconvolved_fft = fftshift(deconvolved_fft,1);

%For now, DC and -BW/2 are unusable, so only choose every other bin for now...
deconvolved_fft = deconvolved_fft(2:2:end,:,:);

%Flatten to one dimension
deconvolved_fft = reshape(deconvolved_fft,[size(deconvolved_fft,1)*size(deconvolved_fft,2),size(deconvolved_fft,3)]);

%Load and apply window function
load window;
deconvolved_fft = deconvolved_fft.*repmat(window,[1,size(deconvolved_fft,2)]);
deconvolved_fft = ifftshift(deconvolved_fft,1);

%Inverse FFT = CIR
deconvolved = ifft(deconvolved_fft,[],1);
