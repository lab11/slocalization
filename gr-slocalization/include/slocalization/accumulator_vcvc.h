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


#ifndef INCLUDED_SLOCALIZATION_ACCUMULATOR_VCVC_H
#define INCLUDED_SLOCALIZATION_ACCUMULATOR_VCVC_H

#include <slocalization/api.h>
#include <gnuradio/block.h>

namespace gr {
  namespace slocalization {

    /*!
     * \brief <+description of block+>
     * \ingroup slocalization
     *
     */
    class SLOCALIZATION_API accumulator_vcvc : virtual public gr::block
    {
     public:
      typedef boost::shared_ptr<accumulator_vcvc> sptr;

      /*!
       * \brief Return a shared_ptr to a new instance of slocalization::accumulator_vcvc.
       *
       * To avoid accidental use of raw pointers, slocalization::accumulator_vcvc's
       * constructor is in a private implementation
       * class. slocalization::accumulator_vcvc::make is the public interface for
       * creating new instances.
       */
      static sptr make(int vector_len, int num_accums);
    };

  } // namespace slocalization
} // namespace gr

#endif /* INCLUDED_SLOCALIZATION_ACCUMULATOR_VCVC_H */

