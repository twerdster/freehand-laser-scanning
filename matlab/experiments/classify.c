#include <math.h>
#include <matrix.h>
#include <mex.h>


typedef struct pixel
{
    double R;
    double G;
    double B;
    double H;
    double S;
    double V;
}pixel;
            
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    //declare variables
  mxArray *a_in_m, *c_out_m;
  const mwSize *dims;
  mwSize newDims[2];
  pixel *pix;
  double *data;
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
  
  data = mxGetPr(c_out_m);
  
  int i;
  float f1,f2,f3,f4,f5,f6;

  for (i=0 ; i<dimx ; i++)
  {
     f1=pix[i].R;
     f2=pix[i].G;
     f3=pix[i].B;
     f4=pix[i].H;
     f5=pix[i].S;
     f6=pix[i].V;
if ( f4 < 0.91709){
if ( f4 < 0.027668){
if ( f5 < 0.37044){
if ( f5 < 0.30785){
if ( f5 < 0.29349){
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
} else {
if ( f1 < 230){
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
} else {
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
}
}
} else {
if ( f1 < 219){
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
} else {
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
}
}
} else {
if ( f1 < 157.5){
if ( f5 < 0.50497){
if ( f4 < 0.024911){
if ( f5 < 0.38832){
if ( f5 < 0.38776){
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
} else {
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
}
} else {
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
}
} else {
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
}
} else {
if ( f1 < 93.5){
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
} else {
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
}
}
} else {
if ( f1 < 167.5){
if ( f2 < 79.5){
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
} else {
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
}
} else {
if ( f1 < 213.5){
if ( f5 < 0.41581){
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
} else {
if ( f4 < 0.019482){
if ( f3 < 117.5){
if ( f4 < 0.015419){
if ( f1 < 176.5){
if ( f4 < 0.0062671){
if ( f1 < 174.5){
if ( f4 < 0.0060104){
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
} else {
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
}
} else {
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
}
} else {
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
}
} else {
if ( f1 < 210.5){
if ( f3 < 101.5){
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
} else {
if ( f2 < 105.5){
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
} else {
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
}
}
} else {
if ( f2 < 94.5){
if ( f4 < 0.0076638){
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
} else {
if ( f3 < 87.5){
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
} else {
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
}
}
} else {
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
}
}
}
} else {
if ( f4 < 0.015448){
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
} else {
if ( f4 < 0.01784){
if ( f4 < 0.017703){
if ( f5 < 0.6005){
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
} else {
if ( f2 < 90.5){
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
} else {
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
}
}
} else {
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
}
} else {
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
}
}
}
} else {
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
}
} else {
if ( f1 < 193.5){
if ( f5 < 0.62408){
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
} else {
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
}
} else {
if ( f4 < 0.019564){
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
} else {
if ( f3 < 98.5){
if ( f1 < 205.5){
if ( f4 < 0.019808){
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
} else {
if ( f4 < 0.023427){
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
} else {
if ( f4 < 0.023605){
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
} else {
if ( f2 < 98.5){
if ( f2 < 95.5){
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
} else {
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
}
} else {
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
}
}
}
}
} else {
if ( f4 < 0.021277){
if ( f4 < 0.021092){
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
} else {
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
}
} else {
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
}
}
} else {
if ( f2 < 118){
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
} else {
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
}
}
}
}
}
}
} else {
if ( f1 < 227.5){
if ( f2 < 126.5){
if ( f4 < 0.012195){
if ( f2 < 94.5){
if ( f2 < 93.5){
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
} else {
if ( f5 < 0.59817){
if ( f5 < 0.59552){
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
} else {
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
}
} else {
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
}
}
} else {
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
}
} else {
if ( f4 < 0.012195){
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
} else {
if ( f5 < 0.48174){
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
} else {
if ( f1 < 223.5){
if ( f3 < 97.5){
if ( f4 < 0.016327){
if ( f4 < 0.015326){
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
} else {
if ( f4 < 0.015395){
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
} else {
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
}
}
} else {
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
}
} else {
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
}
} else {
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
}
}
}
}
} else {
if ( f4 < 0.027246){
if ( f4 < 0.023704){
if ( f3 < 119){
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
} else {
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
}
} else {
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
}
} else {
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
}
}
} else {
if ( f1 < 236.5){
if ( f2 < 140.5){
if ( f1 < 235.5){
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
} else {
if ( f4 < 0.021654){
if ( f4 < 0.0013551){
if ( f4 < 0.0013282){
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
} else {
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
}
} else {
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
}
} else {
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
}
}
} else {
if ( f2 < 141.5){
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
} else {
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
}
}
} else {
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
}
}
}
}
}
}
} else {
if ( f4 < 0.90035){
if ( f4 < 0.83436){
if ( f4 < 0.033206){
if ( f5 < 0.35306){
if ( f1 < 251.5){
if ( f5 < 0.29217){
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
} else {
if ( f1 < 198.5){
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
} else {
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
}
}
} else {
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
}
} else {
if ( f1 < 177.5){
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
} else {
if ( f1 < 217.5){
if ( f2 < 116.5){
if ( f2 < 104.5){
if ( f2 < 99){
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
} else {
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
}
} else {
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
}
} else {
if ( f5 < 0.52123){
if ( f1 < 199){
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
} else {
if ( f4 < 0.032833){
if ( f2 < 133.5){
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
} else {
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
}
} else {
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
}
}
} else {
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
}
}
} else {
if ( f2 < 148){
if ( f2 < 145.5){
if ( f4 < 0.029333){
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
} else {
if ( f5 < 0.5618){
if ( f2 < 122){
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
} else {
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
}
} else {
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
}
}
} else {
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
}
} else {
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
}
}
}
}
} else {
if ( f4 < 0.041209){
if ( f5 < 0.35048){
if ( f4 < 0.040783){
if ( f5 < 0.26975){
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
} else {
if ( f1 < 216){
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
} else {
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
}
}
} else {
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
}
} else {
if ( f1 < 193.5){
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
} else {
if ( f5 < 0.47316){
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
} else {
if ( f3 < 97.5){
if ( f4 < 0.038624){
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
} else {
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
}
} else {
if ( f5 < 0.48917){
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
} else {
if ( f1 < 222.5){
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
} else {
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
}
}
}
}
}
}
} else {
if ( f4 < 0.80796){
if ( f4 < 0.060606){
if ( f4 < 0.060606){
if ( f5 < 0.22245){
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
} else {
if ( f1 < 229){
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
} else {
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
}
}
} else {
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
}
} else {
if ( f4 < 0.77992){
if ( f1 < 243.5){
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
} else {
if ( f2 < 224.5){
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
} else {
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
}
}
} else {
if ( f5 < 0.37265){
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
} else {
if ( f1 < 104){
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
} else {
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
}
}
}
}
} else {
if ( f5 < 0.44686){
if ( f5 < 0.31062){
if ( f5 < 0.22336){
if ( f1 < 227.5){
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
} else {
if ( f2 < 217){
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
} else {
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
}
}
} else {
if ( f1 < 126){
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
} else {
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
}
}
} else {
if ( f1 < 85){
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
} else {
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
}
}
} else {
if ( f1 < 66.5){
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
} else {
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
}
}
}
}
}
} else {
if ( f5 < 0.47295){
if ( f1 < 227.5){
if ( f4 < 0.84314){
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
} else {
if ( f5 < 0.33512){
if ( f1 < 225.5){
if ( f5 < 0.28239){
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
} else {
if ( f1 < 129.5){
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
} else {
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
}
}
} else {
if ( f5 < 0.068282){
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
} else {
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
}
}
} else {
if ( f3 < 142.5){
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
} else {
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
}
}
}
} else {
if ( f2 < 219.5){
if ( f1 < 229.5){
if ( f2 < 210.5){
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
} else {
if ( f4 < 0.86563){
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
} else {
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
}
}
} else {
if ( f4 < 0.84286){
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
} else {
if ( f5 < 0.096764){
if ( f2 < 209.5){
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
} else {
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
}
} else {
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
}
}
}
} else {
if ( f5 < 0.06598){
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
} else {
if ( f5 < 0.077396){
if ( f1 < 249.5){
if ( f3 < 241){
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
} else {
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
}
} else {
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
}
} else {
if ( f4 < 0.89868){
if ( f4 < 0.87958){
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
} else {
if ( f4 < 0.88145){
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
} else {
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
}
}
} else {
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
}
}
}
}
}
} else {
if ( f2 < 39.5){
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
} else {
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
}
}
}
} else {
if ( f1 < 234.5){
if ( f5 < 0.48497){
if ( f1 < 231.5){
if ( f5 < 0.18221){
if ( f4 < 0.90237){
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
} else {
if ( f5 < 0.13564){
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
} else {
if ( f5 < 0.13633){
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
} else {
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
}
}
}
} else {
if ( f1 < 179){
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
} else {
if ( f5 < 0.18885){
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
} else {
if ( f5 < 0.25266){
if ( f1 < 216.5){
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
} else {
if ( f4 < 0.91319){
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
} else {
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
}
}
} else {
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
}
}
}
}
} else {
if ( f5 < 0.079547){
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
} else {
if ( f2 < 197.5){
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
} else {
if ( f2 < 209){
if ( f2 < 200.5){
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
} else {
if ( f4 < 0.90571){
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
} else {
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
}
}
} else {
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
}
}
}
}
} else {
if ( f1 < 70.5){
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
} else {
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
}
}
} else {
if ( f2 < 224.5){
if ( f5 < 0.11452){
if ( f1 < 247.5){
if ( f1 < 235.5){
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
} else {
if ( f2 < 209.5){
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
} else {
if ( f5 < 0.10233){
if ( f4 < 0.90941){
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
} else {
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
}
} else {
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
}
}
}
} else {
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
}
} else {
if ( f5 < 0.15737){
if ( f5 < 0.15714){
if ( f3 < 224.5){
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
} else {
if ( f1 < 237.5){
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
} else {
if ( f2 < 213.5){
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
} else {
if ( f3 < 234.5){
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
} else {
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
}
}
}
}
} else {
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
}
} else {
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
}
}
} else {
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
}
}
}
}
} else {
if ( f5 < 0.167){
if ( f1 < 240.5){
if ( f1 < 236.5){
if ( f1 < 233.5){
if ( f5 < 0.15717){
if ( f5 < 0.10945){
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
} else {
if ( f5 < 0.10956){
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
} else {
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
}
}
} else {
if ( f5 < 0.15755){
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
} else {
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
}
}
} else {
if ( f2 < 215.5){
if ( f3 < 222){
if ( f3 < 213.5){
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
} else {
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
}
} else {
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
}
} else {
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
}
}
} else {
if ( f5 < 0.10042){
if ( f5 < 0.060417){
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
} else {
if ( f1 < 239.5){
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
} else {
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
}
}
} else {
if ( f3 < 220.5){
if ( f5 < 0.14915){
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
} else {
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
}
} else {
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
}
}
}
} else {
if ( f2 < 225.5){
if ( f2 < 218.5){
if ( f4 < 0.9378){
if ( f5 < 0.15886){
if ( f3 < 234.5){
if ( f5 < 0.1127){
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
} else {
if ( f2 < 210.5){
if ( f1 < 247.5){
if ( f4 < 0.91886){
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
} else {
if ( f4 < 0.93661){
if ( f5 < 0.14845){
if ( f4 < 0.92143){
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
} else {
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
}
} else {
if ( f4 < 0.9347){
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
} else {
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
}
}
} else {
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
}
}
} else {
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
}
} else {
if ( f4 < 0.93722){
if ( f2 < 215.5){
if ( f2 < 214.5){
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
} else {
if ( f3 < 228.5){
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
} else {
if ( f4 < 0.92639){
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
} else {
if ( f3 < 231.5){
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
} else {
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
}
}
}
}
} else {
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
}
} else {
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
}
}
}
} else {
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
}
} else {
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
}
} else {
if ( f4 < 0.95766){
if ( f5 < 0.1514){
if ( f5 < 0.10882){
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
} else {
if ( f2 < 217.5){
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
} else {
if ( f1 < 246.5){
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
} else {
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
}
}
}
} else {
if ( f4 < 0.94591){
if ( f1 < 242.5){
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
} else {
if ( f1 < 249.5){
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
} else {
if ( f2 < 210.5){
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
} else {
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
}
}
}
} else {
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
}
}
} else {
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
}
}
} else {
if ( f4 < 0.97096){
if ( f2 < 223.5){
if ( f3 < 231.5){
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
} else {
if ( f3 < 232.5){
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
} else {
if ( f1 < 248.5){
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
} else {
if ( f3 < 234.5){
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
} else {
if ( f1 < 252){
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
} else {
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
}
}
}
}
}
} else {
if ( f4 < 0.94444){
if ( f1 < 247){
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
} else {
if ( f1 < 252.5){
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
} else {
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
}
}
} else {
if ( f4 < 0.94868){
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
} else {
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
}
}
}
} else {
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
}
}
} else {
if ( f2 < 227.5){
if ( f1 < 245){
if ( f4 < 0.92407){
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
} else {
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
}
} else {
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
}
} else {
if ( f5 < 0.047529){
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
} else {
if ( f5 < 0.04849){
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
} else {
if ( f1 < 241.5){
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
} else {
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
}
}
}
}
}
}
} else {
if ( f1 < 73.5){
if ( f5 < 0.61755){
if ( f1 < 68.5){
if ( f5 < 0.56428){
if ( f4 < 0.9219){
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
} else {
if ( f1 < 55.5){
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
} else {
if ( f2 < 33){
if ( f4 < 0.95673){
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
} else {
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
}
} else {
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
}
}
}
} else {
if ( f5 < 0.57418){
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
} else {
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
}
}
} else {
if ( f2 < 35.5){
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
} else {
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
}
}
} else {
if ( f1 < 59){
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
} else {
if ( f1 < 70.5){
if ( f4 < 0.95989){
if ( f2 < 16.5){
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
} else {
if ( f4 < 0.95706){
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
} else {
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
}
}
} else {
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
}
} else {
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
}
}
}
} else {
if ( f1 < 82.5){
if ( f5 < 0.52248){
if ( f4 < 0.94936){
if ( f4 < 0.94748){
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
} else {
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
}
} else {
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
}
} else {
if ( f4 < 0.9393){
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
} else {
if ( f4 < 0.95079){
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
} else {
if ( f3 < 45.5){
if ( f4 < 0.9509){
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
} else {
if ( f5 < 0.64778){
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
} else {
if ( f1 < 80.5){
if ( f1 < 79.5){
if ( f1 < 74.5){
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
} else {
if ( f2 < 23.5){
if ( f4 < 0.9591){
if ( f3 < 33.5){
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
} else {
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
}
} else {
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
}
} else {
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
}
}
} else {
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
}
} else {
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
}
}
}
} else {
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
}
}
}
}
} else {
if ( f5 < 0.53132){
if ( f1 < 161.5){
if ( f4 < 0.96332){
if ( f1 < 104.5){
if ( f5 < 0.4501){
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
} else {
if ( f4 < 0.95438){
if ( f5 < 0.52374){
if ( f5 < 0.4593){
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
} else {
if ( f5 < 0.49747){
if ( f5 < 0.49247){
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
} else {
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
}
} else {
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
}
}
} else {
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
}
} else {
if ( f4 < 0.95876){
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
} else {
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
}
}
}
} else {
if ( f5 < 0.29065){
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
} else {
if ( f2 < 61.5){
if ( f5 < 0.46369){
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
} else {
if ( f1 < 107){
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
} else {
if ( f4 < 0.94533){
if ( f4 < 0.93543){
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
} else {
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
}
} else {
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
}
}
}
} else {
if ( f4 < 0.92951){
if ( f5 < 0.3472){
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
} else {
if ( f2 < 67){
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
} else {
if ( f2 < 98.5){
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
} else {
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
}
}
}
} else {
if ( f1 < 109.5){
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
} else {
if ( f4 < 0.95648){
if ( f4 < 0.95567){
if ( f5 < 0.52337){
if ( f1 < 134.5){
if ( f1 < 118.5){
if ( f5 < 0.44538){
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
} else {
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
}
} else {
if ( f1 < 133.5){
if ( f4 < 0.9482){
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
} else {
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
}
} else {
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
}
}
} else {
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
}
} else {
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
}
} else {
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
}
} else {
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
}
}
}
}
}
}
} else {
if ( f5 < 0.50431){
if ( f5 < 0.45276){
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
} else {
if ( f4 < 0.98843){
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
} else {
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
}
}
} else {
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
}
}
} else {
if ( f1 < 175.5){
if ( f3 < 136.5){
if ( f4 < 0.93293){
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
} else {
if ( f4 < 0.95149){
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
} else {
if ( f4 < 0.95377){
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
} else {
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
}
}
}
} else {
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
}
} else {
if ( f5 < 0.26132){
if ( f1 < 240.5){
if ( f5 < 0.18938){
if ( f4 < 0.92191){
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
} else {
if ( f4 < 0.93672){
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
} else {
if ( f4 < 0.93921){
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
} else {
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
}
}
}
} else {
if ( f1 < 207.5){
if ( f1 < 203){
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
} else {
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
}
} else {
if ( f3 < 198){
if ( f2 < 188.5){
if ( f5 < 0.24609){
if ( f4 < 0.93652){
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
} else {
if ( f5 < 0.24305){
if ( f5 < 0.19513){
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
} else {
if ( f4 < 0.94336){
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
} else {
if ( f4 < 0.94392){
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
} else {
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
}
}
}
} else {
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
}
}
} else {
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
}
} else {
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
}
} else {
if ( f2 < 186.5){
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
} else {
if ( f1 < 233.5){
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
} else {
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
}
}
}
}
}
} else {
if ( f4 < 0.93093){
if ( f4 < 0.92837){
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
} else {
if ( f4 < 0.92857){
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
} else {
if ( f5 < 0.23459){
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
} else {
if ( f5 < 0.23658){
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
} else {
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
}
}
}
}
} else {
if ( f5 < 0.17729){
if ( f1 < 249.5){
if ( f5 < 0.16974){
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
} else {
if ( f4 < 0.93994){
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
} else {
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
}
}
} else {
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
}
} else {
if ( f4 < 0.9311){
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
} else {
if ( f5 < 0.26105){
if ( f4 < 0.93986){
if ( f4 < 0.93969){
if ( f2 < 189.5){
if ( f5 < 0.23711){
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
} else {
if ( f1 < 253.5){
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
} else {
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
}
}
} else {
if ( f1 < 245.5){
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
} else {
if ( f5 < 0.23321){
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
} else {
if ( f5 < 0.23506){
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
} else {
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
}
}
}
}
} else {
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
}
} else {
if ( f5 < 0.20322){
if ( f5 < 0.20238){
if ( f2 < 196.5){
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
} else {
if ( f4 < 0.94562){
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
} else {
if ( f5 < 0.184){
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
} else {
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
}
}
}
} else {
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
}
} else {
if ( f2 < 183.5){
if ( f2 < 182.5){
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
} else {
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
}
} else {
if ( f4 < 0.953){
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
} else {
if ( f3 < 208.5){
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
} else {
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
}
}
}
}
}
} else {
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
}
}
}
}
}
} else {
if ( f1 < 210.5){
if ( f4 < 0.92045){
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
} else {
if ( f2 < 127.5){
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
} else {
if ( f1 < 183.5){
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
} else {
if ( f4 < 0.9396){
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
} else {
if ( f4 < 0.94015){
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
} else {
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
}
}
}
}
}
} else {
if ( f5 < 0.32632){
if ( f5 < 0.32618){
if ( f1 < 220.5){
if ( f4 < 0.95492){
if ( f3 < 185){
if ( f4 < 0.93859){
if ( f2 < 151.5){
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
} else {
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
}
} else {
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
}
} else {
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
}
} else {
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
}
} else {
if ( f5 < 0.31535){
if ( f2 < 183.5){
if ( f1 < 242.5){
if ( f4 < 0.93885){
if ( f4 < 0.93854){
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
} else {
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
}
} else {
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
}
} else {
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
}
} else {
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
}
} else {
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
}
}
} else {
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
}
} else {
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
}
}
}
}
}
} else {
if ( f4 < 0.93863){
if ( f1 < 114.5){
if ( f5 < 0.58936){
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
} else {
if ( f1 < 111.5){
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
} else {
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
}
}
} else {
if ( f5 < 0.5922){
if ( f4 < 0.92379){
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
} else {
if ( f5 < 0.58916){
if ( f4 < 0.93855){
if ( f4 < 0.93427){
if ( f4 < 0.93418){
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
} else {
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
}
} else {
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
}
} else {
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
}
} else {
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
}
}
} else {
if ( f4 < 0.93745){
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
} else {
if ( f4 < 0.93756){
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
} else {
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
}
}
}
}
} else {
if ( f1 < 123.5){
if ( f5 < 0.54855){
if ( f3 < 60.5){
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
} else {
if ( f1 < 119){
if ( f5 < 0.54772){
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
} else {
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
}
} else {
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
}
}
} else {
if ( f5 < 0.65298){
if ( f4 < 0.94522){
if ( f4 < 0.9448){
if ( f5 < 0.56684){
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
} else {
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
}
} else {
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
}
} else {
if ( f4 < 0.96057){
if ( f1 < 122.5){
if ( f1 < 90.5){
if ( f3 < 52.5){
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
} else {
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
}
} else {
if ( f3 < 58.5){
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
} else {
if ( f2 < 44.5){
if ( f5 < 0.56351){
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
} else {
if ( f1 < 111.5){
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
} else {
if ( f1 < 113.5){
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
} else {
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
}
}
}
} else {
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
}
}
}
} else {
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
}
} else {
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
}
}
} else {
if ( f1 < 93.5){
if ( f4 < 0.97347){
if ( f2 < 25){
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
} else {
if ( f5 < 0.71891){
if ( f5 < 0.69946){
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
} else {
if ( f5 < 0.70165){
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
} else {
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
}
}
} else {
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
}
}
} else {
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
}
} else {
if ( f3 < 55.5){
if ( f1 < 102.5){
if ( f5 < 0.81094){
if ( f4 < 0.96127){
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
} else {
if ( f3 < 48.5){
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
} else {
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
}
}
} else {
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
}
} else {
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
}
} else {
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
}
}
}
}
} else {
if ( f1 < 130.5){
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
} else {
if ( f5 < 0.55756){
if ( f5 < 0.55748){
if ( f1 < 177.5){
if ( f1 < 174){
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
} else {
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
}
} else {
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
}
} else {
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
}
} else {
if ( f1 < 144.5){
if ( f4 < 0.98423){
if ( f4 < 0.94574){
if ( f4 < 0.94564){
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
} else {
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
}
} else {
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
}
} else {
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
}
} else {
if ( f4 < 0.96025){
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
} else {
if ( f4 < 0.96026){
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
} else {
if ( f4 < 0.9621){
if ( f4 < 0.96203){
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
} else {
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
}
} else {
if ( f1 < 204.5){
if ( f3 < 79.5){
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
} else {
if ( f5 < 0.70049){
if ( f4 < 0.98885){
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
} else {
if ( f4 < 0.98958){
//leaf
data[i] = 0*10;
data[i+1] = 0*10;
data[i+2] = 0*10;
} else {
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
}
}
} else {
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
}
}
} else {
//leaf
data[i] = 1*10;
data[i+1] = 1*10;
data[i+2] = 1*10;
}
}
}
}
}
}
}
}
}
}
}
}
}
}

// 
 }
}
