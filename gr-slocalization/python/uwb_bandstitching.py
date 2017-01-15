#!/usr/bin/env python
#
# Copyright 2004,2007,2011,2012 Free Software Foundation, Inc.
#
# This file is part of GNU Radio
#
# GNU Radio is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3, or (at your option)
# any later version.
#
# GNU Radio is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with GNU Radio; see the file COPYING.  If not, write to
# the Free Software Foundation, Inc., 51 Franklin Street,
# Boston, MA 02110-1301, USA.
#

from gnuradio import gr
from gnuradio import analog
from gnuradio import blocks
from gnuradio import uhd
from gnuradio.eng_option import eng_option
from optparse import OptionParser

from gnuradio import eng_notation

import datetime, time

#Ref: gr-digital/examples/narrowband/digital_bert_rx.py
import gnuradio.gr.gr_threading as _threading

SAMPLE_RATE = 4e6
START_FREQ = 3.1e9
END_FREQ = 4.4e9
STEP_FREQ = 4e6
DIRECT_FEED_TIME = 0.01
STEP_TIME = 0.1

class status_thread(_threading.Thread):
    def __init__(self, tb):
        _threading.Thread.__init__(self)
        self.setDaemon(1)
        self.tb = tb
        self.done = False
        self.start()

    def run(self):
        next_call = time.time()
        while not self.done:
            self.tb.increment_channel()
            self.tb.switch_to_overair()
            
            try:
                next_call = next_call + STEP_TIME
                time.sleep(next_call - time.time())
            except KeyboardInterrupt:
                self.done = True

class build_block(gr.top_block):
    def __init__(self, args1, args2):
        gr.top_block.__init__(self)

        ##############################
        # TRANSMIT CHAIN
        ##############################
        print "\nTRANSMIT CHAIN"

        #USRP transmits repeating file generated in MATLAB
        self.tx_src = blocks.file_source(gr.sizeof_gr_complex, "iq_in.dat", True)

        #Find USRP with device characteristics specified by args1
        d1 = uhd.find_devices(uhd.device_addr(args1))
        uhd_type1 = d1[0].get('type')
        print "\nFound '%s' at args '%s'" % \
            (uhd_type1, args1)

        stream_args = uhd.stream_args('fc32')
        self.u_tx = uhd.usrp_sink(device_addr=args1, stream_args=stream_args)
        self.u_tx.set_samp_rate(SAMPLE_RATE)
        self.center_freq = START_FREQ
        self.u_tx.set_center_freq(START_FREQ)

        # Get dboard gain range and select maximum
        tx_gain_range = self.u_tx.get_gain_range()
        tx_gain = tx_gain_range.stop()
        self.u_tx.set_gain(tx_gain)

        self.connect (self.tx_src, self.u_tx)

        ##############################
        # RECEIVE CHAIN
        ##############################
        print "\nRECEIVE CHAIN"

        #USRP logs IQ data to file
        self.rx_dst = blocks.file_meta_sink(gr.sizeof_gr_complex, "iq_out.dat", SAMPLE_RATE)

        #Find USRP with device characteristics specified by args1
        d2 = uhd.find_devices(uhd.device_addr(args2))
        uhd_type2 = d2[0].get('type')
        print "\nFound '%s' at args '%s'" % \
            (uhd_type2, args2)

        self.u_rx = uhd.usrp_source(device_addr=args2,
                                    io_type=uhd.io_type.COMPLEX_FLOAT32,
                                    num_channels=1)
        self.u_rx.set_samp_rate(SAMPLE_RATE)
        self.u_rx.set_center_freq(START_FREQ)

        # Get dboard gain range and select maximum
        rx_gain_range = self.u_rx.get_gain_range()
        rx_gain = rx_gain_range.stop()
        self.u_rx.set_gain(rx_gain, 0)

        self.connect (self.u_rx, self.rx_dst)

        # Synchronize both USRPs' timebases
        self.u_rx.set_time_now(uhd.time_spec(0.0))
        self.u_tx.set_time_now(uhd.time_spec(0.0))

    def increment_channel(self):
        self.center_freq = self.center_freq + STEP_FREQ
        if self.center_freq > END_FREQ:
            self.center_freq = START_FREQ
        print "Setting frequency to %f" % (self.center_freq)
        self.u_tx.set_center_freq(self.center_freq)
        self.u_rx.set_center_freq(self.center_freq)

    def switch_to_direct_feed(self):
        self.u_rx.set_antenna("RX2")

    def switch_to_overair(self):
        self.u_rx.set_antenna("TX/RX")

def main ():
    parser = OptionParser (option_class=eng_option)
    parser.add_option("-a", "--args1", type="string", default="addr=192.168.10.13",
                      help="TX UHD device (#1) address args [default=%default]")
    parser.add_option("-A", "--args2", type="string", default="addr=192.168.20.14",
                      help="RX UHD device (#2) address args [default=%default]")
    (options, args) = parser.parse_args ()

    tb = build_block (options.args1, options.args2)
    updater = status_thread(tb)

    try:
        tb.run()
    except KeyboardInterrupt:
        updater.done = True
        updater = None

if __name__ == '__main__':
    main ()
