/*
 * This file is part of APRIL-ANN toolkit (A
 * Pattern Recognizer In Lua with Artificial Neural Networks).
 *
 * Copyright 2013, Salvador España-Boquera, Francisco Zamora-Martinez
 * Copyright 2012, Salvador España-Boquera
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
#include "cmath_overloads.h"
#include "mathcore.h"
#include "matrix.h"
#include "maxmin.h"
#include "realfftwithhamming.h"
#include "smart_ptr.h"
#include "sparse_matrix.h"

// Must be defined in this order.
#include "matrix_ext_misc.h"

// Must to be defined here.
#include "map_matrix.h"
#include "map_sparse_matrix.h"

// Must to be defined here.
#include "reduce_matrix.h"
#include "reduce_sparse_matrix.h"

using Basics::Matrix;
using Basics::SparseMatrix;

namespace AprilMath {
  namespace MatrixExt {
    
    namespace Misc {
      //////////////////// OTHER MATH OPERATIONS ////////////////////
    
      template <typename T>
      Matrix<T> *matAddition(const Matrix<T> *a,
                             const Matrix<T> *b,
                             Matrix<T> *c) {
        if (c == 0) c = a->clone();
        return AprilMath::MatrixExt::BLAS::matAxpy(c, T(1.0f), b);
      }

      template <typename T>
      Matrix<T> *matSubstraction(const Matrix<T> *a,
                                 const Matrix<T> *b,
                                 Matrix<T> *c) {
        if (c == 0) c = a->clone();
        return AprilMath::MatrixExt::BLAS::matAxpy(c, T(-1.0f), b);
      }
    
      template <typename T>
      Matrix<T> *matMultiply(const Matrix<T> *a,
                             const Matrix<T> *b,
                             Matrix<T> *c) {
        if (b->isVector()) {
          if (a->isColVector()) {
            // OUTER product
            int dim[2] = {a->size(),b->size()};
            if (c == 0) {
              c = new Matrix<T>(2, dim);
#ifdef USE_CUDA
              c->setUseCuda(a->getCudaFlag() || b->getCudaFlag());
#endif
            }
            else if (!c->sameDim(dim, 2)) {
              ERROR_EXIT2(128, "Incorrect matrix sizes, expected %dx%d\n",
                          dim[0], dim[1]);
            }
            AprilMath::MatrixExt::BLAS::
              matGer(AprilMath::MatrixExt::Initializers::matZeros(c),
                     T(1.0f), a, b);
          }
          else if (!a->isVector()) {
            // Matrix-Vector product
            int dim[2] = {a->getDimSize(0),1};
            if (c == 0) {
              c = new Matrix<T>(b->getNumDim(), dim);
#ifdef USE_CUDA
              c->setUseCuda(a->getCudaFlag() || b->getCudaFlag());
#endif
            }
            else if (!c->sameDim(dim, b->getNumDim())) {
              ERROR_EXIT2(128, "Incorrect matrix sizes, expected %dx%d\n",
                          dim[0], dim[1]);
            }
            AprilMath::MatrixExt::BLAS::
              matGemv(AprilMath::MatrixExt::Initializers::matZeros(c),
                      CblasNoTrans, T(1.0f), a, b, T());
          }
          else {
            // DOT product
            int dim[2] = {1,1};
            if (c == 0) {
              c = new Matrix<T>(a->getNumDim(), dim);
#ifdef USE_CUDA
              c->setUseCuda(a->getCudaFlag() || b->getCudaFlag());
#endif
            }
            else if (!c->sameDim(dim, a->getNumDim())) {
              ERROR_EXIT2(128, "Incorrect matrix sizes, expected %dx%d\n",
                          dim[0], dim[1]);
            }
            c->getRawDataAccess()->putValue( c->getOffset(),
                                             AprilMath::MatrixExt::BLAS::
                                             matDot(a, b) );
          }
        }
        else if (a->getNumDim() == 2 && b->getNumDim() == 2 &&
                 a->getDimSize(1) == b->getDimSize(0)) {
          // Matrix-Matrix product
          int dim[2] = {a->getDimSize(0), b->getDimSize(1)};
          if (c == 0) {
            c = new Matrix<T>(2,dim);
#ifdef USE_CUDA
              c->setUseCuda(a->getCudaFlag() || b->getCudaFlag());
#endif
          }
          else if (!c->sameDim(dim,2)) {
            ERROR_EXIT2(128, "Incorrect matrix sizes, expected %dx%d\n",
                        dim[0], dim[1]);
          }
          AprilMath::MatrixExt::BLAS::
            matGemm(AprilMath::MatrixExt::Initializers::matZeros(c),
                    CblasNoTrans, CblasNoTrans,
                    T(1.0f), a, b, T());
        }
        else {
          ERROR_EXIT(128, "Incompatible matrix sizes\n");
        }
        return c;
      }
      
      
      Basics::Matrix<float> *matRealFFTwithHamming(Basics::Matrix<float> *obj,
						   int wsize,
						   int wadvance,
						   Basics::Matrix<float> *dest) {
	const int N = obj->getNumDim();
	if (N != 1) ERROR_EXIT(128, "Only valid for numDim=1\n");
	if (wsize > obj->size() || wadvance > obj->size()) {
	  ERROR_EXIT(128, "Incompatible wsize or wadvance value\n");
	}
	AprilMath::RealFFTwithHamming real_fft(wsize);
	const int M = real_fft.getOutputSize();
	AprilUtils::UniquePtr<int []> dest_size(new int[N+1]);
	dest_size[0] = (obj->getDimSize(0) - wsize)/wadvance + 1;
	dest_size[1] = M;
	if (dest != 0) {
	  if (!dest->sameDim(dest_size.get(), N+1)) {
	    ERROR_EXIT(128, "Incompatible dest matrix\n");
	  }
	}
	else {
	  dest = new Matrix<float>(N+1, dest_size.get());
#ifdef USE_CUDA
	  dest->setUseCuda(obj->getCudaFlag());
#endif
	}
	AprilUtils::UniquePtr<double []> input(new double[wsize]);
	AprilUtils::UniquePtr<double []> output(new double[M]);
	//
	Basics::Matrix<float>::sliding_window swindow(obj,
                                                      &wsize,
                                                      0, // offset
                                                      &wadvance);
	AprilUtils::SharedPtr< Matrix<float> > input_slice;
	AprilUtils::SharedPtr< Matrix<float> > output_slice;
	int i=0, j;
	while(!swindow.isEnd()) {
	  april_assert(i < dest_size[0]);
	  input_slice = swindow.getMatrix(input_slice.get());
	  output_slice = dest->select(0, i);
	  j=0;
	  for (Basics::Matrix<float>::const_iterator it(input_slice->begin());
	       it != input_slice->end(); ++it, ++j) {
	    april_assert(j<wsize);
	    input[j] = static_cast<double>(*it);
	  }
	  april_assert(j==wsize);
	  real_fft(input.get(), output.get());
	  j=0;
	  for (Basics::Matrix<float>::iterator it(output_slice->begin());
	       it != output_slice->end(); ++it, ++j) {
	    april_assert(j<M);
	    *it = static_cast<float>(output[j]);
	  }
	  april_assert(j==M);
	  ++i;
	  swindow.next();
	}
	april_assert(i == dest_size[0]);
	return dest;
      }

      template Matrix<float> *matAddition(const Matrix<float> *,
                                          const Matrix<float> *,
                                          Matrix<float> *);

      template Matrix<float> *matSubstraction(const Matrix<float> *,
                                              const Matrix<float> *,
                                              Matrix<float> *);
      template Matrix<float> *matMultiply(const Matrix<float> *,
                                          const Matrix<float> *,
                                          Matrix<float> *);

      template Matrix<double> *matAddition(const Matrix<double> *,
                                          const Matrix<double> *,
                                          Matrix<double> *);

      template Matrix<double> *matSubstraction(const Matrix<double> *,
                                              const Matrix<double> *,
                                              Matrix<double> *);
      template Matrix<double> *matMultiply(const Matrix<double> *,
                                          const Matrix<double> *,
                                          Matrix<double> *);    


      template Matrix<ComplexF> *matAddition(const Matrix<ComplexF> *,
                                          const Matrix<ComplexF> *,
                                          Matrix<ComplexF> *);

      template Matrix<ComplexF> *matSubstraction(const Matrix<ComplexF> *,
                                                 const Matrix<ComplexF> *,
                                                 Matrix<ComplexF> *);
      template Matrix<ComplexF> *matMultiply(const Matrix<ComplexF> *,
                                             const Matrix<ComplexF> *,
                                             Matrix<ComplexF> *);    

      
    } // namespace Misc
    
  } // namespace MatrixExt
} // namespace AprilMath
