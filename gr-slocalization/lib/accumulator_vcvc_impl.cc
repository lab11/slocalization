/* -*- c++ -*- */
/* 
 * Copyright 2017 <+YOU OR YOUR COMPANY+>.
 * 
 * This is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 3, or (at your option)
 * any later version.
 * 
 * This software is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this software; see the file COPYING.  If not, write to
 * the Free Software Foundation, Inc., 51 Franklin Street,
 * Boston, MA 02110-1301, USA.
 */

#ifdef HAVE_CONFIG_H
#include "config.h"
#endif

#include <gnuradio/io_signature.h>
#include "accumulator_vcvc_impl.h"

namespace gr {
  namespace slocalization {

    accumulator_vcvc::sptr
    accumulator_vcvc::make(int vector_len, int num_accums)
    {
      return gnuradio::get_initial_sptr
        (new accumulator_vcvc_impl(vector_len, num_accums));
    }

    /*
     * The private constructor
     */
    accumulator_vcvc_impl::accumulator_vcvc_impl(int vector_len, int num_accums)
      : gr::block("accumulator_vcvc",
              gr::io_signature::make(1, 1, sizeof(gr_complex)*vector_len),
              gr::io_signature::make(1, 1, sizeof(gr_complex)*vector_len))
    {
      d_accum_count = 0;
      d_accum_max = num_accums;
      d_k.reserve(vector_len);
      for(int ii=0; ii < vector_len; ii++){
        d_k[ii] = gr_complexd(0, 0);
      }
      set_relative_rate(1./num_accums);
    }

    /*
     * Our virtual destructor.
     */
    accumulator_vcvc_impl::~accumulator_vcvc_impl()
    {
    }

    void
    accumulator_vcvc_impl::forecast (int noutput_items, gr_vector_int &ninput_items_required)
    {
      /* <+forecast+> e.g. ninput_items_required[0] = noutput_items */
      ninput_items_required[0] = noutput_items;
    }

    int
    accumulator_vcvc_impl::general_work (int noutput_items,
                       gr_vector_int &ninput_items,
                       gr_vector_const_void_star &input_items,
                       gr_vector_void_star &output_items)
    {
      const gr_complex *in = (const gr_complex *) input_items[0];
      gr_complex *out = (gr_complex *) output_items[0];

      int nitems_per_block = output_signature()->sizeof_stream_item(0)/sizeof(gr_complex);
      int nitems_produced = 0;

      // Simply accumulate until we need to dump the output
      for(int ii = 0; ii < noutput_items; ii++){
        // Add to the accumulator any incoming samples
        for(int jj = 0; jj < nitems_per_block; jj++){
          d_k[jj] += *in++;
        }
        d_accum_count++;

        // Every d_accum_max vectors received, output one
        if(d_accum_count == d_accum_max){
          d_accum_count = 0;
          nitems_produced++;
          
          // Reset the accumulator for next round...
          for(int jj=0; jj < nitems_per_block; jj++){
            *out++ = d_k[jj];
            d_k[jj] = gr_complexd(0, 0);
          }
        }
      }

      // Tell runtime system how many input items we consumed on
      // each input stream.
      consume_each (noutput_items);

      // Tell runtime system how many output items we produced.
      return nitems_produced;
    }

  } /* namespace slocalization */
} /* namespace gr */

