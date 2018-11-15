//
//  ViewController.h
//  MovementTracker
//
//  Created by Joshua on 2018-11-14.
//  Copyright © 2018 jtc260. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MultipeerConnectivity/MultipeerConnectivity.h>
#import <CoreMotion/CMMotionManager.h>

#define SERVICE_TYPE @"mt-4768"
#define FILTERNO     0
#define FILTERLOW    1
#define FILTERHIGH   2

@interface ViewController : UIViewController <MCSessionDelegate, MCBrowserViewControllerDelegate>

@end
