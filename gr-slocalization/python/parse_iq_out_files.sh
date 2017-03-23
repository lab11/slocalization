#!/bin/bash

../../gr_parse_file_metadata ./iq_out_192.168.10.13.dat
mv data.dat data_192.168.10.13.dat
mv header.csv header_192.168.10.13.csv
../../gr_parse_file_metadata ./iq_out_192.168.20.14.dat
mv data.dat data_192.168.20.14.dat
mv header.csv header_192.168.20.14.csv
../../gr_parse_file_metadata ./iq_out_192.168.30.15.dat
mv data.dat data_192.168.30.15.dat
mv header.csv header_192.168.30.15.csv
