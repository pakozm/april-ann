/*
 * This file is part of the Neural Network modules of the APRIL toolkit (A
 * Pattern Recognizer In Lua).
 *
 * Copyright 2012, Salvador España-Boquera, Adrian Palacios Corella, Francisco
 * Zamora-Martinez
 *
 * The APRIL-ANN toolkit is free software; you can redistribute it and/or modify it
 * under the terms of the GNU General Public License version 3 as
 * published by the Free Software Foundation
 *
 * This library is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License
 * for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this library; if not, write to the Free Software Foundation,
 * Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
 *
 */
#ifndef ACTFCOMPONENT_H
#define ACTFCOMPONENT_H

#include "ann_component.h"

namespace ANN {

  /// An abstract class that defines the basic interface that
  /// the anncomponents must fulfill.
  class ActivationFunctionANNComponent : public Referenced {
    TokenMemoryBlock *input, *output, *error_input, *error_output;
    unsigned int bunch_size;
  protected:
    virtual void applyActivation(FloatGPUMirroredMemoryBlock *input_units,
				 FloatGPUMirroredMemoryBlock *output_units,
				 unsigned int size,
				 unsigned int bunch_size) = 0;
    virtual void multiplyDerivatives(FloatGPUMirroredMemoryBlock *input_units,
				     FloatGPUMirroredMemoryBlock *output_units,
				     FloatGPUMirroredMemoryBlock *input_errors,
				     FloatGPUMirroredMemoryBlock *output_errors,
				     unsigned int size,
				     unsigned int bunch_size,
				     bool is_output) = 0;
  public:
    ActivationFunctionANNComponent(const char *name);
    virtual ~ActivationFunctionANNComponent();
    
    virtual const Token *getInput() const { return input; }
    virtual const Token *getOutput() const { return output; }
    virtual const Token *getErrorInput() const { return error_input; }
    virtual const Token *getErrorOutput() const { return error_output; }
    
    virtual Token *doForward(Token* input, bool during_training);
    
    virtual Token *doBackprop(Token *input_error);

    virtual void reset();
    
    virtual ANNComponent *clone() = 0;
    
    virtual void setOption(const char *name, double value);

    virtual bool hasOption(const char *name);
    
    virtual double getOption(const char *name) { return 0.0; }
    
    virtual void build(unsigned int _input_size,
		       unsigned int _output_size,
		       hash<string,Connections*> &weights_dict,
		       hash<string,ANNComponent*> &components_dict);
  };
}

#endif // ACTFCOMPONENT_H
