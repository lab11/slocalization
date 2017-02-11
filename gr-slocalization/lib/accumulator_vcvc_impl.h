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

#ifndef INCLUDED_SLOCALIZATION_ACCUMULATOR_VCVC_IMPL_H
#define INCLUDED_SLOCALIZATION_ACCUMULATOR_VCVC_IMPL_H

#include <slocalization/accumulator_vcvc.h>

namespace gr {
  namespace slocalization {

    class accumulator_vcvc_impl : public accumulator_vcvc
    {
     private:
      std::vector<gr_complexd> d_k;
      int d_accum_count, d_accum_max;

     public:
      accumulator_vcvc_impl(int vector_len, int num_accums);
      ~accumulator_vcvc_impl();

      // Where all the action really happens
      void forecast (int noutput_items, gr_vector_int &ninput_items_required);

      int general_work(int noutput_items,
           gr_vector_int &ninput_items,
           gr_vector_const_void_star &input_items,
           gr_vector_void_star &output_items);
    };

  } // namespace slocalization
} // namespace gr

#endif /* INCLUDED_SLOCALIZATION_ACCUMULATOR_VCVC_IMPL_H */

