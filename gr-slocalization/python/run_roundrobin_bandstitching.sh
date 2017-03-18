#!/bin/bash

./uwb_bandstitching.py --args1="addr=192.168.10.13" --args2="addr=192.168.20.14,addr=192.168.30.15"
./gr_parse_file_metadata iq_out_192.168.20.14.dat
mv data.dat data_10_to_20.dat
mv header.csv header_10_to_20.csv
./gr_parse_file_metadata iq_out_192.168.30.15.dat
mv data.dat data_10_to_30.dat
mv header.csv header_10_to_30.csv
./uwb_bandstitching.py --args1="addr=192.168.20.14" --args2="addr=192.168.10.13,addr=192.168.30.15"
./gr_parse_file_metadata iq_out_192.168.10.13.dat
mv data.dat data_20_to_10.dat
mv header.csv header_20_to_10.csv
./gr_parse_file_metadata iq_out_192.168.30.15.dat
mv data.dat data_20_to_30.dat
mv header.csv header_20_to_30.csv
./uwb_bandstitching.py --args1="addr=192.168.30.15" --args2="addr=192.168.10.13,addr=192.168.20.14"
./gr_parse_file_metadata iq_out_192.168.10.13.dat
mv data.dat data_30_to_10.dat
mv header.csv header_30_to_10.csv
./gr_parse_file_metadata iq_out_192.168.20.14.dat
mv data.dat data_30_to_20.dat
mv header.csv header_30_to_20.csv
