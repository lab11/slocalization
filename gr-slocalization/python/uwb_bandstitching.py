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

n2s = eng_notation.num_to_str

SAMPLE_RATE = 1000e6

class build_block(gr.top_block):
    def __init__(self, args1, args2):
        gr.top_block.__init__(self)

        #Find USRP with device characteristics specified by args1
        d1 = uhd.find_devices(uhd.device_addr(args1))
        uhd_type1 = d1[0].get('type')
        print "\nFound '%s' at args '%s'" % \
            (uhd_type1, args1)

        #Find USRP with device characteristics specified by args1
        d2 = uhd.find_devices(uhd.device_addr(args2))
        uhd_type2 = d2[0].get('type')
        print "\nFound '%s' at args '%s'" % \
            (uhd_type2, args2)

        print "\nTRANSMIT CHAIN"
        stream_args = uhd.stream_args('fc32')
        self.u_tx = uhd.usrp_sink(device_addr=args1, stream_args=stream_args)
        self.u_tx.set_samp_rate(SAMPLE_RATE)

        self.tx_src0 = analog.sig_source_c(self.u_tx.get_samp_rate(),
                                           analog.GR_CONST_WAVE,
                                           0, 1.0, 0)

        # Get dboard gain range and select maximum
        tx_gain_range = self.u_tx.get_gain_range()
        tx_gain = tx_gain_range.stop()

        # Get dboard freq range and select midpoint
        tx_freq_range = self.u_tx.get_freq_range()
        tx_freq_mid = (tx_freq_range.start() + tx_freq_range.stop())/2.0

        for i in xrange(tx_nchan):
            self.u_tx.set_center_freq (tx_freq_mid + i*1e6, i)
            self.u_tx.set_gain(tx_gain, i)

        print "\nTx Sample Rate: %ssps" % (n2s(self.u_tx.get_samp_rate()))
        for i in xrange(tx_nchan):
            print "Tx Channel %d: " % (i)
            print "\tFrequency = %sHz" % \
                (n2s(self.u_tx.get_center_freq(i)))
            print "\tGain = %f dB" % (self.u_tx.get_gain(i))
        print ""

        self.connect (self.tx_src0, self.u_tx)

        print "\nRECEIVE CHAIN"
        self.u_rx = uhd.usrp_source(device_addr=args2,
                                    io_type=uhd.io_type.COMPLEX_FLOAT32,
                                    num_channels=rx_nchan)
        self.rx_dst0 = blocks.null_sink(gr.sizeof_gr_complex)

        self.u_rx.set_samp_rate(SAMPLE_RATE)

        # Get dboard gain range and select maximum
        rx_gain_range = self.u_rx.get_gain_range()
        rx_gain = rx_gain_range.stop()

        # Get dboard freq range and select midpoint
        rx_freq_range = self.u_rx.get_freq_range()
        rx_freq_mid = (rx_freq_range.start() + rx_freq_range.stop())/2.0

        for i in xrange(tx_nchan):
            self.u_rx.set_center_freq (rx_freq_mid + i*1e6, i)
            self.u_rx.set_gain(rx_gain, i)

        print "\nRx Sample Rate: %ssps" % (n2s(self.u_rx.get_samp_rate()))
        for i in xrange(rx_nchan):
            print "Rx Channel %d: " % (i)
            print "\tFrequency = %sHz" % \
                (n2s(self.u_rx.get_center_freq(i)))
            print "\tGain = %f dB" % (self.u_rx.get_gain(i))
        print ""

        self.connect (self.u_rx, self.rx_dst0)

def main ():
    parser = OptionParser (option_class=eng_option)
    parser.add_option("-a1", "--args1", type="string", default="",
                      help="TX UHD device (#1) address args [default=%default]")
    parser.add_option("-a2", "--args2", type="string", default="",
                      help="RX UHD device (#2) address args [default=%default]")
    (options, args) = parser.parse_args ()

    tb = build_block (options.args1, options.args2)

    tb.start ()
    raw_input ('Press Enter to quit: ')
    tb.stop ()

if __name__ == '__main__':
    main ()
