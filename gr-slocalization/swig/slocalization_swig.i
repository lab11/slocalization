/* -*- c++ -*- */

#define SLOCALIZATION_API

%include "gnuradio.i"			// the common stuff

//load generated python docstrings
%include "slocalization_swig_doc.i"

%{
#include "slocalization/accumulator_vcvc.h"
%}


%include "slocalization/accumulator_vcvc.h"
GR_SWIG_BLOCK_MAGIC2(slocalization, accumulator_vcvc);
