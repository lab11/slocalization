#!/bin/bash

EXP_DIR=256hz_exp8

mkdir $EXP_DIR
mkdir $EXP_DIR/minus_2
mkdir $EXP_DIR/minus_1

./uwb_bandstitching_multichannel.py --trxoff=2
mv iq_out* $EXP_DIR/minus_2
cd $EXP_DIR/minus_2
../../parse_iq_out_files.sh
cd ../../
./uwb_bandstitching_multichannel.py --trxoff=1
mv iq_out* $EXP_DIR/minus_1
cd $EXP_DIR/minus_1
../../parse_iq_out_files.sh
cd ../../
