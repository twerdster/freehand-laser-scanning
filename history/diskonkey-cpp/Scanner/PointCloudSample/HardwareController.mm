/**
 * Copyright (C) 2012 13th Lab AB
 *
 * See the LICENSE file that came with this example code.
 */

#import "HardwareController.h"
#include "TestApp.h"
#include <opencv2/opencv.hpp>

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


- (NSString *)dataFilePath:(NSString*) fileName {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    
    NSString *docDirectory = [paths objectAtIndex:0];
    return [docDirectory stringByAppendingPathComponent:fileName];
}


- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error {
	[self becomeFirstResponder];
	[self dismissViewControllerAnimated:YES completion:^(void){}];
    //[self dismissModalViewControllerAnimated:YES];
}

- (void) emailFile
{
    MFMailComposeViewController* controller = [[MFMailComposeViewController alloc] init];
    controller.mailComposeDelegate = self;
    [controller setToRecipients:[NSArray array]];
    [controller setSubject:@"My Subject"];
    [controller setMessageBody:@"Latest Data." isHTML:NO];
    NSData *myData = [NSData dataWithContentsOfFile: [self dataFilePath:@"Data.txt"] ];
    
    [controller addAttachmentData:myData mimeType:@"mime" fileName:@"Data.txt"];
    [self presentViewController:controller animated:YES completion:^(){}];
    //if (controller) [self presentModalViewController:controller animated:YES];
    [controller release];
}


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
	
	[glView setDelegate:self];
    glView.multipleTouchEnabled = YES;
	[self setView:glView];
	
    
    videoProcessor = [[VideoWriter alloc] init];
	videoProcessor.delegate = self;
    /*// Keep track of changes to the device orientation so we can update the video processor
	NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
	[notificationCenter addObserver:self selector:@selector(deviceOrientationDidChange) name:UIDeviceOrientationDidChangeNotification object:nil];
	[[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
	*/
    
    /*recordDataButton = [self but:@"" yPosition: (CGFloat) 10.0];
	[previewView addSubview:frameRateLabel];*/
	
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
    
    // Additional UI
    recordButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [recordButton addTarget:self
               action:@selector(toggleRecording:)
     forControlEvents:UIControlEventTouchDown];
    [recordButton setTitle:@"R" forState:UIControlStateNormal];
    recordButton.frame = CGRectMake(5, 5.0, 100.0, 100.0);
    [recordButton setAlpha:0.3];
    [self.glView addSubview:recordButton];
    [recordButton release];
}


- (void) deleteFile
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    [fileManager removeItemAtPath:[self dataFilePath:@"Data.txt"] error:NULL];
}

- (void)toggleRecording:(id) sender
{
	// Wait for the recording to start/stop before re-enabling the record button.
	
	
	if ( [videoProcessor isRecording] ) {
		// The recordingWill/DidStop delegate methods will fire asynchronously in response to this call
		[videoProcessor stopRecording];
        [recordButton setTitle:@"R" forState:UIControlStateNormal];
        [ self emailFile];
	}
	else {
		// The recordingWill/DidStart delegate methods will fire asynchronously in response to this call
        [self deleteFile];
        frameCount = 0;
        [videoProcessor startRecording];
        [recordButton setTitle:@"..." forState:UIControlStateNormal];
	}
}

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
    	
	AVCaptureFocusMode wantedFocusMode = AVCaptureFocusModeContinuousAutoFocus;
    
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
    
    
    /*dispatch_queue_t videoCaptureQueue = dispatch_queue_create("Video Capture Queue", DISPATCH_QUEUE_SERIAL);
	[videoOut setSampleBufferDelegate:self queue:videoCaptureQueue];
	dispatch_release(videoCaptureQueue);*/
	
    

    
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

- (void) log:(NSString *)content
{
    
    //Get the file path
    NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains (NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *fileName = [documentsDirectory stringByAppendingPathComponent:@"Data.txt"];
    
    //create file if it doesn't exist
    if(![[NSFileManager defaultManager] fileExistsAtPath:fileName])
        [[NSFileManager defaultManager] createFileAtPath:fileName contents:nil attributes:nil];
    
    //append text to file (you'll probably want to add a newline every write)
    NSFileHandle *file = [NSFileHandle fileHandleForUpdatingAtPath:fileName];
    [file seekToEndOfFile];
    [file writeData:[content dataUsingEncoding:NSUTF8StringEncoding]];
    [file closeFile];
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
											w, h,
											POINTCLOUD_BGRA_8888,
											[resourcePath cStringUsingEncoding:[NSString defaultCStringEncoding]], 
											[documentsDirectory cStringUsingEncoding:[NSString defaultCStringEncoding]],
											machineName(),
											g_scale);
	}
    
	self.pixelBuffer = pixBuff;
	
    
    [glView drawView];
    
    
    if (pointcloudApplication->isTracking())
    {
        NSString *str;
        char buf[10000];
        sprintf(buf,"");
        
        for (int i = 0; i < 16; i++ )
            sprintf(buf + strlen(buf), "%f ",pointcloudApplication->projection_matrix.data[i]);
        
        for (int i = 0; i < 16; i++ )
            sprintf(buf + strlen(buf), "%f ",pointcloudApplication->camera_matrix.data[i]);

        
        str = [NSString stringWithFormat:@"%i %s\n",frameCount,buf];
        
        [videoProcessor updateAssetWriter:sampleBuffer andLog:str]; // this will retain the data on a separate thread ... if it gives problems u should try changing initWithBytesNoCopy to something that does a deep copy
        
        if (videoProcessor.isRecording)
            frameCount++;
        //printf("%i\n",frameCount);
        
    }
    
    //pointcloudApplication->projection_matrix;
	//pointcloudApplication->camera_matrix;
    
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
    
    // Can use this to synch track data
    //CMTime timestamp = CMSampleBufferGetPresentationTimeStamp( sampleBuffer );
    //[videoProcessor calculateFramerateAtTimestamp:timestamp];
    
    
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
    [videoProcessor tearDownRecording];
    videoProcessor.delegate = nil;
    [videoProcessor release];
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

/*- (void)pixelBufferReadyForDisplay:(CVPixelBufferRef)pixelBuffer
{
	// Don't make OpenGLES calls while in the background.
	/if ( [UIApplication sharedApplication].applicationState != UIApplicationStateBackground )
		[oglView displayPixelBuffer:pixelBuffer];
//}*/




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






