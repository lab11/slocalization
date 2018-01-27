#!/bin/bash

EXP_DIR=256hz_onetoone_exp2

mkdir $EXP_DIR
mkdir $EXP_DIR/20_tx
mkdir $EXP_DIR/30_tx

./configure_eth_interface.sh 192.168.20.14
./configure_eth_interface.sh 192.168.30.15

sudo ./uwb_bandstitching.py --args1="addr=192.168.30.15" --args2="addr=192.168.20.14"
mv iq_out* $EXP_DIR/30_tx
cd $EXP_DIR/30_tx
../../gr_parse_file_metadata ./iq_out_192.168.20.14.dat
mv data.dat data_192.168.20.14.dat
mv header.csv header_192.168.20.14.csv
cd ../../
sudo ./uwb_bandstitching.py --args1="addr=192.168.20.14" --args2="addr=192.168.30.15"
mv iq_out* $EXP_DIR/20_tx
cd $EXP_DIR/20_tx
../../gr_parse_file_metadata ./iq_out_192.168.30.15.dat
mv data.dat data_192.168.30.15.dat
mv header.csv header_192.168.30.15.csv
