function [cirs_complex, packet_idxs] = readBackScatterData(filename)

%Read all data in from saleae logic dump
fid = fopen(filename, 'r');
header = fgetl(fid);
[file_data,count] = fscanf(fid, '%f,%d,0x%2X,0x%2X',[4,inf]);
fclose(fid);

%Extract the important information (output of DecaWave)
miso = file_data(4,:).';
clear file_data

%Find all incoming packets denoting start of CIR data read 50 e5 98 c0
cir_read_start_idxs = findPattern2(miso, [80 229 152 192]) + 20;
cir_read_start_idxs = cir_read_start_idxs(1:end-1);
packet_idxs = miso(cir_read_start_idxs-15) + ...
    miso(cir_read_start_idxs-14)*256 + ...
    miso(cir_read_start_idxs-13)*256*256 + ...
    miso(cir_read_start_idxs-12)*256*256*256;

%The CIR isn't read in one fell swoop.  There are some junk bytes here and
%there
subsequence_start_idxs = 2:532:4096;
subsequence_start_idxs_full = ...
    (repmat(cir_read_start_idxs, [1,length(subsequence_start_idxs)]) + ...
    repmat(subsequence_start_idxs, [length(cir_read_start_idxs),1])).';
subsequence_start_idxs_full = subsequence_start_idxs_full(:);

subsequence_idxs_full = ...
    (repmat(subsequence_start_idxs_full,[1,512]) + ...
    repmat(0:511,[length(subsequence_start_idxs_full),1])).';
subsequence_idxs_full = subsequence_idxs_full(:);

cirs_raw = reshape(miso(subsequence_idxs_full),[4096,length(cir_read_start_idxs)]);

cirs_msb = cirs_raw(2:2:end,:);
cirs_lsb = cirs_raw(1:2:end,:);
cirs_msb(cirs_msb > 127) = cirs_msb(cirs_msb > 127) - 256;

cirs = cirs_msb*256 + cirs_lsb;

cirs_complex = cirs(1:2:end,:) + 1i*cirs(2:2:end,:);
cirs_complex = cirs_complex(1:1016,:);