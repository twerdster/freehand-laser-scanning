#include <math.h>
#include <matrix.h>
#include <mex.h>


typedef struct pixel
{
    double R;
    double G;
    double B;
}pixel;
            
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    //declare variables
  mxArray *a_in_m, *c_out_m;
  const mwSize *dims;
  mwSize newDims[2];
  pixel *pix;
  double *class;
  int dimx, dimy, numdims;
  
  //associate inputs
  a_in_m = mxDuplicateArray(prhs[0]);
  
  
  //figure out dimensions
  dims = mxGetDimensions(prhs[0]);
  numdims = mxGetNumberOfDimensions(prhs[0]);
  dimy = (int)dims[0]; dimx = (int)dims[1];
  newDims[0] = dimx; newDims[1] = 1;
  
  //associate outputs
  c_out_m = plhs[0] = mxCreateNumericArray(1, newDims, mxDOUBLE_CLASS, mxREAL);

  
  
  pix = (pixel*) mxGetPr(a_in_m);
  
  class = mxGetPr(c_out_m);
  
  int i;
  float f1,f2,f3;

  for (i=0 ; i<dimx ; i++)
  {
     f1=pix[i].R;
     f2=pix[i].G;
     f3=pix[i].B;
     //mexPrintf("%f %f %f\n",f1,f2,f3);
     
     // tree goes here 
     
    if ( f2 > -6.0912){
        if ( f2 > -18.0082){
            if ( f2 > -39.5773){
                if ( f2 > -60.3412){
                    if ( f3 > -50.34){
                        //leaf
                        class[i] = 0;
                    } else {
                        //leaf
                        class[i] = 0;
                    }
                } else {
                    if ( f1 > 64.6333){
                        //leaf
                        class[i] = 0;
                    } else {
                        //leaf
                        class[i] = 0;
                    }
                }
            } else {
                if ( f3 > -7.4773){
                    if ( f1 > 58.259){
                        //leaf
                        class[i] = 1;
                    } else {
                        //leaf
                        class[i] = 0;
                    }
                } else {
                    if ( f3 > 2.5507){
                        //leaf
                        class[i] = 0;
                    } else {
                        //leaf
                        class[i] = 0;
                    }
                }
            }
        } else {
            if ( f3 > -1.6298){
                if ( f3 > -6.9741){
                    if ( f3 > -24.0453){
                        //leaf
                        class[i] = 1;
                    } else {
                        //leaf
                        class[i] = 1;
                    }
                } else {
                    if ( f1 > -90.99){
                        //leaf
                        class[i] = 0;
                    } else {
                        //leaf
                        class[i] = 1;
                    }
                }
            } else {
                if ( f3 > 5.7005){
                    if ( f1 > -83.3509){
                        //leaf
                        class[i] = 0;
                    } else {
                        //leaf
                        class[i] = 0;
                    }
                } else {
                    //leaf
                    class[i] = 0;
                }
            }
        }
    } else {
        if ( f1 > -59.9351){
            if ( f2 > 17.8065){
                if ( f1 > -123.4523){
                    if ( f3 > -0.44527){
                        //leaf
                        class[i] = 1;
                    } else {
                        //leaf
                        class[i] = 0;
                    }
                } else {
                    if ( f2 > 9.6972){
                        //leaf
                        class[i] = 1;
                    } else {
                        //leaf
                        class[i] = 1;
                    }
                }
            } else {
                if ( f1 > -60.076){
                    if ( f1 > -60.148){
                        //leaf
                        class[i] = 1;
                    } else {
                        //leaf
                        class[i] = 1;
                    }
                } else {
                    //leaf
                    class[i] = 1;
                }
            }
        } else {
            if ( f3 > 49.1539){
                if ( f3 > 41.5537){
                    if ( f3 > 38.6978){
                        //leaf
                        class[i] = 1;
                    } else {
                        //leaf
                        class[i] = 0;
                    }
                } else {
                    //leaf
                    class[i] = 0;
                }
            } else {
                if ( f1 > 59.5369){
                    //leaf
                    class[i] = 1;
                } else {
                    //leaf
                    class[i] = 0;
                }
            }
        }
    }
     
     //
  }
  
  
  
  
  
}

