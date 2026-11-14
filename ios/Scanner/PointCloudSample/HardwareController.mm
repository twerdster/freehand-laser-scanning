/**
 * Copyright (C) 2012 13th Lab AB
 *
 * See the LICENSE file that came with this example code.
 */

#import "HardwareController.h"
#include "TestApp.h"


#import <AVFoundation/AVCaptureOutput.h>
#import <CoreVideo/CVPixelBuffer.h>

@implementation HardwareController

@synthesize timestamp;
@synthesize captureSession;
@synthesize glView;
@synthesize pixelBuffer;
@synthesize motionManager;
@synthesize g_scale;
@synthesize restartingCamera;
@synthesize accelerometer_available;
@synthesize device_motion_available;
@synthesize pointcloudApplication;
@synthesize calibButton;
@synthesize recordButton;

- (void)startCamera {
    [self.captureSession startRunning];
	restartingCamera = NO;
}

- (void) restartCamera {
	if (self.restartingCamera)
		return;
	
	restartingCamera = YES;
	
	if ([self.captureSession isRunning])
		[self.captureSession stopRunning];
	
	[self startCamera];
}

-(void)eventHandler:(id)data {
    if ([[data name] isEqualToString:@"AVCaptureSessionRuntimeErrorNotification"]) {
		[NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(restartCamera) userInfo:nil repeats:NO];
    } else if ([[data name] isEqualToString:@"AVCaptureSessionInterruptionEndedNotification"]) {
        [self.captureSession startRunning];
    }
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
		[self.view setFrame:[[UIScreen mainScreen] bounds]];
    }
	
    return self;
}

- (void) viewDidAppear:(BOOL)animated
{
}

- (void)viewDidLoad {
    [super viewDidLoad];
	
	self.restartingCamera = NO;
	self.accelerometer_available = NO;
	self.device_motion_available = NO;
	
	[UIApplication sharedApplication].statusBarHidden = NO;
	self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    
	CGRect rect = [[UIScreen mainScreen] bounds];
	
	glView = [[GLView alloc] initWithFrame:rect];
	
	[self.glView.window setFrame:rect];
	
	[self.glView setFrame:[[UIScreen mainScreen] applicationFrame]];
    
    // Double the resolution on iPhone 4 and 4s etc.
    if ([[UIScreen mainScreen] respondsToSelector:@selector(scale)]) {
        self.g_scale = [UIScreen mainScreen].scale;
    } else {
        self.g_scale = 1.0f;
    }
    
    if ([self.glView respondsToSelector:@selector(setContentScaleFactor:)])
    {
        [self.glView setContentScaleFactor: g_scale];
    }
    videoProcessor = [[VideoWriter alloc] init];
	videoProcessor.delegate = self;
	
	[glView setDelegate:self];
    glView.multipleTouchEnabled = YES;
	[self setView:glView];
    
    //    UIButton *captureBtn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    //    [captureBtn addTarget:self action:@selector(capturePressed:) forControlEvents:UIControlEventTouchDown];
    //    [captureBtn setTitle:@"Capture" forState:UIControlStateNormal];
    //    captureBtn.frame = CGRectMake(80.0, 100.0, 160.0, 40.0);
    //    [[self view] addSubview:captureBtn];
    
    calibButton= [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [calibButton addTarget:self action:@selector(calibrationPressed:) forControlEvents:UIControlEventTouchDown];
    [calibButton setTitle:@"Calibrate" forState:UIControlStateNormal];
    calibButton.frame = CGRectMake(80.0, 60.0, 160.0, 40.0);
    [[self view] addSubview:calibButton];
	
    recordButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [recordButton addTarget:self action:@selector(recordPressed:) forControlEvents:UIControlEventTouchDown];
    [recordButton setTitle:@"Record" forState:UIControlStateNormal];
    recordButton.frame = CGRectMake(80.0, 100.0, 160.0, 40.0);
    [[self view] addSubview:recordButton];
    
	[self initCapture];
	
	motionManager = [[CMMotionManager alloc] init];
	
	if (self.motionManager.accelerometerAvailable) {
		accelerometer_available = true;
		[self.motionManager startAccelerometerUpdates];
	}
	
	if (self.motionManager.deviceMotionAvailable) {
		device_motion_available = true;
		[self.motionManager startDeviceMotionUpdates];
	}
    
}

//- (void) capturePressed :(id)sender{
//
//
//}

- (void) calibrationPressed :(id)sender{
    
    pointcloudApplication->_calibrating = !pointcloudApplication->_calibrating;
    if(!pointcloudApplication->_calibrating)
    {
        [calibButton setTitle:@"calibrate" forState:UIControlStateNormal];
        [calibButton setTitleColor:NULL forState:UIControlStateNormal];
        cv::Mat surfaceCoeffs =  [self FindSurface];
        
        NSArray* surfaceCoeffsArray = [NSArray arrayWithObjects:[NSNumber numberWithFloat:surfaceCoeffs.at<float>(0)], [NSNumber numberWithFloat:surfaceCoeffs.at<float>(1)] ,[NSNumber numberWithFloat:surfaceCoeffs.at<float>(2)],[NSNumber numberWithFloat:surfaceCoeffs.at<float>(3)],nil];
        NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject:surfaceCoeffsArray forKey:@"surfaceCoeffs"];
        pointcloudApplication->realWorldLaserPoints.resize(0);
    }
    else{
        [calibButton setTitle:@"calibrating" forState:UIControlStateNormal];
        [calibButton setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
        
    }
    
}


- (void)toggleRecording:(id) sender
{
	// Wait for the recording to start/stop before re-enabling the record button.
	
	

}

- (void) recordPressed :(id)sender{
    
    
    if(!pointcloudApplication->_record)
    {
        [videoProcessor startRecording];
        // reset points vec
        pointcloudApplication->realWorldLaserPoints.resize(0);
        pointcloudApplication->frameId.resize(0);
        pointcloudApplication->cameraMatrixVec.resize(0);
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSArray *surfaceCoeffs = [NSArray arrayWithArray:[defaults objectForKey:@"surfaceCoeffs"]];
        pointcloudApplication->laserPlaneCoeffs[0]= [[surfaceCoeffs objectAtIndex:0] floatValue];
        pointcloudApplication->laserPlaneCoeffs[1]= [[surfaceCoeffs objectAtIndex:1] floatValue];
        pointcloudApplication->laserPlaneCoeffs[2]= [[surfaceCoeffs objectAtIndex:2] floatValue];
        pointcloudApplication->laserPlaneCoeffs[3]= [[surfaceCoeffs objectAtIndex:3] floatValue];
        
    }
    else
    {
        [videoProcessor stopRecording];
        // save ply file
        //        NSString* plyFile =@"";
        int numVertices = (int)pointcloudApplication->realWorldLaserPoints.size();
        NSString *header = [[NSString alloc] initWithFormat:@"ply\nformat binary_little_endian 1.0\nelement vertex %d\nproperty float x\nproperty float y\nproperty float z\nproperty uchar red\nproperty uchar green\nproperty uchar blue\nend_header\n",numVertices];
        NSMutableData *data = [[NSMutableData alloc] init];
        [data appendData:[header dataUsingEncoding:NSUTF8StringEncoding]];
        cv::Vector<cv::Point3f>::iterator iter;
        cv::Vector<cv::Point3i>::iterator color;
        cv::Point3f cm(0.0,0.0,0.0);
        cv::Scalar_<float>scal(1/(float)numVertices);
        
        for(iter = pointcloudApplication->realWorldLaserPoints.begin() ; iter != pointcloudApplication->realWorldLaserPoints.end() ; iter++)
        {
            cm = (1/(float)numVertices)*(*iter);
        }
        
        color = pointcloudApplication->realWorldPointsColor.begin();
        for(iter = pointcloudApplication->realWorldLaserPoints.begin() ; iter != pointcloudApplication->realWorldLaserPoints.end() ; iter++)
        {
            *iter = *iter-cm;
            [data appendBytes:&iter->x length:sizeof(float)];
            [data appendBytes:&iter->y length:sizeof(float)];
            [data appendBytes:&iter->z length:sizeof(float)];
            [data appendBytes:&color->x length:sizeof(char)];
            [data appendBytes:&color->y length:sizeof(char)];
            [data appendBytes:&color->z length:sizeof(char)];
            color++;
            
        }
        
        //        NSMutableData *frameIdData = [[NSMutableData alloc] init];
        //        cv::Vector<int>::iterator frameIds;
        //        for(frameIds = pointcloudApplication->frameId.begin() ; frameIds!=pointcloudApplication->frameId.end() ; frameIds++)
        //        {
        //            [frameIdData appendBytes:frameIds length:sizeof(int)];
        //        }
        //
        //        NSMutableData *cameraMatrixData = [[NSMutableData alloc] init];
        //        cv::Vector<cv::Mat>::iterator cameraMat;
        //        for(cameraMat = pointcloudApplication->cameraMatrixVec.begin() ; cameraMat!=pointcloudApplication->cameraMatrixVec.end() ; cameraMat++)
        //        {
        //            for (int i=0; i<4; i++) {
        //                for (int j=0; j<4; j++) {
        //                    [cameraMatrixData appendBytes:&cameraMat->at<float>(i,j) length:sizeof(float)];
        //                }
        //            }
        //
        //
        //        }
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        NSString *filePath = [documentsDirectory stringByAppendingPathComponent:@"result.ply"];
        [data writeToFile:filePath atomically:true];
        //        NSString *filePath2 = [documentsDirectory stringByAppendingPathComponent:@"frames.bin"];
        //        [frameIdData writeToFile:filePath2 atomically:true];
        //        NSString *filePath3 = [documentsDirectory stringByAppendingPathComponent:@"cameraMats.bin"];
        //        [cameraMatrixData writeToFile:filePath3 atomically:true];
        
        
        //        NSLog(plyFile);
        
    }
    pointcloudApplication->_record = !pointcloudApplication->_record;
    
    
}

- (cv::Mat) FindSurface {
    
    int numPoints = pointcloudApplication->realWorldLaserPoints.size();
    cv::Mat A(numPoints,4,CV_32F);
    cv::Mat surfaceCoeffs;
    
    
    for (int i =0; i < numPoints; i++) {
        A.at<float>(i,0) = pointcloudApplication->realWorldLaserPoints[i].x;
        A.at<float>(i,1) = pointcloudApplication->realWorldLaserPoints[i].y;
        A.at<float>(i,2) = pointcloudApplication->realWorldLaserPoints[i].z;
        A.at<float>(i,3) = 1.0;
        
    }
    
    
    cv::SVD::solveZ(A, surfaceCoeffs);
    std::cout <<"surface coeffs: "<< surfaceCoeffs << std::endl;
    cv::Mat product = A * surfaceCoeffs;
    std::cout << "should be zero: "<< product <<std::endl;
    
    
    return surfaceCoeffs;
}




//- (void) findIntersection {
//    cv::Mat input1(360,480,CV_8U);
//    cv::Mat input2(360,480,CV_8U);
//
//    // populate the input for hough lines algorithem
//    for (int i =0 ; i < VERTICAL_LINE_MARGINE ; i++)
//    {
//        input1.at<unsigned char>(i,pointcloudApplication->_indices[i]+50) = 255;
//
//    }
//    for (int i =360-VERTICAL_LINE_MARGINE ; i < 360 ; i++)
//    {
//        input2.at<unsigned char>(i,pointcloudApplication->_indices[i]+50) = 255;
//
//    }
//
//    // use hough transform to find the straight lines
//
//    cv::vector<cv::Vec2f> lines1 , lines2;
//
//    HoughLines(input1, lines1, 1, CV_PI/180, 20, 0, 0 );
//    HoughLines(input2, lines2, 1, CV_PI/180, 20, 0, 0 );
//    cv::Point2f pt1(0,0), pt2(0,0) ,pt3(0,0), pt4(0,0) ,meetingPoint(0.0);
//    cv::Point3f meetingPointRealWorld;
//
//    if (lines1.size() >0)
//    {
//        float rho = lines1[0][0], theta = lines1[0][1];
//        double a = cos(theta), b = sin(theta);
//        double x0 = a*rho, y0 = b*rho;
//        pt1.x = cvRound(x0 + 1000*(-b));
//        pt1.y = cvRound(y0 + 1000*(a));
//        pt2.x = cvRound(x0 - 1000*(-b));
//        pt2.y = cvRound(y0 - 1000*(a));
//    }
//
//    if (lines2.size() >0)
//    {
//        float rho = lines2[0][0], theta = lines2[0][1];
//        double a = cos(theta), b = sin(theta);
//        double x0 = a*rho, y0 = b*rho;
//        pt3.x = cvRound(x0 + 1000*(-b));
//        pt3.y = cvRound(y0 + 1000*(a));
//        pt4.x = cvRound(x0 - 1000*(-b));
//        pt4.y = cvRound(y0 - 1000*(a));
//    }
//
//
//    // find meeting point
//    if (pt1.x != 0 && pt3.x !=0) {
//        float slope1, slope2, cross1 , cross2;
//
//        slope1 = (pt2.y - pt1.y)/(pt2.x-pt1.x);
//        slope2 = (pt4.y - pt3.y)/(pt4.x-pt3.x);
//        cross1 = (pt1.y - pt1.x*(pt2.y-pt1.y)/(pt2.x-pt1.x));
//        cross2 = (pt3.y - pt3.x*(pt4.y-pt3.y)/(pt4.x-pt3.x));
//        meetingPoint.x = (cross2 - cross1) / (slope1-slope2);;
//        meetingPoint.y = slope1 * meetingPoint.x + cross1;
//
//        // find real world meeting point and save to queue
//        cv::Mat realWorldPoint = [self findRealWorldPoint:(void*) pointcloudApplication->camera_matrix.data :&meetingPoint];
//        meetingPointRealWorld.x = realWorldPoint.at<float>(0);
//        meetingPointRealWorld.y = realWorldPoint.at<float>(1);
//        meetingPointRealWorld.z = realWorldPoint.at<float>(2);
//
//        (pointcloudApplication->_meetingPoints).push(meetingPointRealWorld);
//
//    }
//
//}





- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
	CGPoint pt = [[touches anyObject] locationInView:self.glView];
	if (pointcloudApplication) {
		pointcloudApplication->on_touch_moved(pt.x, pt.y);
	}
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	CGPoint pt = [[touches anyObject] locationInView:self.glView];
	if (pointcloudApplication) {
		pointcloudApplication->on_touch_ended(pt.x, pt.y);
	}
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	CGPoint pt = [[touches anyObject] locationInView:self.glView];
	if (pointcloudApplication) {
		pointcloudApplication->on_touch_started(pt.x, pt.y);
	}
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
	CGPoint pt = [[touches anyObject] locationInView:self.glView];
	if (pointcloudApplication) {
		pointcloudApplication->on_touch_cancelled(pt.x, pt.y);
	}
}


#import <sys/utsname.h>

struct utsname systemInfo;

const char*
machineName()
{
    uname(&systemInfo);
	
    return systemInfo.machine;
}

- (void)startGraphics {
	if (pointcloudApplication)
		pointcloudApplication->on_resume();
}

- (void)stopGraphics {
	if (pointcloudApplication)
		pointcloudApplication->on_pause();
    if (videoProcessor)
        [videoProcessor sendStopRecordingMessage];
}

- (void)drawView:(GLView*)view {
	CVReturn lockResult = CVPixelBufferLockBaseAddress (self.pixelBuffer, 0);
	if(lockResult == kCVReturnSuccess) {
		if (accelerometer_available) {
			if (!motionManager.accelerometerActive)
				[motionManager startAccelerometerUpdates];
			
			CMAccelerometerData *accelerometerData = motionManager.accelerometerData;
			if (accelerometerData) {
				CMAcceleration acceleration = accelerometerData.acceleration;
				
				pointcloudApplication->on_accelerometer_update(acceleration.y, acceleration.x, acceleration.z, timestamp);
			}
		}
		if (device_motion_available) {
			if (!motionManager.deviceMotionActive)
				[motionManager startDeviceMotionUpdates];
			
			CMDeviceMotion *deviceMotion = motionManager.deviceMotion;
			if (deviceMotion) {
				CMAcceleration device_acceleration = deviceMotion.userAcceleration;
				CMRotationRate device_rotation_rate = deviceMotion.rotationRate;
                CMAcceleration gravity = deviceMotion.gravity;
				
				pointcloudApplication->on_device_motion_update(device_acceleration.y,
															   device_acceleration.x,
															   device_acceleration.z,
															   device_rotation_rate.y,
															   device_rotation_rate.x,
															   device_rotation_rate.z,
                                                               gravity.y,
                                                               gravity.x,
                                                               gravity.z,
                                                               timestamp);
			}
		}
		
		char* ba = (char*)CVPixelBufferGetBaseAddress(self.pixelBuffer);
		pointcloudApplication->render_frame(ba, CVPixelBufferGetDataSize(self.pixelBuffer), timestamp);
		
		CVPixelBufferUnlockBaseAddress (self.pixelBuffer, 0);
		return;
	}
}

-(void)setupView:(GLView*)view {
}

- (void)initCapture {
	[[UIApplication sharedApplication] setIdleTimerDisabled:YES];
    
	captureSession = [[AVCaptureSession alloc] init];
    
	NSArray *arr = [AVCaptureDevice devices];
	
	AVCaptureDevice *device = nil;
	NSError *outError = nil;
    
    for(int i=0; i<[arr count] && device == nil; i++) {
        AVCaptureDevice *d = [arr objectAtIndex:i];
		if (d.position == AVCaptureDevicePositionBack && [d hasMediaType: AVMediaTypeVideo]) {
			device = d;
		}
    }
	
	if (device == nil) {
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"No camera found"
														message:@"You need a device with a back-facing camera to run this app."
													   delegate:self
											  cancelButtonTitle:@"Quit"
											  otherButtonTitles:nil];
		[alert show];
		[alert release];
		return;
	}
    
    if ([device respondsToSelector:@selector(isAutoFocusRangeRestrictionSupported)] && device.autoFocusRangeRestrictionSupported) {
        // If we are on an iOS version that supports AutoFocusRangeRestriction and the device supports it
        // Set the focus range to "near"
        if ([device lockForConfiguration:nil]) {
            device.autoFocusRangeRestriction = AVCaptureAutoFocusRangeRestrictionFar;
            [device unlockForConfiguration];
        }
    }
    
	AVCaptureFocusMode wantedFocusMode = AVCaptureFocusModeAutoFocus;
	if ([device isFocusModeSupported: wantedFocusMode]) {
		if ([device lockForConfiguration: &outError]) {
			[device setFocusMode: wantedFocusMode];
			[device unlockForConfiguration];
		} else {
			NSLog(@"lockForConfiguration ERROR: %@", outError);
		}
	}
    
	
    AVCaptureDeviceInput *devInput = [[[AVCaptureDeviceInput alloc] initWithDevice:device error:&outError] autorelease];
    
    if (!devInput) {
        NSLog(@"ERROR: %@",outError);
        return;
    }
    
	if (device == nil) {
		NSLog(@"Device is nil");
	}
	
	AVCaptureVideoDataOutput *output = [[[AVCaptureVideoDataOutput alloc] init] autorelease];
    output.alwaysDiscardsLateVideoFrames = YES;
    
    NSMutableDictionary *videoSettings = [[[NSMutableDictionary alloc] init] autorelease];
    
    [videoSettings setValue:[NSNumber numberWithUnsignedInt:kCVPixelFormatType_32BGRA] forKey:(NSString*) kCVPixelBufferPixelFormatTypeKey];
    
	[output setVideoSettings:videoSettings];
    
    [output setSampleBufferDelegate:self queue:dispatch_get_current_queue()];
    
    [self.captureSession addInput:devInput];
    
    [self.captureSession addOutput:output];
    
    double max_fps = 30;
    NSString *deviceName = [NSString stringWithUTF8String:machineName()];
    if ([deviceName isEqualToString:@"iPhone2,1"] || [deviceName isEqualToString:@"iPhone3,1"]) {
        max_fps = 15;//Lower frame rate on iPhone 3GS and iPhone 4 for increased image detection performance
    }
    
    NSLog(@"FPS %f", max_fps);
    
    for(int i = 0; i < [[output connections] count]; i++) {
        AVCaptureConnection *conn = [[output connections] objectAtIndex:i];
        if (conn.supportsVideoMinFrameDuration) {
            conn.videoMinFrameDuration = CMTimeMake(1, max_fps);
        }
        if (conn.supportsVideoMaxFrameDuration) {
            conn.videoMaxFrameDuration = CMTimeMake(1, max_fps);
        }
    }
    
    [self.captureSession setSessionPreset: AVCaptureSessionPresetMedium];
    
    NSArray *events = [NSArray arrayWithObjects:
                       AVCaptureSessionRuntimeErrorNotification,
                       AVCaptureSessionErrorKey,
                       AVCaptureSessionDidStartRunningNotification,
                       AVCaptureSessionDidStopRunningNotification,
                       AVCaptureSessionWasInterruptedNotification,
                       AVCaptureSessionInterruptionEndedNotification,
                       nil];
    
    for (id e in events) {
        [[NSNotificationCenter defaultCenter]
         addObserver:self
         selector:@selector(eventHandler:)
         name:e
         object:nil];
    }
    
    [NSTimer scheduledTimerWithTimeInterval:0.05 target:self selector:@selector(startCamera) userInfo:nil repeats:NO];
}


- (void) realCaptureOutput:(id) pixData {
    NSData * data = (NSData *) pixData;
    
    CMSampleBufferRef sampleBuffer = (CMSampleBufferRef) [data bytes];
    
    timestamp = CMTimeGetSeconds(CMSampleBufferGetPresentationTimeStamp(sampleBuffer));
    
    CVImageBufferRef imgBuff = CMSampleBufferGetImageBuffer(sampleBuffer);
    CFRetain(imgBuff);
    CVPixelBufferRef pixBuff = imgBuff;
    
    int w = CVPixelBufferGetWidth(pixBuff);
    int h = CVPixelBufferGetHeight(pixBuff);
    
    if (w == 0 && !restartingCamera) {
        NSLog(@"Bad image data, restarting session...?!");
        [self.captureSession stopRunning];
        restartingCamera = true;
        [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(startCamera) userInfo:nil repeats:NO];
        return;
    }
	
	// Create the application once we get the first camera frame
	if (!pointcloudApplication) {
		NSArray* paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
		NSString* documentsDirectory = [paths objectAtIndex:0]; // User-accesible file system path
		NSString *resourcePath = [NSString stringWithFormat:@"%@/", [[NSBundle mainBundle] resourcePath]];
        
		pointcloudApplication = new TestApp(self.glView.bounds.size.width,
											self.glView.bounds.size.height,
											w,
											h,
											POINTCLOUD_BGRA_8888,
											[resourcePath cStringUsingEncoding:[NSString defaultCStringEncoding]],
											[documentsDirectory cStringUsingEncoding:[NSString defaultCStringEncoding]],
											machineName(),
											g_scale);
	}
    
	self.pixelBuffer = pixBuff;
	
    
    [glView drawView];
    if (videoProcessor.isRecording)
    {

        
        [videoProcessor updateAssetWriter:sampleBuffer]; // this will retain the data on a separate thread ... if it gives problems u should try changing initWithBytesNoCopy to something that does a deep copy
        
    }
    
	
    self.pixelBuffer = nil;
	
    CFRelease(imgBuff);
}

// Capture delegate
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    
    if (sampleBuffer == nil) {
        NSLog(@"Received nil sampleBuffer from %@ with connection %@",captureOutput,connection);
        return;
    }
	
    CFRetain(sampleBuffer);
    
    NSData *data = [[NSData alloc] initWithBytesNoCopy:sampleBuffer length:4 freeWhenDone:NO];
    
	// Make sure that we handle the camera data in the main thread
	if (![NSThread isMainThread]) {
        [self performSelectorOnMainThread:@selector(realCaptureOutput:) withObject:data waitUntilDone:true];
    } else {
        [self realCaptureOutput: data];
    }
    
    [data release];
	
    CFRelease(sampleBuffer);
}

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	NSLog(@"Memory warning received");
}

- (void)viewDidUnload {
    
}

-(void)viewDidDisappear:(BOOL)animated
{
    delete pointcloudApplication;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return (interfaceOrientation==UIInterfaceOrientationPortrait);
}

- (BOOL)shouldAutorotate {
	return YES;
}

-(NSUInteger)supportedInterfaceOrientations{
	return UIInterfaceOrientationMaskPortrait;
}

- (void)dealloc {
	[captureSession release];
    
	[super dealloc];
}
#pragma mark VideoWriterDelegate

- (void)recordingWillStart
{
	dispatch_async(dispatch_get_main_queue(), ^{
		//[[self recordButton] setEnabled:NO];
		//[[self recordButton] setTitle:@"Stop"];
        
		// Disable the idle timer while we are recording
		[UIApplication sharedApplication].idleTimerDisabled = YES;
        
		// Make sure we have time to finish saving the movie if the app is backgrounded during recording
		if ([[UIDevice currentDevice] isMultitaskingSupported])
			backgroundRecordingID = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{}];
	});
}

- (void)recordingDidStart
{
	dispatch_async(dispatch_get_main_queue(), ^{
		//[[self recordButton] setEnabled:YES];
	});
}

- (void)recordingWillStop
{
	dispatch_async(dispatch_get_main_queue(), ^{
		// Disable until saving to the camera roll is complete
		//[[self recordButton] setTitle:@"Record"];
		//[[self recordButton] setEnabled:NO];
		
		// Pause the capture session so that saving will be as fast as possible.
		// We resume the sesssion in recordingDidStop:
		//[videoProcessor pauseCaptureSession];
	});
}

- (void)recordingDidStop
{
	dispatch_async(dispatch_get_main_queue(), ^{
		//[[self recordButton] setEnabled:YES];
		
		[UIApplication sharedApplication].idleTimerDisabled = NO;
        
		//[videoProcessor resumeCaptureSession];
        
		if ([[UIDevice currentDevice] isMultitaskingSupported]) {
			[[UIApplication sharedApplication] endBackgroundTask:backgroundRecordingID];
			backgroundRecordingID = UIBackgroundTaskInvalid;
		}
	});
}

///*- (void)pixelBufferReadyForDisplay:(CVPixelBufferRef)pixelBuffer
// {
// // Don't make OpenGLES calls while in the background.
// /if ( [UIApplication sharedApplication].applicationState != UIApplicationStateBackground )
// [oglView displayPixelBuffer:pixelBuffer];
// //}*/
//
//
//
//
@end


// Forward decl.
static char *getRGBA(UIImage * image);

// Simple interface from C++ layer to read PNG resource files as RGBA
bool read_png_image(const char *filename, char **data, int *width, int *height) {
	NSString* fileNameNS = [NSString stringWithUTF8String:filename];
	UIImage* image = [UIImage imageNamed:fileNameNS];
	if (image) {
		*width = (int)image.size.width;
		*height = (int)image.size.height;
		*data = getRGBA(image);
		return true;
	}
	else {
		NSLog(@"No such image %@", fileNameNS);
	}
	return false;
}


// Get RGBA data from an UIImage

static char * getRGBA(UIImage * image) {
	size_t width = CGImageGetWidth(image.CGImage);
	size_t height = CGImageGetHeight(image.CGImage);
	size_t bitsPerComponent = 8;
	size_t bytesPerRow = width * 4;
	
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB(); assert(colorSpace);
	
	void *data = malloc(bytesPerRow * height); assert(data);
	memset(data,0,bytesPerRow * height);
	
	CGContextRef context = CGBitmapContextCreate(data,
												 width,
												 height,
												 bitsPerComponent,
												 bytesPerRow,
												 colorSpace,
												 kCGImageAlphaPremultipliedLast);
	
	assert(context);
	
	CGColorSpaceRelease(colorSpace);
	
	// Draw image on bitmap
	CGContextDrawImage(context, CGRectMake(0, 0, width, height), image.CGImage);
	
	CGContextRelease(context);
	
	return (char*) data;
}


