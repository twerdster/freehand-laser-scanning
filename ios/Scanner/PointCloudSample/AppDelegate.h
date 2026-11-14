/**
 * Copyright (C) 2012 13th Lab AB
 *
 * See the LICENSE file that came with this example code.
 */ 

#import <UIKit/UIKit.h>
#import "HardwareController.h"
#import "MyGLKViewController.h"

@class HardwareController;

@interface AppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *window;
	HardwareController *cameraViewController;
    MyGLKViewController *kiwiViewController;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) HardwareController *cameraViewController;
@property (nonatomic, retain) MyGLKViewController *kiwiViewcontroller;


@end

