/**
 * Copyright (C) 2012 13th Lab AB
 *
 * See the LICENSE file that came with this example code.
 */

#include "PointCloudApplication.h"
#include <cassert>
#include <stdlib.h>
#include <iostream.h>
#include "kernels.h"


using namespace std;

PointCloudApplication::PointCloudApplication(int viewport_width, int viewport_height,
											 int video_width, int video_height,
											 pointcloud_video_format video_format,
											 const char* _resource_path,
											 const char* documents_path,
											 const char* device,
											 double ui_scale_factor_) {
	ui_scale_factor = ui_scale_factor_;
	
	video_texture = 0;
	last_frame_clock = current_time();
	
	stop_opengl = false;
	
	pointcloud_create(viewport_width, viewport_height,
					  video_width, video_height,
					  video_format,
					  device,
					  "REPLACE_WITH_YOUR_POINTCLOUD_APPLICATION_KEY");
	
	context = pointcloud_get_context();
	
	resource_path = _resource_path;
    
	setup_graphics();
	
	init_lighting();
    
    realWorldLaserPoints = cv::Vector<cv::Point3f>(NULL);
    
    framesBuffer = (char*)malloc(sizeof(char)*context.viewport_width*context.viewport_height * NUM_FRAMES_FOR_BUFFER*4);
    cameraMatrixBuffer = (float*)malloc(sizeof(float)*16*NUM_FRAMES_FOR_BUFFER);
    frameCounter = 0 ;
}

PointCloudApplication::~PointCloudApplication()
{
    free(framesBuffer);
    free(cameraMatrixBuffer);
}

void PointCloudApplication::setup_graphics() {
	// Define Viewport
	glViewport(0,
			   0,
			   context.viewport_width * ui_scale_factor,
			   context.viewport_height * ui_scale_factor);
	
	setup_video_texture();
	
	logo_texture  = read_png_texture("pointcloud-logo.png");
	point_texture = read_png_texture("trackpoint.png");
	
	switch_to_ortho();
}


void PointCloudApplication::setup_video_texture() {
	assert(context.video_format == POINTCLOUD_BGRA_8888);
	
	video_texture = create_texture(NULL, context.video_width, context.video_height, true, GL_BGRA);
    
	// Setup geometry for the video overlay
	video_vertices[0] = 0;
	video_vertices[1] = context.viewport_height;
	video_vertices[2] = context.viewport_width;
	video_vertices[3] = context.viewport_height;
	video_vertices[4] = context.viewport_width;
	video_vertices[5] = 0;
	video_vertices[6] = 0;
	video_vertices[7] = 0;
	
	video_texcoords[0] = context.video_width  - context.video_crop_x;
	video_texcoords[1] = context.video_height - context.video_crop_y;
	video_texcoords[2] = context.video_width  - context.video_crop_x;
	video_texcoords[3] = context.video_crop_y;
	video_texcoords[4] = context.video_crop_x;
	video_texcoords[5] = context.video_crop_y;
	video_texcoords[6] = context.video_crop_x;
	video_texcoords[7] = context.video_height - context.video_crop_y;
    
	for (int i = 0; i < 8; i += 2) {
		video_texcoords[i] /= context.video_width;
		video_texcoords[i+1] /= context.video_height;
	}
}
//CvMat a;


void PointCloudApplication::load_camera_texture(char *data) {
	if (!data)
		return;
    
	glBindTexture(GL_TEXTURE_2D, video_texture);
    
	assert(context.video_format == POINTCLOUD_BGRA_8888);
	glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0,
					context.video_width, context.video_height,
					GL_BGRA, GL_UNSIGNED_BYTE, data);
}


void PointCloudApplication::render_camera_frame() {
	switch_to_ortho();
	
	//glClearColor(0.0, 0.0, 0.0, 1.0);
	glClear(/*GL_COLOR_BUFFER_BIT | */GL_DEPTH_BUFFER_BIT);
	
	glBindTexture(GL_TEXTURE_2D, video_texture);
    
	glEnable(GL_TEXTURE_2D);
	glDisable(GL_DEPTH_TEST);
	
	glEnableClientState(GL_VERTEX_ARRAY);
	glEnableClientState( GL_TEXTURE_COORD_ARRAY );
	
	glColor4f(1.0, 1.0, 1.0, 1.0);
	glVertexPointer(2, GL_FLOAT, 0, video_vertices);
	glTexCoordPointer( 2, GL_FLOAT, 0, video_texcoords);
	glDrawArrays(GL_TRIANGLE_FAN, 0, 4);
	
	glDisableClientState(GL_TEXTURE_COORD_ARRAY);
	glDisableClientState(GL_VERTEX_ARRAY);
	
	glDisable(GL_TEXTURE_2D);
	glEnable(GL_DEPTH_TEST);
}

void PointCloudApplication::clean_up() {
}

/*
 * Draws the required (for the free SDK) logo in the bottom-left corner of the visible camera feed
 */
void PointCloudApplication::draw_logo() {
	int h = context.viewport_height;
	int w = context.viewport_width;
	double scale_factor = w == 320 ? 0.5 : 1.0;
	switch_to_ortho();
	draw_image(logo_texture, 10, h-(140+54)*scale_factor, 262*scale_factor, 54*scale_factor, 0, 0, 1, 1);
}



void PointCloudApplication::on_pause() {
	// We need to stop all OpenGL calls as soon as the application enters background
	stop_opengl = true;
}


void PointCloudApplication::on_resume() {
	stop_opengl = false;
}


void PointCloudApplication::on_accelerometer_update(float x, float y, float z, double timestamp) {
	pointcloud_on_accelerometer_update(x, y, z, timestamp);
}


void PointCloudApplication::on_device_motion_update(float x, float y, float z, float rot_x, float rot_y, float rot_z, float g_x, float g_y, float g_z, double timestamp) {
	pointcloud_on_device_motion_update(x, y, z, rot_x, rot_y, rot_z, g_x, g_y, g_z, timestamp);
}

// convolove with left and right kenrels and find maximum response between all kernels
void convFilter(float* leftKernel ,float* rightKernel , float* convResultTotal, vImage_Buffer* grayImageBuffer ,vImage_Buffer* convResultrBuffer , vImage_Buffer* convResultlBuffer)
{
    float zero =0;
    vDSP_Length width = grayImageBuffer->width;
    vDSP_Length height = grayImageBuffer->height;
    float* convResultr = (float*)convResultrBuffer->data;
    float* convResultl = (float*)convResultlBuffer->data;
    
    
    vImageConvolve_PlanarF (
                            grayImageBuffer,
                            convResultlBuffer,
                            NULL,
                            0,
                            0,
                            leftKernel,
                            11,
                            11,
                            NULL,
                            kvImageCopyInPlace
                            );
    
    
    
    // all negative elements are sent to zero
    
    vDSP_vthr (
               convResultl,
               1,
               &zero,
               convResultl,
               1,
               width*height
               );
    
    
    
    vImageConvolve_PlanarF (
                            grayImageBuffer,
                            convResultrBuffer,
                            NULL,
                            0,
                            0,
                            rightKernel,
                            11,
                            11,
                            NULL,
                            kvImageCopyInPlace
                            );
    
    
    
    
    // all negative elements are sent to zero
    vDSP_vthr (
               convResultr,
               1,
               &zero,
               convResultr,
               1,
               width*height
               );
    
    // find min between left and right kernels
    
    vDSP_vmin (
               convResultr,
               1,
               convResultl,
               1,
               convResultr,
               1,
               width*height
               );
    
    // find maximum response
    
    vDSP_vmax (
               convResultTotal,
               1,
               convResultr,
               1,
               convResultTotal,
               1,
               width*height
               );
}

// convert rgba floating poing image to grayscale floating point image
void rgbaToGrayScale( float* rgbImage , float* grayImage ,int imageSize )
{
    float rWeight = 0.298;
    float gWeight = 0.587;
    float bWeight = 0.114;
    
    
    vDSP_vsmul (
                rgbImage,
                4,
                &bWeight,
                rgbImage,
                4,
                imageSize
                );
    
    vDSP_vsmul (
                &rgbImage[1],
                4,
                &gWeight,
                &rgbImage[1],
                4,
                imageSize
                );
    
    
    
    vDSP_vsmul (
                &rgbImage[2],
                4,
                &rWeight,
                &rgbImage[2],
                4,
                imageSize
                );
    
    vDSP_vadd (
               rgbImage,
               4,
               &rgbImage[1],
               4,
               grayImage,
               1,
               imageSize
               );
    vDSP_vadd (
               &rgbImage[2],
               4,
               grayImage,
               1,
               grayImage,
               1,
               imageSize
               );
}

cv::Point3f findRealWorldPointLaser(cv::Mat cameraMat , cv::Point2f* CameraPoint , float* laserSurface) {
    
    // create K matrix
    float Kdata[9] = {455 , 0 ,242 , 0 , 455 , 183,0,0,1};
    cv::Mat K(3,3,CV_32FC1 , Kdata ,0);
    // create
    float imagePoint[3] = {CameraPoint->x , CameraPoint->y ,1.0};
    cv::Mat imagePointMat (3,1,CV_32FC1, (void*) imagePoint);
    // calculate the alpha coefficient that sattisfies z=0
    cv::Mat result = (K.inv())*imagePointMat;
    cv::Mat coeffs(3,1,CV_32F);
    coeffs.at<float>(0) = laserSurface[0], coeffs.at<float>(1) = laserSurface[1], coeffs.at<float>(2) = laserSurface[2];
    float d = laserSurface[3];
    float alpha = -d / ( result.dot(coeffs));
    
    // find the realWorld point using the alpha coefficient
    cv::Mat cameraPoint = alpha*(K.inv())*imagePointMat;
    cv::vconcat(cameraPoint, cv::Mat::ones(1, 1, cameraPoint.type()), cameraPoint);
    
    cv::Mat realWorldPointMat = (cameraMat.inv()) * cameraPoint;
    
    cv::Point3f realWorldPoint(realWorldPointMat.at<float>(0),realWorldPointMat.at<float>(1),realWorldPointMat.at<float>(2));
    
    return realWorldPoint;
}

cv::Mat findPixelFromWorldPoint(cv::Point3f point , cv::Mat cameraMat )
{
    float Kdata[9] = {455 , 0 ,242 , 0 , 455 , 183,0,0,1};
    cv::Mat K(3,3,CV_32FC1 , Kdata ,0);
    float realWorldPoint[4] = {point.x,point.y,point.z,1.0};
    cv::Mat realWorldPointHom = cv::Mat(4,1,CV_32F,realWorldPoint);
    cv::Mat cameraPoint = cameraMat*realWorldPointHom;
    cv::Mat pixel = K*cameraPoint.rowRange(0, 3);
    pixel = pixel/pixel.at<float>(2);
    return pixel.rowRange(0, 2);
    
}

void findMaxInRow(float* convResult, int width , int length ,unsigned long * indices)
{
    float val = 0.f;
    for (int i =0 ; i < width ; i++)
    {
        vDSP_maxvi (
                    &convResult[i*length+50],
                    1,
                    &val,
                    &indices[i],
                    length-100
                    );
        //        convResult[i*length+indices[i]+50]=255;
        
    }
    
}

void gammaCorrection( vImage_Buffer* grayImageBuffer ,float gammaExp,int width, int height )
{
    
    GammaFunction gammaObject =  vImageCreateGammaFunction (gammaExp,kvImageGamma_UseGammaValue_half_precision,NULL);
    float scale =1.0/255.0;
    float rescale = 255.0;
    vDSP_vsmul ( (float*)grayImageBuffer->data , 1,  &scale, (float*)grayImageBuffer->data, 1, width*height );
    
    vImageGamma_PlanarF ( grayImageBuffer, grayImageBuffer, gammaObject, NULL );
    vDSP_vsmul ( (float*)grayImageBuffer->data , 1,  &rescale, (float*)grayImageBuffer->data, 1, width*height );
    vImageDestroyGammaFunction (gammaObject);
    
}

void PointCloudApplication::addPoints( float * cameraMatrixData) {
    cv::Mat input(360,480,CV_8U);
    
    
    // populate the input for hough lines algorithem
    for (int i =0 ; i < 360 ; i++)
    {
        input.at<unsigned char>(i,_indices[i]+50) = 255;
    }
    
    // use hough transform to find the straight lines
    
    cv::vector<cv::Vec2f> lines;
    
    HoughLines(input, lines, 1, CV_PI/180, 20, 0, 0 );
    
    cv::Point2f pt1(0,0), pt2(0,0);
    
    if (lines.size() >0)
    {
        float rho = lines[0][0], theta = lines[0][1];
        double a = cos(theta), b = sin(theta);
        double x0 = a*rho, y0 = b*rho;
        pt1.x = cvRound(x0 + 200*(-b));
        pt1.y = cvRound(y0 + 200*(a));
        pt2.x = cvRound(x0 + 500*(-b));
        pt2.y = cvRound(y0 + 500*(a));
    }
    
    
    cv::Mat cameraMat(4,4,CV_32FC1 , cameraMatrixData );
    
    //RT takes you from world to camera
    // inv(RT) takes you from camera to world)
    cameraMat = (cameraMat.t());
    
    cv::Mat realWorldPointMat1 = findRealWorldPoint(cameraMat ,&pt1);
    cv::Mat realWorldPointMat2 = findRealWorldPoint(cameraMat ,&pt2);
    
    //    cv::Mat one = cv::Mat::ones(1, 1, CV_32F);
    //
    //    cv::vconcat(realWorldPointMat1, one, realWorldPointMat1);
    //    cv::vconcat(realWorldPointMat2, one, realWorldPointMat2);
    //
    //
    //    // convert point to camera world
    //    cv::Mat cameraPointMat1 = cameraMat*realWorldPointMat1;
    //    cv::Mat cameraPointMat2 = cameraMat*realWorldPointMat2;
    //    std::cout << cameraPointMat1 << " "<< cameraPointMat2 << std::endl;
    
    // convert point to cv::Point3f
    cv::Point3f cameraPoint1(realWorldPointMat1.at<float>(0),realWorldPointMat1.at<float>(1),realWorldPointMat1.at<float>(2));
    cv::Point3f cameraPoint2(realWorldPointMat2.at<float>(0),realWorldPointMat2.at<float>(1),realWorldPointMat2.at<float>(2));
    std::cout << cameraPoint1 << " "<< cameraPoint2 << std::endl;
    // save points
    realWorldLaserPoints.push_back(cameraPoint1);
    realWorldLaserPoints.push_back(cameraPoint2);
    
    
    
}

cv::Mat PointCloudApplication::findRealWorldPoint( cv::Mat cameraMat , cv::Point2f* CameraPoint) {
    
    
    
    // take R part of camera matrix
    cv::Mat R = cameraMat(cv::Range(0,3),cv::Range(0,3));
    
    // t part from camera matrix
    cv::Mat t = cameraMat.col(3);
    t = t.rowRange(0,3);
    
    // create K matrix
    float Kdata[9] = {455 , 0 ,242 , 0 , 455 , 183,0,0,1};
    cv::Mat K(3,3,CV_32FC1 , Kdata ,0);
    // create
    float imagePoint[3] = {CameraPoint->x , CameraPoint->y ,1.0};
    cv::Mat imagePointMat (3,1,CV_32F, (void*) imagePoint);
    // calculate the alpha coefficient that sattisfies y=0
    cv::Mat result = R.t()*(K.inv())*imagePointMat;
    cv::Mat RTt = R.t()*t;
    float alpha = RTt.at<float>(1) / result.at<float>(1);
    
    // find the realWorld point using the alpha coefficient
    cv::Mat realWorldPointMat = alpha*(K.inv())*imagePointMat;
    
    return realWorldPointMat;
}

#define IND(row,col,chan,numChan)

/**
 * Main rendering loop
 */
void PointCloudApplication::render_frame(char *data, int length, double timestamp) {
	if (stop_opengl) return;
	
	pointcloud_state state = pointcloud_get_state();
	
	// Timers
	double now = current_time();
	double time_since_last_frame = now - last_frame_clock;
	last_frame_clock = now;
    
	process_camera_frame(data, timestamp);
	if (stop_opengl) return;
	
    // -------------------------------
    /* Main Scanner processing entry point.
     
     pointcloudApplication->projection_matrix;
     pointcloudApplication->camera_matrix;
     They are both of type pointcloud_matrix_4x4 and I have made them public (they were protected)
     Im not sure what happens when tracking is lost. I.e. im sure theres a flag which says whether or not
     the matrices are valid. In any case we need to check that.
     
     
     We now want to lock the memory, copy it and process it in a background thread so that we dont freeze the render.
     However the background thread part is slightly tricky so we will do that later.
     The first thing to do is to process the image and find the best way to extract a bright red laser line.
     One way might be to simply segment based on red. I think a better way might be to extract the gradient image
     and then decide whether a point is a laser based
     I think it might even be a good idea to not use OpenCV because it seems quite slow. But for the meantime it is okay for testing\
     and algorithm dev.
     
     The next step is to extract a laser line from an image.
     */
    
    
    
    int w = context.video_width;
    int h = context.video_height;
    memcpy(&framesBuffer[(frameCounter%NUM_FRAMES_FOR_BUFFER)*4*w*h], data, sizeof(char)*w*h*4);
    memcpy(&cameraMatrixBuffer[(frameCounter%NUM_FRAMES_FOR_BUFFER)*16], camera_matrix.data, sizeof(float)*16);
    frameCounter++;
    float* dataFloat = (float*) malloc(sizeof(float)*4*w*h);
    
    float* grayImage = (float*) malloc( sizeof(float)*w*h);
    vImage_Buffer grayImageBuffer = {(void*)grayImage , h , w , sizeof(float)*w};
    float* convResultTotal = (float*) calloc(w*h, sizeof(float));
    vImage_Buffer convResultImageBuffer = {(void*)convResultTotal , h , w , sizeof(float)*w};
    
    // convert image to floating point
    vDSP_vfltu8 (
                 ( uint8_t *)data,
                 1,
                 dataFloat,
                 1,
                 4*w*h
                 );
    // convert floating point rgba image to grayscale
    rgbaToGrayScale( dataFloat , grayImage ,w*h );
    //gamma correction
    gammaCorrection( &grayImageBuffer ,12.0 ,w,h);
    // convolve with all kernels one by one
    
    vDSP_Length width = grayImageBuffer.width;
    vDSP_Length height = grayImageBuffer.height;
    
    float* convResultr = (float*) malloc( sizeof(float)*width*height);
    float* convResultl = (float*) malloc( sizeof(float)*width*height);
    vImage_Buffer  convResultrBuffer = {convResultr , height , width ,width*sizeof(float)};
    vImage_Buffer  convResultlBuffer = {convResultl , height , width ,width*sizeof(float)};
    
    
    
    //    convFilter( elx0 , erx0 , convResultTotal, &grayImageBuffer ,&convResultrBuffer , &convResultlBuffer);
    //    convFilter( elx10 , erx10 , convResultTotal, &grayImageBuffer ,&convResultrBuffer , &convResultlBuffer);
    //    convFilter( elx20 , erx20 , convResultTotal, &grayImageBuffer ,&convResultrBuffer , &convResultlBuffer);
    //    convFilter( elx30 , erx30 , convResultTotal, &grayImageBuffer ,&convResultrBuffer , &convResultlBuffer);
    //    convFilter( elx40 , erx40 , convResultTotal, &grayImageBuffer ,&convResultrBuffer , &convResultlBuffer);
    //    convFilter( elx50 , erx50 , convResultTotal, &grayImageBuffer ,&convResultrBuffer , &convResultlBuffer);
    //    convFilter( elx60 , erx60 , convResultTotal, &grayImageBuffer ,&convResultrBuffer , &convResultlBuffer);
    
    //    convFilter( elx70s05 , erx70s05 , convResultTotal, &grayImageBuffer ,&convResultrBuffer , &convResultlBuffer);
    convFilter( elx80s05 , erx80s05 , convResultTotal, &grayImageBuffer ,&convResultrBuffer , &convResultlBuffer);
    convFilter( elx90s05 , erx90s05 , convResultTotal, &grayImageBuffer ,&convResultrBuffer , &convResultlBuffer);
    convFilter( elx100s05 , erx100s05 , convResultTotal, &grayImageBuffer ,&convResultrBuffer , &convResultlBuffer);
    //    convFilter( elx110s05 , erx110s05 , convResultTotal, &grayImageBuffer ,&convResultrBuffer , &convResultlBuffer);
    
    //    convFilter( elx70s1 , erx70s1 , convResultTotal, &grayImageBuffer ,&convResultrBuffer , &convResultlBuffer);
    convFilter( elx80s1 , erx80s1 , convResultTotal, &grayImageBuffer ,&convResultrBuffer , &convResultlBuffer);
    convFilter( elx90s1 , erx90s1 , convResultTotal, &grayImageBuffer ,&convResultrBuffer , &convResultlBuffer);
    convFilter( elx100s1 , erx100s1 , convResultTotal, &grayImageBuffer ,&convResultrBuffer , &convResultlBuffer);
    //    convFilter( elx110s1 , erx110s1 , convResultTotal, &grayImageBuffer ,&convResultrBuffer , &convResultlBuffer);
    
    
    //    convFilter( elx70s15 , erx70s15 , convResultTotal, &grayImageBuffer ,&convResultrBuffer , &convResultlBuffer);
    convFilter( elx80s15 , erx80s15 , convResultTotal, &grayImageBuffer ,&convResultrBuffer , &convResultlBuffer);
    convFilter( elx90s15 , erx90s15 , convResultTotal, &grayImageBuffer ,&convResultrBuffer , &convResultlBuffer);
    convFilter( elx100s15 , erx100s15 , convResultTotal, &grayImageBuffer ,&convResultrBuffer , &convResultlBuffer);
    //    convFilter( elx110s15 , erx110s15 , convResultTotal, &grayImageBuffer ,&convResultrBuffer , &convResultlBuffer);
    
    //    convFilter( elx70s2 , erx70s2 , convResultTotal, &grayImageBuffer ,&convResultrBuffer , &convResultlBuffer);
    convFilter( elx80s2 , erx80s2 , convResultTotal, &grayImageBuffer ,&convResultrBuffer , &convResultlBuffer);
    convFilter( elx90s2 , erx90s2 , convResultTotal, &grayImageBuffer ,&convResultrBuffer , &convResultlBuffer);
    convFilter( elx100s2 , erx100s2 , convResultTotal, &grayImageBuffer ,&convResultrBuffer , &convResultlBuffer);
    //    convFilter( elx110s2 , erx110s2 , convResultTotal, &grayImageBuffer ,&convResultrBuffer , &convResultlBuffer);
    
    //    convFilter( elx110 , erx110 , convResultTotal, &grayImageBuffer ,&convResultrBuffer , &convResultlBuffer);
    //    convFilter( elx120 , erx120 , convResultTotal, &grayImageBuffer ,&convResultrBuffer , &convResultlBuffer);
    //    convFilter( elx130 , erx130 , convResultTotal, &grayImageBuffer ,&convResultrBuffer , &convResultlBuffer);
    //    convFilter( elx140 , erx140 , convResultTotal, &grayImageBuffer ,&convResultrBuffer , &convResultlBuffer);
    
    //    float kernel [9] ={ 1.0/9 , 1.0/9 , 1.0/9 , 1.0/9 , 1.0/9 , 1.0/9 , 1.0/9 , 1.0/9 , 1.0/9 };
    //
    //    vImageConvolve_PlanarF (
    //                            &convResultImageBuffer,
    //                            &convResultImageBuffer,
    //                            NULL,
    //                            0,
    //                            0,
    //                            kernel,
    //                            9,
    //                            1,
    //                            NULL,
    //                            kvImageCopyInPlace
    //                            );
    
    //    cv::Mat y(5,1,CV_32FC1);
    float y[5];
    cv::Mat invAMat(5,5,CV_32FC1,invA);
    //    cv::Mat interpCoeffs;
    float interpCoeffs[5];
    float a,b,c,root1,root2;
    cv::Point3f realWorldPoint;
    cv::Point2f pt;
    
    float cameraMatrix[16];
    memcpy(cameraMatrix, camera_matrix.data, 16*sizeof(float));
    cv::Mat cameraMat(4,4,CV_32FC1 , cameraMatrix );
    //    cameraMatrixVec.push_back(cameraMat.clone());
    
    cv::Mat cameraMatOld(4,4,CV_32FC1 , &cameraMatrixBuffer[(frameCounter%NUM_FRAMES_FOR_BUFFER)*16] );
    cameraMatOld = cameraMatOld.t();
    char *oldFrame = &framesBuffer[(frameCounter%NUM_FRAMES_FOR_BUFFER)*4*w*h];
    
    //RT takes you from world to camera
    // inv(RT) takes you from camera to world)
    cameraMat = (cameraMat.t());
    if (_record){
        
        
        for( int i = 0; i <  height;i++)
        {
            for( int j =150 ;  j < width-150 ; j++)
            {
                //            data[i*4*width+ j*4] = 0;
                //            data[i*4*width+ j*4+1] = 0;
                //            data[i*4*width+ j*4+2] = 0;
                if (convResultTotal[ j + i*width] >RESPONSE_THRESHOLD)
                {
                    data[i*4*width+ j*4] = 255;
                    
                    //                y.at<float>(0) =convResultTotal[ j + (i-2)*height];
                    //                y.at<float>(1) =convResultTotal[ j + (i-1)*height];
                    //                y.at<float>(2) =convResultTotal[ j + (i)*height];
                    //                y.at<float>(3) =convResultTotal[ j + (i+1)*height];
                    //                y.at<float>(4) =convResultTotal[ j + (i+2)*height];
                    y[0] = convResultTotal[ i*width + j-2];
                    y[1] = convResultTotal[ i*width + j-1];
                    y[2] = convResultTotal[ i*width + j];
                    y[3] = convResultTotal[ i*width + j+1];
                    y[4] = convResultTotal[ i*width + j+2];
                    
                    //                interpCoeffs = invAMat*y;
                    vDSP_mmul (invA,1,y,1,interpCoeffs,1,5,1,5);
                    
                    //                a=3*interpCoeffs.at<float>(0); b=2*interpCoeffs.at<float>(1); c=interpCoeffs.at<float>(2);
                    a=3*interpCoeffs[0]; b=2*interpCoeffs[1]; c=interpCoeffs[2];
                    if(b*b-4*a*c>=0)
                    {
                        root1=(-b + sqrt(b*b-4*a*c))/(2*a);
                        root2=(-b-sqrt(b*b-4*a*c))/(2*a);
                        if(6*interpCoeffs[0]*root1 + 2*interpCoeffs[1]<0 && abs(root1)<0.7)
                        {
                            pt.x = j+root1;
                            pt.y = i;
                            realWorldPoint = findRealWorldPointLaser(cameraMat , &pt , laserPlaneCoeffs);
                            data[i*4*width+ j*4] = 255;
                            
                            
                            if (abs(realWorldPoint.x) <5 && abs(realWorldPoint.y) <5 && abs(realWorldPoint.z) <5 )
                            {
                                realWorldLaserPoints.push_back(cv::Point3f(realWorldPoint.x,realWorldPoint.y, realWorldPoint.z));
                                cv::Mat pixel = findPixelFromWorldPoint(realWorldPoint, cameraMatOld);
                                int u,v;
                                u =(int)pixel.at<float>(1);
                                v =(int)pixel.at<float>(0);
                                u = u < 0 ? 0 : u;
                                u = u > height ? height : u;
                                v = v < 0 ? 0 : v;
                                v = v > width ? width : v;
                                //                            std::cout << "u: " << u <<" v: " << v << std::endl;
                                
                                char r =oldFrame[u*4*width + 4*v+2];
                                char g =oldFrame[u*4*width + 4*v+1];
                                char b =oldFrame[u*4*width + 4*v];
                                
                                realWorldPointsColor.push_back(cv::Point3i(r,g,b));
                                //                            frameId.push_back(frameCounter);
                                
                                
                                data[i*4*width+ j*4+1] = 255;
                                data[i*4*width+ j*4+2] = 255;
                            }
                        }
                        else if (6*interpCoeffs[0]*root2 + 2*interpCoeffs[1]<0 && abs(root2)<0.7)
                        {
                            pt.x = j+root2;
                            pt.y = i;
                            realWorldPoint = findRealWorldPointLaser(cameraMat , &pt , laserPlaneCoeffs);
                            data[i*4*width+ j*4] = 255;
                            
                            if (abs(realWorldPoint.x) <5 && abs(realWorldPoint.y) <5 && abs(realWorldPoint.z) <5 )
                            {
                                realWorldLaserPoints.push_back(cv::Point3f(realWorldPoint.x,realWorldPoint.y, realWorldPoint.z));
                                cv::Mat pixel = findPixelFromWorldPoint(realWorldPoint, cameraMatOld);
                                int u,v;
                                u =(int)pixel.at<float>(1);
                                v =(int)pixel.at<float>(0);
                                u = u < 0 ? 0 : u;
                                u = u > height ? height : u;
                                v = v < 0 ? 0 : v;
                                v = v > width ? width : v;
                                
                                //                            std::cout << "u: " << u <<" v: " << v << std::endl;
                                
                                char r =oldFrame[u*4*width + 4*v+2];
                                char g =oldFrame[u*4*width + 4*v+1];
                                char b =oldFrame[u*4*width + 4*v];
                                
                                realWorldPointsColor.push_back(cv::Point3i(r,g,b));
                                //                            frameId.push_back(frameCounter);
                                //                            printf("r: %d g: %d b: %d\n",r,g,b);
                                
                                
                                data[i*4*width+ j*4+1] = 255;
                                data[i*4*width+ j*4+2] = 255;
                            }
                            
                        }
                        
                    }   // if(b*b-4*a*c>=0)
                }   // if convresulttotal >30
            }   // for int j
        }   // for int i
    }// if record
    else if (_calibrating)
    {
        findMaxInRow(convResultTotal,  h ,  w, _indices);
        float cameraMatrix[16];
        memcpy(cameraMatrix, camera_matrix.data, 16*sizeof(float));
        addPoints (cameraMatrix);
    }
    
    
    
    //    unsigned long *indices = (unsigned long*) malloc(h*sizeof(unsigned long));
    //    findMaxInRow(convResultTotal,  h ,  w, _indices);
    //
    //    for (int i =0 ; i<h; i++) {
    //        data[i*4*w+ _indices[i]*4+200]=255;
    //        data[i*4*w+ _indices[i]*4+201]=255;
    //        data[i*4*w+ _indices[i]*4+202]=255;
    //        if (_record){
    //            cv::Point2f pt(i,_indices[i]+50);
    //            cv::Point3f realWorldPoint = findRealWorldPointLaser(cameraMat , &pt , laserPlaneCoeffs);
    //            std::cout << realWorldPoint.x << "," << realWorldPoint.y << "," << realWorldPoint.z <<std::endl;
    //        }
    //    }
    //
    
    
    //    float zero = 0.0;
    //
    //
    //    vDSP_vsadd (
    //                convResultTotal,
    //                1,
    //                &zero,
    //                dataFloat,
    //                4,
    //                w*h
    //                );
    //    vDSP_vsadd (
    //                convResultTotal,
    //                1,
    //                &zero,
    //                &dataFloat[1],
    //                4,
    //                w*h
    //                );
    //    vDSP_vsadd (
    //                convResultTotal,
    //                1,
    //                &zero,
    //                &dataFloat[2],
    //                4,
    //                w*h
    //                );
    //    vDSP_vsadd (
    //                convResultTotal,
    //                1,
    //                &zero,
    //                &dataFloat[3],
    //                4,
    //                w*h
    //                );
    //
    //
    //
    //    vDSP_vfixu8 (
    //                 dataFloat,
    //                 1,
    //                 (unsigned char*)data,
    //                 1,
    //                 w*h*4
    //                 );
    
    free(dataFloat);
    free(grayImage);
    free(convResultl);
    free(convResultr);
    free(convResultTotal);
    
    // draw calibration lines on screen
    //    for (int i =0 ; i < h ; i++)
    //    {
    //        data[i*4*w+4*HORIZONTAL_LINE_MARGINE]=255;
    //        data[(i+1)*4*w - 4*HORIZONTAL_LINE_MARGINE]=255;
    //
    //    }
    //
    //    for (int i =0 ; i < w ; i++)
    //    {
    //        data[4*w*VERTICAL_LINE_MARGINE + 4*i]=255;
    //        data[4*w*( h-VERTICAL_LINE_MARGINE ) + 4*i]=255;
    //
    //    }
    
    
    
    
    load_camera_texture(data);
	if (stop_opengl) return;
	
    
	render_camera_frame();
	if (stop_opengl) return;
	
	render_point_cloud();
	if (stop_opengl) return;
	
	render_content(time_since_last_frame);
	if (stop_opengl) return;
    
    
	//draw_logo();
	if (stop_opengl) return;
	
	clean_up();
	
	last_state = state;
}


void PointCloudApplication::process_camera_frame(char *data, double timestamp) {
	
	pointcloud_on_camera_frame(data, timestamp);
	
	camera_matrix = pointcloud_get_camera_matrix();
	
	// Calculate the camera projection matrix (with given near and far clipping planes)
	projection_matrix = pointcloud_get_frustum(0.1, 100);
}

/*
 * Renders the tracked points
 */
void PointCloudApplication::render_point_cloud() {
	
    pointcloud_state state = pointcloud_get_state();
    
    if (state == POINTCLOUD_INITIALIZING ||
		state == POINTCLOUD_TRACKING_SLAM_MAP) {
        
        pointcloud_point_cloud* points = pointcloud_get_points();
		
        if (points) {
			switch_to_camera();
			disable_lighting();
            
			glDisable(GL_DEPTH_TEST);
            
            glColor4f(0.9, 0.95, 1.0, 0.6);
            
            glEnable(GL_POINT_SPRITE_OES);
            glEnable(GL_TEXTURE_2D);
            
            glEnable(GL_BLEND);
            glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
			
			glBindTexture(GL_TEXTURE_2D, point_texture);
            
            glTexEnvi(GL_POINT_SPRITE_OES, GL_COORD_REPLACE_OES, GL_TRUE);
            
            glPointParameterf(GL_POINT_SIZE_MAX, 64.0f);
            
			glPointSize(32.0);
			glEnableClientState(GL_VERTEX_ARRAY);
            glVertexPointer(3,GL_FLOAT,0, (float *)points->points);
            glDrawArrays(GL_POINTS,0, points->size);
			
			glDisableClientState(GL_VERTEX_ARRAY);
            
            glColor4f(1, 1, 1, 1);
			
			glPointSize(1);
            
			glDisable(GL_BLEND);
			glDisable(GL_TEXTURE_2D);
			glDisable(GL_POINT_SPRITE_OES);
			
			pointcloud_destroy_point_cloud(points);
			
			switch_to_ortho();
        }
    }
}


/*
 * Switches to orthogonal drawing (e.g. UI)
 */
void PointCloudApplication::switch_to_ortho() {
	disable_lighting();
	
	glDisable(GL_DEPTH_TEST);
	glMatrixMode(GL_PROJECTION);
	glLoadIdentity();
	glOrthof(0, context.viewport_width, context.viewport_height, 0, -1, 1);
	glMatrixMode(GL_MODELVIEW);
	glLoadIdentity();
}

/*
 * Switches to camera perspective ("AR mode")
 */
void PointCloudApplication::switch_to_camera() {
	enable_lighting();
	
	glShadeModel(GL_SMOOTH);
	
	glDisable(GL_BLEND);
	glDisable(GL_TEXTURE_2D);
	
	glEnable(GL_DEPTH_TEST);
	
	// Set up projection matrix
	glMatrixMode(GL_PROJECTION);
	glLoadMatrixf(projection_matrix.data);
    
	// Set up camera matrix
	glMatrixMode(GL_MODELVIEW);
	glLoadMatrixf(camera_matrix.data);
}


/*
 * Initializes basic lighting
 */
void PointCloudApplication::init_lighting() {
	float light_ambient[4] = {0.2f, 0.2f, 0.2f, 1.0f};
	float light_diffuse[4] = {1.0f, 1.0f, 1.0, 1.0f};
	float light_specular[4] = {1.0f, 1.0f, 1.0f, 1.0f};
	
	// Assign created components to GL_LIGHT0
	glLightfv(GL_LIGHT0, GL_AMBIENT, light_ambient);
	glLightfv(GL_LIGHT0, GL_DIFFUSE, light_diffuse);
	glLightfv(GL_LIGHT0, GL_SPECULAR, light_specular);
}


void PointCloudApplication::enable_lighting() {
	glEnable(GL_LIGHTING);
	glEnable(GL_LIGHT0);
}


void PointCloudApplication::disable_lighting() {
	glDisable(GL_LIGHTING);
	glDisable(GL_LIGHT0);
}
