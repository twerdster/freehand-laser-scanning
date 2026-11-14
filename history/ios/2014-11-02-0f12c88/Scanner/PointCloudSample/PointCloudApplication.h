/**
 * Copyright (C) 2012 13th Lab AB
 *
 * See the LICENSE file that came with this example code.
 */ 

#ifndef POINTCLOUDAPPLICATION_H
#define POINTCLOUDAPPLICATION_H

#define VERTICAL_LINE_MARGINE 120
#define HORIZONTAL_LINE_MARGINE 170
#define NUM_FRAMES_FOR_BUFFER 30
#define RESPONSE_THRESHOLD 70

#include "PointCloud.h"
#include "TextureUtilities.h"

// iOS opengl ES1.1 includes
#include <OpenGLES/ES1/gl.h>
#include <OpenGLES/ES1/glext.h>
#include <Accelerate/Accelerate.h>
#include <opencv2/opencv.hpp>
#include <queue.h>

// iOS time
#include <QuartzCore/QuartzCore.h>

inline double current_time() {
    return CACurrentMediaTime();
}


// Sample OpenGL ES 1.1 PointCloud controller
class PointCloudApplication {
	
public:
	
	PointCloudApplication(int viewport_width, int viewport_height, 
						  int video_width, int video_height, 
						  pointcloud_video_format video_format,
						  const char* resource_path, 
						  const char* documents_path,
						  const char* device,
						  double ui_scale_factor);
	~PointCloudApplication();
	// Interface from Objective-C layer
	
	void render_frame(char* data, int length, double timestamp);

	void on_accelerometer_update(float x, float y, float z, double timestamp);
	void on_device_motion_update(float x, float y, float z, float rot_x, float rot_y, float rot_z, float g_x, float g_y, float g_z, double timestamp);

	virtual bool on_touch_started(double x, double y) { return false; }
	virtual bool on_touch_moved(double x, double y) { return false; }
	virtual bool on_touch_ended(double x, double y) { return false; }
	virtual bool on_touch_cancelled(double x, double y) { return false; }
	
	void on_pause();
	void on_resume();
    
	pointcloud_matrix_4x4 projection_matrix; // CHANGED: These two were originally protected
	pointcloud_matrix_4x4 camera_matrix;
    
    cv::Vector<cv::Point3f> realWorldLaserPoints;
    cv::Vector<cv::Point3i> realWorldPointsColor;
    cv::Vector<int> frameId;
    cv::Vector<float> timeStamps;
    cv::Vector<cv::Mat> cameraMatrixVec;
    float laserPlaneCoeffs[4];
    int _record =0;
    int _calibrating =0;
    
    unsigned long _indices[360];
	
protected:
	
	// Switch to orthogonal projection (for UI etc)
	virtual void switch_to_ortho();
	
	// Switch to camera projection
	virtual void switch_to_camera();
	
	// Add a simple light to the scene
	virtual void init_lighting();
	virtual void enable_lighting();
	virtual void disable_lighting();

	virtual void render_point_cloud();
	virtual void render_content(double time_since_last_frame) {};

	
	pointcloud_context context;
	
	double ui_scale_factor;
	const char* resource_path;
	pointcloud_state last_state;
    char *framesBuffer;
    float *cameraMatrixBuffer;
    int frameCounter;
	
	

	
private:
	
	bool stop_opengl;
	
	void setup_graphics();
	void load_camera_texture(char *data);
	void process_camera_frame(char *data, double timestamp);
	void setup_video_texture();
	void render_camera_frame();
	void draw_logo();
	void clean_up();
    void addPoints( float * cameraMatrixData);
    cv::Mat findRealWorldPoint( cv::Mat cameraMat , cv::Point2f* CameraPoint);

	GLuint logo_texture;
	GLuint point_texture;
	GLuint video_texture;
	
	float video_vertices[8];
	float video_texcoords[8];
	
	double last_frame_clock;
	
};

extern bool run_opengl;

#endif // POINTCLOUDAPPLICATION_H
