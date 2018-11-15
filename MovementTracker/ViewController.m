//
//  ViewController.m
//  MovementTracker
//
//  Created by Joshua on 2018-11-14.
//  Copyright © 2018 jtc260. All rights reserved.
//

#import "ViewController.h"

@interface ViewController () {
    int _filterMode;
    float _accX, _accY, _accZ;
    float _avgX, _avgY, _avgZ;
    float _varX, _varY, _varZ;
    float _rotPitch, _rotRoll, _rotYaw;
    BOOL connected;
    CGRect originalViewFrame;
}
@property (strong, nonatomic) CMMotionManager *motman;
@property (strong, nonatomic) NSTimer *timer;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *browseButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *disconnectButton;
@property (weak, nonatomic) IBOutlet UILabel *xLabel;
@property (weak, nonatomic) IBOutlet UILabel *yLabel;
@property (weak, nonatomic) IBOutlet UILabel *zLabel;
@property (weak, nonatomic) IBOutlet UILabel *pitchLabel;
@property (weak, nonatomic) IBOutlet UILabel *rollLabel;
@property (weak, nonatomic) IBOutlet UILabel *yawLabel;
@property (weak, nonatomic) IBOutlet UIView *xNeg;
@property (weak, nonatomic) IBOutlet UIView *xPos;
@property (weak, nonatomic) IBOutlet UIView *yNeg;
@property (weak, nonatomic) IBOutlet UIView *yPos;
@property (weak, nonatomic) IBOutlet UIView *zNeg;
@property (weak, nonatomic) IBOutlet UIView *zPos;
@property (weak, nonatomic) IBOutlet UIView *rollPos;
@property (weak, nonatomic) IBOutlet UIView *pitchPos;
@property (weak, nonatomic) IBOutlet UIView *yawPos;
@property (weak, nonatomic) IBOutlet UIView *pitchNeg;
@property (weak, nonatomic) IBOutlet UIView *rollNeg;
@property (weak, nonatomic) IBOutlet UIView *yawNeg;
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;
@property (strong, nonatomic) MCSession *session;
@property (strong, nonatomic) MCAdvertiserAssistant *assistant;
@property (strong, nonatomic) MCBrowserViewController *browserVC;

- (IBAction)browseButtonTapped:(UIBarButtonItem *)sender;
- (IBAction)disconnectButtonTapped:(UIBarButtonItem *)sender;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self startMonitoringMotion];
    connected = NO;
    originalViewFrame = self.view.frame;
    [self prepareSession];
    [self startAdvertising];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (connected)
        [self setUIToConnectedState];
    else
        [self setUIToNotConnectedState];
}

- (IBAction)segmentDidChange:(UISegmentedControl*)sender {
    switch (sender.selectedSegmentIndex) {
        case 0:
            _filterMode = FILTERLOW;
            break;
        case 1:
            _filterMode = FILTERNO;
            break;
        case 2:
            _filterMode = FILTERHIGH;
            break;
    }
}

#pragma Motion Monitoring Methods
- (void) startMonitoringMotion {
    self.motman = [[CMMotionManager alloc] init];
    if (!self.motman.accelerometerAvailable || !self.motman.gyroAvailable) {
        NSLog(@"No Accelerometer or No Gyro");
        return;
    }
    self.motman.accelerometerUpdateInterval = 0.05;
    self.motman.gyroUpdateInterval = 0.05;
    [self.motman startAccelerometerUpdates];
    [self.motman startGyroUpdates];
    self.timer = [NSTimer scheduledTimerWithTimeInterval: 0.05 target: self selector: @selector(pollMotion:) userInfo:nil repeats:YES];
}

- (void)pollMotion:(NSTimer *)timer {
    CMAcceleration acc = self.motman.accelerometerData.acceleration;
    CMRotationRate rot = self.motman.gyroData.rotationRate;
    NSArray* rots = [NSArray arrayWithObjects:[NSNumber numberWithDouble:rot.x],[NSNumber numberWithDouble:rot.y],[NSNumber numberWithDouble:rot.z], nil];
    NSArray* rotViews = [NSArray arrayWithObjects:self.pitchPos, self.rollPos, self.yawPos, nil];
    [self addAcceleration:acc];
    NSArray* nf = [NSArray arrayWithObjects:[NSNumber numberWithDouble:acc.x],[NSNumber numberWithDouble:acc.y],[NSNumber numberWithDouble:acc.z], nil];
    NSArray* lp = [NSArray arrayWithObjects:[NSNumber numberWithDouble:_avgX],[NSNumber numberWithDouble:_avgY],[NSNumber numberWithDouble:_avgZ], nil];
    NSArray* hp = [NSArray arrayWithObjects:[NSNumber numberWithDouble:_varX],[NSNumber numberWithDouble:_varY],[NSNumber numberWithDouble:_varZ], nil];
    float scale = 100;
    float rotScale = 50;
    UIView *v = nil;
    self.pitchLabel.text = [[NSNumber numberWithFloat:rot.x] stringValue];
    for (int i=0 ; i<=2 ; i++) {
        if (rots[i] >= 0) {
            v = rotViews[i];
            v.backgroundColor = [UIColor redColor];
            CGRect frame = v.frame;
            frame.origin.y = 751 + ([rots[i] doubleValue]*rotScale);
            frame.size.height = -[rots[i] doubleValue] * rotScale;
            v.frame = frame;
        } else {
            v = self.pitchPos;
            v.backgroundColor = [UIColor greenColor];
            CGRect frame = v.frame;
            frame.size.height = [rots[i] doubleValue] * rotScale;
            frame.origin.y = 751;
            v.frame = frame;
        }
    }
    switch (_filterMode) {
        case FILTERNO:
            for (int i = 0 ; i <=2 ; i++) {
                if (acc.x >= 0) {
                    v = self.xPos;
                    v.backgroundColor = [UIColor redColor];
                    CGRect frame = v.frame;
                    frame.origin.y = 281 + (acc.x*scale);
                    frame.size.height = -acc.x * scale;
                    v.frame = frame;
                } else {
                    v = self.xPos;
                    v.backgroundColor = [UIColor greenColor];
                    CGRect frame = v.frame;
                    frame.size.height = acc.x * scale;
                    frame.origin.y = 281;
                    v.frame = frame;
                }
            }
        case FILTERLOW:
            if (_avgX >= 0) {
                v = self.xPos;
                v.backgroundColor = [UIColor redColor];
                CGRect frame = v.frame;
                frame.origin.y = 281 + (_avgX*scale);
                frame.size.height = -_avgX * scale;
                v.frame = frame;
            } else {
                v = self.xPos;
                v.backgroundColor = [UIColor greenColor];
                CGRect frame = v.frame;
                frame.size.height = _avgX * scale;
                frame.origin.y = 281;
                v.frame = frame;
            }
            if (_avgY >= 0) {
                v = self.yPos;
                v.backgroundColor = [UIColor redColor];
                CGRect frame = v.frame;
                frame.origin.y = 281 + (_avgY*scale);
                frame.size.height = -_avgY * scale;
                v.frame = frame;
            } else {
                v = self.yPos;
                v.backgroundColor = [UIColor greenColor];
                CGRect frame = v.frame;
                frame.size.height = _avgY * scale;
                frame.origin.y = 281;
                v.frame = frame;
            }
            if (_avgZ >= 0) {
                v = self.zPos;
                v.backgroundColor = [UIColor redColor];
                CGRect frame = v.frame;
                frame.origin.y = 281 + (_avgZ*scale);
                frame.size.height = -_avgZ * scale;
                v.frame = frame;
            } else {
                v = self.zPos;
                v.backgroundColor = [UIColor greenColor];
                CGRect frame = v.frame;
                frame.size.height = _avgZ * scale;
                frame.origin.y = 281;
                v.frame = frame;
            }
            break;
        case FILTERHIGH:
            if (_varX >= 0) {
                v = self.xPos;
                v.backgroundColor = [UIColor redColor];
                CGRect frame = v.frame;
                frame.origin.y = 281 + (_varX*scale);
                frame.size.height = -_varX * scale;
                v.frame = frame;
            } else {
                v = self.xPos;
                v.backgroundColor = [UIColor greenColor];
                CGRect frame = v.frame;
                frame.size.height = _varX * scale;
                frame.origin.y = 281;
                v.frame = frame;
            }
            if (_varY >= 0) {
                v = self.yPos;
                v.backgroundColor = [UIColor redColor];
                CGRect frame = v.frame;
                frame.origin.y = 281 + (_varY*scale);
                frame.size.height = -_varY * scale;
                v.frame = frame;
            } else {
                v = self.yPos;
                v.backgroundColor = [UIColor greenColor];
                CGRect frame = v.frame;
                frame.size.height = _varY * scale;
                frame.origin.y = 281;
                v.frame = frame;
            }
            if (_varZ >= 0) {
                v = self.zPos;
                v.backgroundColor = [UIColor redColor];
                CGRect frame = v.frame;
                frame.origin.y = 281 + (_varZ*scale);
                frame.size.height = -_varZ * scale;
                v.frame = frame;
            } else {
                v = self.zPos;
                v.backgroundColor = [UIColor greenColor];
                CGRect frame = v.frame;
                frame.size.height = _varZ * scale;
                frame.origin.y = 281;
                v.frame = frame;
            }
            break;
    }
    [self.view setNeedsDisplay];
}

/*- (void)drawRect:(CGRect)rect
{
    // Acceleration
    float scale = 100;
    NSArray *rulers = [NSArray arrayWithObjects:self.xPos, self.xNeg, self.yPos, self.yNeg, self.xPos, self.zNeg, nil];
    CGFloat acc[3] = {_accX, _accY, _accZ};
    for (int i = 0; i<3; i++)
    {
        UIView *v = [rulers objectAtIndex:i];
        CGRect frame = v.frame;
        if (acc[i]>=0)
        {
            frame.size.height = acc[i]*scale;
            frame.origin.x = 160;
        }
        else
        {
            frame.origin.x = 160 + acc[i]*scale;
            frame.size.height = -acc[i]*scale;
        }
        v.frame = frame;
    }
    // Rotation
    scale = 50;
    rulers = [NSArray arrayWithObjects:self.viewRotX, self.viewRotY, self.viewRotZ, nil];
    CGFloat rot[] = {_rotPitch, _rotRoll, _rotYaw};
    for (int i = 0; i<3; i++)
    {
        UIView *v = [rulers objectAtIndex:i];
        CGRect frame = v.frame;
        if (rot[i]>=0)
        {
            frame.size.width = rot[i]*scale;
            frame.origin.x = 160;
        }
        else
        {
            frame.origin.x = 160 + rot[i]*scale;
            frame.size.width = -rot[i]*scale;
        }
        v.frame = frame;
    }
 
}*/

-(void) addAcceleration: (CMAcceleration) acc{
    float alpha = 0.1;
    _avgX = alpha*acc.x + (1-alpha)*_avgX;
    _avgY = alpha*acc.y + (1-alpha)*_avgY;
    _avgZ = alpha*acc.z + (1-alpha)*_avgZ;
    _varX = acc.x - _avgX;
    _varY = acc.y - _avgY;
    _varZ = acc.z - _avgZ;
}

#pragma Peer-To-Peer Connectivity Related Methods
- (void) prepareSession {
    MCPeerID *myPeerID = [[MCPeerID alloc] initWithDisplayName:[[UIDevice currentDevice] name]];
    self.session = [[MCSession alloc] initWithPeer:myPeerID];
}

- (void) startAdvertising {
    self.assistant = [[MCAdvertiserAssistant alloc] initWithServiceType:SERVICE_TYPE discoveryInfo:nil session:self.session];
    [self.assistant start];
}

- (IBAction)browseButtonTapped:(UIBarButtonItem *)sender {
    self.browserVC = [[MCBrowserViewController alloc] initWithServiceType:SERVICE_TYPE session:self.session];
    self.browserVC.delegate = self;
    [self presentViewController:self.browserVC animated:YES completion:nil];
}

/*- (IBAction)sendButtonTapped:(UIButton *)sender {
    NSArray *peerIDs = self.session.connectedPeers;
    NSString *str = self.textInput.text;
    [self.session sendData:[str dataUsingEncoding:NSASCIIStringEncoding]
                   toPeers:peerIDs
                  withMode:MCSessionSendDataReliable error:nil];
    self.textInput.text = @"";
    [self.textInput resignFirstResponder];
    // echo in the local text view
    self.textView.text = [NSString stringWithFormat:@"%@\n> %@", self.textView.text, str];
}*/

- (IBAction)disconnectButtonTapped:(UIBarButtonItem *)sender {
    [self setUIToNotConnectedState];
    connected = NO;
    [self.session disconnect];
    self.statusLabel.text = @"Status: disconnected";
}

- (void)session:(MCSession *)session peer:(MCPeerID *)peerID didChangeState:(MCSessionState)state {
    NSString *str = [NSString stringWithFormat:@"Status: %@", peerID.displayName];
    if (state == MCSessionStateConnected) {
        self.statusLabel.text = [str stringByAppendingString:@" connected"];
        [self setUIToConnectedState];
        connected = YES;
    } else if (state == MCSessionStateNotConnected) {
        self.statusLabel.text = [str stringByAppendingString:@" not connected"];
        [self setUIToNotConnectedState];
        connected = NO;
    }
}

/*- (void)session:(MCSession *)session didReceiveData:(NSData *)data fromPeer:(MCPeerID *)peerID
{
    NSString *str = [[NSString alloc] initWithData:data
                                          encoding:NSASCIIStringEncoding];
    NSLog(@"Received data: %@", str);
    NSString *tempStr = [NSString stringWithFormat:@"%@\nMsg from %@: %@",
                         self.textView.text,
                         peerID.displayName,
                         str];
    dispatch_async(dispatch_get_main_queue(), ^{
        self.textView.text = tempStr;
    });
}*/

- (void)browserViewControllerDidFinish:(MCBrowserViewController *)browserViewController {
    [browserViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)browserViewControllerWasCancelled:(MCBrowserViewController *)browserViewController {
    [browserViewController dismissViewControllerAnimated:YES completion:nil];
}

- (NSString *)participantID {
    return self.session.myPeerID.displayName;
}

- (void)setUIToNotConnectedState {
    self.disconnectButton.enabled = NO;
    self.browseButton.enabled = YES;
    self.statusLabel.text = @"Status: Disconnected";
}

- (void)setUIToConnectedState {
    self.disconnectButton.enabled = YES;
    self.browseButton.enabled = NO;
    self.statusLabel.text = @"Status: Connected";
}

#pragma Displaying the Motion Data Methods
@end
