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
import slocalization

from gnuradio import eng_notation
import pmt

import datetime, time

#Ref: gr-digital/examples/narrowband/digital_bert_rx.py
import gnuradio.gr.gr_threading as _threading

SAMPLE_RATE = 50e6
START_FREQ = 3.15e9
END_FREQ = 6.00e9
START_TX_GAIN = 15.6
END_TX_GAIN = 18.9+6
STEP_FREQ = SAMPLE_RATE
DIRECT_FEED_TIME = 0.01
STEP_TIME = 2.0
SIGNAL_LEN = 20

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

        ##USRP transmits repeating file generated in MATLAB
        #self.tx_src = blocks.file_source(gr.sizeof_gr_complex, "iq_in.dat", True)

        #USRP transmits a repeating vector generated here...
        tx_list = [0.2363 + 0.0741j,
                   0.0733 - 0.2865j,
                  -0.1035 - 0.2663j,
                  -0.0853 + 0.1909j,
                  -0.0736 + 0.2699j,
                   0.0773 + 0.1481j,
                  -0.0336 + 0.2079j,
                  -0.0644 - 0.2244j,
                   0.0396 + 0.2822j,
                  -0.0595 - 0.2416j,
                   0.1379 + 0.2658j,
                  -0.0449 - 0.2539j,
                   0.0593 + 0.2946j,
                   0.0221 - 0.0113j,
                  -0.1303 + 0.2762j,
                  -0.1351 - 0.2598j,
                  -0.0275 - 0.2617j,
                   0.2157 + 0.1021j,
                   0.0332 - 0.0383j,
                  -0.1369 - 0.2680j]
        self.vec_tx_src = blocks.vector_source_c(tuple(tx_list), True, SIGNAL_LEN, [])
        self.tx_src = blocks.vector_to_stream(gr.sizeof_gr_complex, SIGNAL_LEN)

        #Find USRP with device characteristics specified by args1
        d1 = uhd.find_devices(uhd.device_addr(args1))
        uhd_type1 = d1[0].get('type')
        print "\nFound '%s' at args '%s'" % \
            (uhd_type1, args1)

        stream_args = uhd.stream_args('fc32')
        self.u_tx = uhd.usrp_sink(device_addr=args1, stream_args=stream_args)
        self.u_tx.set_samp_rate(SAMPLE_RATE)
        self.u_tx.set_clock_source("external")
        self.center_freq = END_FREQ
        self.tr = uhd.tune_request(self.center_freq)
        self.tr.args = uhd.device_addr_t("mode_n=integer")
        self.u_tx.set_center_freq(self.tr)
        self.u_tx.set_bandwidth(SAMPLE_RATE*1.5);

        # Get dboard gain range and select maximum
        tx_gain_range = self.u_tx.get_gain_range()
        tx_gain = tx_gain_range.stop()
        self.u_tx.set_gain(tx_gain-9)

        self.connect (self.vec_tx_src, self.tx_src, self.u_tx)

        ##############################
        # RECEIVE CHAIN
        ##############################
        print "\nRECEIVE CHAIN"

        #USRP logs IQ data to file
        #This PMT dictionary stuff is stupid, however it's required otherwise the header will become corrupted...
        key = pmt.intern("rx_freq")
        val = pmt.from_double(0)
        extras = pmt.make_dict()
        extras = pmt.dict_add(extras, key, val)
        extras = pmt.serialize_str(extras)

        self.tag_debug = None
        self.u_rxs = []
        
        for usrp_addr in args2.split(","):
            kv = usrp_addr.split("=")
            rx_dst = blocks.file_meta_sink(gr.sizeof_gr_complex*SIGNAL_LEN, "iq_out_{}.dat".format(kv[1]), SAMPLE_RATE, extra_dict=extras)#, detached_header=True)
            #rx_dst = blocks.file_sink(gr.sizeof_gr_complex*SIGNAL_LEN, "iq_out.dat")

            # Accumulate repeating sequences using custom block
            rx_accum = slocalization.accumulator_vcvc(SIGNAL_LEN, int(1e3))

            #Find USRP with device characteristics specified by args1
            d2 = uhd.find_devices(uhd.device_addr(usrp_addr))
            uhd_type2 = d2[0].get('type')
            print "\nFound '%s' at args '%s'" % \
                (uhd_type2, usrp_addr)

            u_rx = uhd.usrp_source(device_addr=usrp_addr,
                                   io_type=uhd.io_type.COMPLEX_FLOAT32,
                                   num_channels=1)
            u_rx.set_samp_rate(SAMPLE_RATE)
            u_rx.set_bandwidth(SAMPLE_RATE*1.5);
            u_rx.set_clock_source("external")
            u_rx.set_center_freq(self.tr)
            self.u_rxs.append(u_rx)

            # Get dboard gain range and select maximum
            rx_gain_range = u_rx.get_gain_range()
            rx_gain = rx_gain_range.stop()
            u_rx.set_gain(rx_gain, 0)

            # Convert stream to vector
            s_to_v = blocks.stream_to_vector(gr.sizeof_gr_complex, SIGNAL_LEN)

            self.connect (u_rx, s_to_v, rx_accum, rx_dst)
            #self.connect (u_rx, s_to_v, rx_dst)

            if not self.tag_debug:
                # DEBUG: Monitor incoming tags...
                self.tag_debug = blocks.tag_debug(gr.sizeof_gr_complex*SIGNAL_LEN, "tag_debugger", "")
                self.connect (rx_accum, self.tag_debug)

        # Synchronize both USRPs' timebases
        u_rx.set_time_now(uhd.time_spec(0.0))
        self.u_tx.set_time_now(uhd.time_spec(0.0))

    def increment_channel(self):
        self.center_freq = self.center_freq + STEP_FREQ
        if self.center_freq > END_FREQ:
            self.center_freq = START_FREQ
        print "Setting frequency to %f" % (self.center_freq)
        self.tr = uhd.tune_request(self.center_freq)
        self.tr.args = uhd.device_addr_t("mode_n=integer")
        self.u_tx.set_center_freq(self.tr)
        progress_frac = (self.center_freq-START_FREQ)/(END_FREQ-START_FREQ)
        tx_gain = (1-progress_frac)*START_TX_GAIN + progress_frac*END_TX_GAIN
        print("setting tx gain to {}...".format(tx_gain))
        self.u_tx.set_gain(tx_gain) #TX (and RX) gain is inconsistent across freuqency, so we compensate...
        for u_rx in self.u_rxs:
            u_rx.set_center_freq(self.tr)

    def switch_to_direct_feed(self):
        for u_rx in self.u_rxs:
            u_rx.set_antenna("RX2")

    def switch_to_overair(self):
        for u_rx in self.u_rxs:
            u_rx.set_antenna("TX/RX")

def main ():
    parser = OptionParser (option_class=eng_option)
    parser.add_option("-a", "--args1", type="string", default="addr=192.168.130.2",
                      help="TX UHD device (#1) address args [default=%default]")
    parser.add_option("-A", "--args2", type="string", default="addr=192.168.130.2",
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
