/* Freehand Laser reconstruction adapter.
 * Paired-filter combination adapted from PointCloudApplication.mm:181-275,
 * copyright 2012 13th Lab AB, MIT; original notice at ios/Scanner/LICENSE.
 * New kernels, guards, wrappers and geometry adapter: copyright 2026 Aaron Wetzler,
 * MIT; see updated/LICENSE. No PointCloud SDK code is included.
 */
#include "laser_core.h"
#include <Accelerate/Accelerate.h>
#include <math.h>
#include <stdlib.h>
#include <string.h>

static void kernel(float *left, float *right, double sigma, int angle) {
    double theta=angle*M_PI/180, ls=0, rs=0;
    for(int y=-5;y<=5;y++) for(int x=-5;x<=5;x++) {
        double u=x*cos(theta)+y*sin(theta),v=-x*sin(theta)+y*cos(theta);
        double l=(u+sigma)*exp(-((u+sigma)*(u+sigma)+v*v)/(2*sigma*sigma))/(sigma*sigma);
        double r=-(u-sigma)*exp(-((u-sigma)*(u-sigma)+v*v)/(2*sigma*sigma))/(sigma*sigma);
        int i=(y+5)*11+x+5;left[i]=(float)l;right[i]=(float)r;ls+=fabs(l);rs+=fabs(r);
    }
    for(int i=0;i<121;i++){left[i]/=(float)ls;right[i]/=(float)rs;}
}

// Same vImage / vDSP positive-minimum / maximum combination as the recovered app.
static int combine(const float *left,const float *right,float *total,
                   vImage_Buffer *im,vImage_Buffer *l,vImage_Buffer *r) {
    size_t n=im->width*im->height;float zero=0;
    if(vImageConvolve_PlanarF(im,l,NULL,0,0,left,11,11,0,kvImageCopyInPlace))return -1;
    if(vImageConvolve_PlanarF(im,r,NULL,0,0,right,11,11,0,kvImageCopyInPlace))return -1;
    vDSP_vthr(l->data,1,&zero,l->data,1,n);
    vDSP_vthr(r->data,1,&zero,r->data,1,n);
    vDSP_vmin(l->data,1,r->data,1,r->data,1,n);
    vDSP_vmax(total,1,r->data,1,total,1,n);
    return 0;
}

int laser_response(const float *image,int w,int h,float *out) {
    if(!image||!out||w<11||h<11||w>2048||h>2048)return -1;
    size_t n=(size_t)w*h;
    float *a=malloc(n*sizeof(float)),*l=malloc(n*sizeof(float)),*r=malloc(n*sizeof(float));
    if(!a||!l||!r){free(a);free(l);free(r);return -1;}
    for(size_t i=0;i<n;i++){
        if(!isfinite(image[i])||image[i]<0||image[i]>255){free(a);free(l);free(r);return -1;}
        a[i]=(float)(255*pow(image[i]/255.0,12));out[i]=0;
    }
    vImage_Buffer ab={a,(vImagePixelCount)h,(vImagePixelCount)w,(size_t)w*sizeof(float)};
    vImage_Buffer lb={l,(vImagePixelCount)h,(vImagePixelCount)w,(size_t)w*sizeof(float)};
    vImage_Buffer rb={r,(vImagePixelCount)h,(vImagePixelCount)w,(size_t)w*sizeof(float)};
    int status=0;
    for(int s=1;s<=4;s++)for(int angle=80;angle<=100;angle+=10){
        float left[121],right[121];kernel(left,right,s*0.5,angle);
        if(combine(left,right,out,&ab,&lb,&rb))status=-1;
    }
    for(int y=0;y<h;y++)for(int x=0;x<w;x++)if(x<5||y<5||x>=w-5||y>=h-5)out[y*w+x]=0;
    free(a);free(l);free(r);return status;
}

static double peak(const float *v) {
    double a=(-v[0]+2*v[1]-2*v[3]+v[4])/12.0;
    double b=(2*v[0]-v[1]-2*v[2]-v[3]+2*v[4])/14.0;
    double c=(v[0]-8*v[1]+8*v[3]-v[4])/12.0;
    double eps=1e-7;for(int i=0;i<5;i++)eps=fmax(eps,fabs(v[i])*1e-7);
    double roots[2];int n=0;
    if(fabs(a)<eps){if(fabs(b)>eps)roots[n++]=-c/(2*b);}
    else if(4*b*b-12*a*c>=0){
        double disc=sqrt(4*b*b-12*a*c);
        roots[n++]=(-2*b+disc)/(6*a);roots[n++]=(-2*b-disc)/(6*a);
    }
    double best=NAN;
    for(int i=0;i<n;i++)if(isfinite(roots[i])&&fabs(roots[i])<=0.7&&6*a*roots[i]+2*b < -eps)
        if(!isfinite(best)||fabs(roots[i])<fabs(best))best=roots[i];
    return best;
}

int laser_extract(const float *image,int w,int h,double threshold,double *uv) {
    if(!uv||threshold<=0||!isfinite(threshold)||w<11||h<11||w>2048||h>2048)return -1;
    float *response=malloc((size_t)w*h*sizeof(float));if(!response)return -1;
    if(laser_response(image,w,h,response)){free(response);return -1;}
    int count=0;
    for(int x=5;x<w-5;x++){
        int y=0;for(int j=1;j<h;j++)if(response[j*w+x]>response[y*w+x])y=j;
        if(response[y*w+x]<threshold||y<5||y>=h-5)continue;
        float values[5];for(int j=0;j<5;j++)values[j]=response[(y+j-2)*w+x];
        double d=peak(values);if(!isfinite(d))continue;
        uv[count*2]=x;uv[count*2+1]=y+d;count++;
    }
    free(response);return count;
}

static int inverse3(const double *a,double *b) {
    double d=a[0]*(a[4]*a[8]-a[5]*a[7])-a[1]*(a[3]*a[8]-a[5]*a[6])+a[2]*(a[3]*a[7]-a[4]*a[6]);
    if(!isfinite(d)||fabs(d)<1e-12)return -1;
    b[0]=(a[4]*a[8]-a[5]*a[7])/d;b[1]=(a[2]*a[7]-a[1]*a[8])/d;b[2]=(a[1]*a[5]-a[2]*a[4])/d;
    b[3]=(a[5]*a[6]-a[3]*a[8])/d;b[4]=(a[0]*a[8]-a[2]*a[6])/d;b[5]=(a[2]*a[3]-a[0]*a[5])/d;
    b[6]=(a[3]*a[7]-a[4]*a[6])/d;b[7]=(a[1]*a[6]-a[0]*a[7])/d;b[8]=(a[0]*a[4]-a[1]*a[3])/d;return 0;
}

static int finite_array(const double *a,int n){
    if(!a)return 0;
    for(int i=0;i<n;i++)if(!isfinite(a[i]))return 0;
    return 1;
}

static int valid_rig(const double *K,const double *T){
    if(!finite_array(K,9)||!finite_array(T,16)||K[0]<=0||K[4]<=0)return 0;
    if(fabs(K[6])+fabs(K[7])+fabs(K[8]-1)>1e-8)return 0;
    if(fabs(T[12])+fabs(T[13])+fabs(T[14])+fabs(T[15]-1)>1e-8)return 0;
    for(int i=0;i<3;i++)for(int j=0;j<3;j++){
        double dot=0;for(int k=0;k<3;k++)dot+=T[4*k+i]*T[4*k+j];
        if(fabs(dot-(i==j))>1e-7)return 0;
    }
    double det=T[0]*(T[5]*T[10]-T[6]*T[9])-T[1]*(T[4]*T[10]-T[6]*T[8])+T[2]*(T[4]*T[9]-T[5]*T[8]);
    return fabs(det-1)<1e-7;
}

int laser_points(const double *uv,int count,const double *K,const double *p,const double *T,double *out) {
    if(count<0||count>1000000||!out||!finite_array(uv,count*2)||!valid_rig(K,T)||!finite_array(p,4))return -1;
    double inv[9],norm=hypot(hypot(p[0],p[1]),p[2]);
    if(inverse3(K,inv)||norm<1e-12)return -1;
    int n=0;
    for(int i=0;i<count;i++){
        double q[3];for(int j=0;j<3;j++)q[j]=inv[3*j]*uv[2*i]+inv[3*j+1]*uv[2*i+1]+inv[3*j+2];
        double den=p[0]*q[0]+p[1]*q[1]+p[2]*q[2],qn=hypot(hypot(q[0],q[1]),q[2]);
        if(!isfinite(den)||fabs(den)/(norm*qn)<0.03)continue;
        double alpha=-p[3]/den;if(!isfinite(alpha)||alpha<=0||alpha>3)continue;
        for(int j=0;j<3;j++)out[3*n+j]=alpha*(T[4*j]*q[0]+T[4*j+1]*q[1]+T[4*j+2]*q[2])+T[4*j+3];
        n++;
    }
    return n;
}

int laser_calibration_points(const double *uv,int count,const double *K,const double *T,const double *board,double *out){
    if(!valid_rig(K,T)||!finite_array(board,4))return -1;
    if(hypot(hypot(board[0],board[1]),board[2])<1e-12)return -1;
    double p[4]={0,0,0,board[3]},I[16]={1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1};
    for(int j=0;j<3;j++)for(int k=0;k<3;k++)p[j]+=T[4*k+j]*board[k];
    for(int j=0;j<3;j++)p[3]+=board[j]*T[4*j+3];
    return laser_points(uv,count,K,p,I,out);
}

int laser_fit_plane(const double *xyz,int count,double *plane){
    if(!plane||count<4||count>1000000||!finite_array(xyz,count*3))return -1;
    __CLPK_integer m=count,n=4,lda=count,ldu=1,ldvt=4,info,lwork=-1;
    double *A=malloc((size_t)count*4*sizeof(double)),s[4],vt[16],u=0,query,center[3]={0};
    if(!A)return -1;
    for(int i=0;i<count;i++)for(int j=0;j<3;j++)center[j]+=xyz[i*3+j]/count;
    for(int i=0;i<count;i++){for(int j=0;j<3;j++)A[j*count+i]=xyz[i*3+j]-center[j];A[3*count+i]=1;}
    char no='N',all='A';
    dgesvd_(&no,&all,&m,&n,A,&lda,s,&u,&ldu,vt,&ldvt,&query,&lwork,&info);
    if(info||!isfinite(query)||query<1||query>100000000){free(A);return -1;}
    lwork=(int)query;double *work=malloc((size_t)lwork*sizeof(double));if(!work){free(A);return -1;}
    dgesvd_(&no,&all,&m,&n,A,&lda,s,&u,&ldu,vt,&ldvt,work,&lwork,&info);
    free(work);free(A);if(info||!isfinite(s[0]))return -1;
    // The centered constant column is orthogonal to XYZ. Remove its sqrt(N)
    // singular value before checking spatial rank, independently of cloud scale.
    int constant=0;double spatial[3];
    for(int j=1;j<4;j++)if(fabs(s[j]-sqrt(count))<fabs(s[constant]-sqrt(count)))constant=j;
    for(int j=0,k=0;j<4;j++)if(j!=constant)spatial[k++]=s[j];
    if(spatial[0]<1e-6||spatial[1]/spatial[0]<.01)return -1;
    double norm=0;int largest=0;
    for(int j=0;j<4;j++){plane[j]=vt[j*4+3];if(j<3){norm+=plane[j]*plane[j];if(fabs(plane[j])>fabs(plane[largest]))largest=j;}}
    for(int j=0;j<3;j++)plane[3]-=plane[j]*center[j];
    if(norm<1e-12)return -1;norm=sqrt(norm)*(plane[largest]<0?-1:1);
    for(int j=0;j<4;j++)plane[j]/=norm;return 0;
}
