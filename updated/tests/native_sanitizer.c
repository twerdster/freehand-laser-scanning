/* Executes actual fixture inputs plus invalid-input cases under ASan/UBSan. */
#include "../native/laser_core.h"
#include <assert.h>
#include <math.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
int main(int argc,char **argv){
    assert(argc==2);FILE *f=fopen(argv[1],"rb");assert(f);
    uint32_t header[4];assert(fread(header,sizeof(uint32_t),4,f)==4);
    int w=header[0],h=header[1],frames=header[2],calibrations=header[3];
    assert(w==160&&h==120&&frames==22&&calibrations==6);
    double K[9],board[4];assert(fread(K,sizeof(double),9,f)==9);assert(fread(board,sizeof(double),4,f)==4);
    float *image=malloc((size_t)w*h*sizeof(float));double *uv=malloc(w*2*sizeof(double)),*xyz=malloc(w*3*sizeof(double)),*cal=malloc(calibrations*w*3*sizeof(double));
    assert(image&&uv&&xyz&&cal);int nc=0,total=0;double plane[4]={0};
    for(int i=0;i<frames;i++){
        double T[16];assert(fread(T,sizeof(double),16,f)==16);assert(fread(image,sizeof(float),(size_t)w*h,f)==(size_t)w*h);
        int n=laser_extract(image,w,h,8,uv);assert(n>=0&&n<=w);
        int np=i<calibrations?laser_calibration_points(uv,n,K,T,board,xyz):laser_points(uv,n,K,plane,T,xyz);
        assert(np>=0&&np<=n);
        if(i<calibrations){memcpy(cal+nc*3,xyz,np*3*sizeof(double));nc+=np;}
        else total+=np;
        if(i==calibrations-1)assert(laser_fit_plane(cal,nc,plane)==0);
    }
    assert(fgetc(f)==EOF);fclose(f);
    double I[16]={1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1},p[4]={0,0,1,-1},one[2]={79.5,59.5};
    assert(laser_points(one,1,K,p,I,xyz)==1);
    assert(laser_points(NULL,1,K,p,I,xyz)==-1);
    assert(laser_points(one,-1,K,p,I,xyz)==-1);
    assert(laser_calibration_points(NULL,0,NULL,NULL,NULL,NULL)==-1);
    assert(laser_fit_plane(NULL,4,p)==-1);
    I[0]=NAN;assert(laser_points(one,1,K,p,I,xyz)==-1);I[0]=1.2;assert(laser_points(one,1,K,p,I,xyz)==-1);
    I[0]=-1;assert(laser_points(one,1,K,p,I,xyz)==-1);I[0]=1;
    one[0]=NAN;assert(laser_points(one,1,K,p,I,xyz)==-1);one[0]=79.5;
    K[0]=-160;assert(laser_points(one,1,K,p,I,xyz)==-1);K[0]=160;
    p[0]=NAN;assert(laser_points(one,1,K,p,I,xyz)==-1);p[0]=0;
    memset(cal,0,calibrations*w*3*sizeof(double));assert(laser_fit_plane(cal,10,p)==-1);
    cal[2]=NAN;assert(laser_fit_plane(cal,10,p)==-1);
    image[0]=NAN;assert(laser_extract(image,w,h,8,uv)==-1);
    assert(laser_response(image,1,1,image)==-1);
    assert(laser_response(NULL,w,h,image)==-1);
    double zero_plane[4]={0};assert(laser_points(one,1,K,zero_plane,I,xyz)==-1);
    double parallel[4]={1,0,0,-.3},behind[4]={0,0,1,.3},deep[4]={0,0,1,-4};
    assert(laser_points(one,1,K,parallel,I,xyz)==0);
    assert(laser_points(one,1,K,behind,I,xyz)==0);
    assert(laser_points(one,1,K,deep,I,xyz)==0);
    printf("{\"fixture_frames\":%d,\"calibration_points\":%d,\"scan_points\":%d,\"invalid_input_assertions\":16,\"ray_rejection_assertions\":3,\"status\":\"passed\"}\n",frames,nc,total);
    free(image);free(uv);free(xyz);free(cal);return 0;
}
