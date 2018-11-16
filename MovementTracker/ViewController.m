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
    int _abSwitch;
}
@property (strong, nonatomic) CMMotionManager *motman;
@property (strong, nonatomic) NSTimer *timer;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *browseButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *disconnectButton;
@property (weak, nonatomic) IBOutlet UIView *xPos;
@property (weak, nonatomic) IBOutlet UIView *yPos;
@property (weak, nonatomic) IBOutlet UIView *zPos;
@property (weak, nonatomic) IBOutlet UIView *rollPos;
@property (weak, nonatomic) IBOutlet UIView *pitchPos;
@property (weak, nonatomic) IBOutlet UIView *yawPos;
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;
@property (weak, nonatomic) IBOutlet UISegmentedControl *ABSwitcher;
@property (strong, nonatomic) MCSession *session;
@property (strong, nonatomic) MCAdvertiserAssistant *assistant;
@property (strong, nonatomic) MCBrowserViewController *browserVC;

- (IBAction)browseButtonTapped:(UIBarButtonItem *)sender;
- (IBAction)disconnectButtonTapped:(UIBarButtonItem *)sender;
@end

@implementation ViewController

/*
 *Checks to see which device is being used, A or B.
 *Sets the State to Not Connected.
 *Prepares the session and starts advertising for a peer.
 */
- (void)viewDidLoad {
    [super viewDidLoad];
    if (_abSwitch == 0) {
        [self startMonitoringMotion];
    } else if (_abSwitch == 1) {
        [self stopMonitoringMotion];
    }
    connected = NO;
    [self setUIToNotConnectedState];
    originalViewFrame = self.view.frame;
    [self prepareSession];
    [self startAdvertising];
}

//Checks what the connected state is upon view appearing.
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (connected)
        [self setUIToConnectedState];
    else
        [self setUIToNotConnectedState];
}

//Changes te value of the filter based on the selection of the segment.
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

//Changes wheter the app responds as device A or device B based on which segment is selected.
- (IBAction)abSegmentDidChange:(UISegmentedControl *)sender {
    switch (sender.selectedSegmentIndex) {
        case 0:
            _abSwitch = 0;
            [self startMonitoringMotion];
            break;
        case 1:
            _abSwitch = 1;
            [self stopMonitoringMotion];
            break;
    }
}

#pragma Motion Monitoring Methods
/*
 *When called, creates a CMMotionManager and starts monitoring motion.
 */
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
    if (_abSwitch == 0) {
        [self sendData];
    }
}

//Halts the motion monitoring.
- (void) stopMonitoringMotion {
    [self.motman stopAccelerometerUpdates];
    [self.motman stopGyroUpdates];
}

/*
 *First checks if the device is A or B, if device is A, it updates the properties to reflect the most recent values of motion.
 *Then for each motion, x, y, z, pitch, roll and yaw, as well as the filters, it calculates the size and signum of the motion and generates a bar of relative size.
 *The bar goes low for negative values and high for positive vales and is also recoloured to red (for negative) and green (for positive)
 *It also contains a call to 'sendData' at the very end.
 */
- (void)pollMotion:(NSTimer *)timer {
    if (_abSwitch == 0) {
        CMAcceleration acc = self.motman.accelerometerData.acceleration;
        _accX = acc.x;
        _accY = acc.y;
        _accZ = acc.z;
        CMRotationRate rot = self.motman.gyroData.rotationRate;
        _rotPitch = rot.x;
        _rotRoll = rot.y;
        _rotYaw = rot.z;
        [self addAcceleration:acc];
    }
    NSArray* rots = [NSArray arrayWithObjects:[NSNumber numberWithFloat:_rotPitch],[NSNumber numberWithFloat:_rotRoll],[NSNumber numberWithFloat:_rotYaw], nil];
    NSArray* rotViews = [NSArray arrayWithObjects:self.pitchPos, self.rollPos, self.yawPos, nil];
    NSArray* nf = [NSArray arrayWithObjects:[NSNumber numberWithFloat:_accX],[NSNumber numberWithFloat:_accY],[NSNumber numberWithFloat:_accZ], nil];
    NSArray* lp = [NSArray arrayWithObjects:[NSNumber numberWithFloat:_avgX],[NSNumber numberWithFloat:_avgY],[NSNumber numberWithFloat:_avgZ], nil];
    NSArray* hp = [NSArray arrayWithObjects:[NSNumber numberWithFloat:_varX],[NSNumber numberWithFloat:_varY],[NSNumber numberWithFloat:_varZ], nil];
    NSArray* accViews = [NSArray arrayWithObjects:self.xPos, self.yPos, self.zPos, nil];
    float scale = 100;
    float rotScale = 50;
    UIView *v = nil;
    for (int i=0 ; i<=2 ; i++) {
        v = rotViews[i];
        if ([rots[i] floatValue] >= 0) {
            dispatch_async(dispatch_get_main_queue(), ^{
                v.backgroundColor = [UIColor redColor];
                CGRect frame = v.frame;
                frame.origin.y = 751 + ([rots[i] floatValue]*rotScale);
                frame.size.height = -[rots[i] floatValue] * rotScale;
                v.frame = frame;
            });
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                v.backgroundColor = [UIColor greenColor];
                CGRect frame = v.frame;
                frame.size.height = [rots[i] floatValue] * rotScale;
                frame.origin.y = 751;
                v.frame = frame;
            });
        }
    }
    switch (_filterMode) {
        case FILTERNO:
            for (int i = 0 ; i <=2 ; i++) {
                v = accViews[i];
                if ([nf[i] floatValue] >= 0) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        v.backgroundColor = [UIColor redColor];
                        CGRect frame = v.frame;
                        frame.origin.y = 281 + ([nf[i] floatValue]*scale);
                        frame.size.height = -[nf[i] floatValue] * scale;
                        v.frame = frame;
                    });
                } else {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        v.backgroundColor = [UIColor greenColor];
                        CGRect frame = v.frame;
                        frame.size.height = [nf[i] floatValue] * scale;
                        frame.origin.y = 281;
                        v.frame = frame;
                    });
                }
            }
            break;
        case FILTERLOW:
            for (int i = 0 ; i <= 2 ; i++) {
                v = accViews[i];
                if ([lp[i] floatValue] >= 0) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        v.backgroundColor = [UIColor redColor];
                        CGRect frame = v.frame;
                        frame.origin.y = 281 + ([lp[i] floatValue]);
                        frame.size.height = -[lp[i] floatValue] * scale;
                        v.frame = frame;
                    });
                } else {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        v.backgroundColor = [UIColor greenColor];
                        CGRect frame = v.frame;
                        frame.size.height = [lp[i] floatValue] * scale;
                        frame.origin.y = 281;
                        v.frame = frame;
                    });
                }
            }
            break;
        case FILTERHIGH:
            for (int i = 0 ; i <= 2 ; i++) {
                v = accViews[i];
                if ([hp[i] floatValue] >= 0) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        v.backgroundColor = [UIColor redColor];
                        CGRect frame = v.frame;
                        frame.origin.y = 281 + ([hp[i] floatValue]);
                        frame.size.height = -[hp[i] floatValue] * scale;
                        v.frame = frame;
                    });
                } else {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        v.backgroundColor = [UIColor greenColor];
                        CGRect frame = v.frame;
                        frame.size.height = [hp[i] floatValue] * scale;
                        frame.origin.y = 281;
                        v.frame = frame;
                    });
                }
            }
            break;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.view setNeedsDisplay];
    });
    if (_abSwitch == 0) {
        [self sendData];
    }
}

//This method just calculates the different filters.
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
//This method generates the session.
- (void) prepareSession {
    MCPeerID *myPeerID = [[MCPeerID alloc] initWithDisplayName:[[UIDevice currentDevice] name]];
    MCSession *temp = [[MCSession alloc] initWithPeer:myPeerID securityIdentity:nil encryptionPreference: MCEncryptionNone];
    self.session = temp;
    self.session.delegate = self;
}

//This method begins the proces of advertising for a connection.
- (void) startAdvertising {
    self.assistant = [[MCAdvertiserAssistant alloc] initWithServiceType:SERVICE_TYPE discoveryInfo:nil session:self.session];
    [self.assistant start];
}

//This method, called when the browse button is clicked, creates the MCBrowserViewController and presents the view.
- (IBAction)browseButtonTapped:(UIBarButtonItem *)sender {
    self.browserVC = [[MCBrowserViewController alloc] initWithServiceType:SERVICE_TYPE session:self.session];
    self.browserVC.delegate = self;
    [self presentViewController:self.browserVC animated:YES completion:nil];
}

//This method generates an array of the motion data, then creates an NSData object and sends it to the connected peer.
- (void)sendData {
    NSArray *peerIDs = self.session.connectedPeers;
    NSArray *senders = [NSArray arrayWithObjects:[[NSNumber numberWithFloat:_accX] stringValue],
                                                [[NSNumber numberWithFloat:_accY] stringValue],
                                                [[NSNumber numberWithFloat:_accZ] stringValue],
                                                [[NSNumber numberWithFloat:_avgX] stringValue],
                                                [[NSNumber numberWithFloat:_avgY] stringValue],
                                                [[NSNumber numberWithFloat:_avgZ] stringValue],
                                                [[NSNumber numberWithFloat:_varX] stringValue],
                                                [[NSNumber numberWithFloat:_varY] stringValue],
                                                [[NSNumber numberWithFloat:_varZ] stringValue],
                                                [[NSNumber numberWithFloat:_rotPitch] stringValue],
                                                [[NSNumber numberWithFloat:_rotRoll] stringValue],
                                                [[NSNumber numberWithFloat:_rotYaw] stringValue],nil];
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:senders];
    [self.session sendData:data toPeers:peerIDs withMode:MCSessionSendDataUnreliable error:nil];
}

//Responds to the disconnect button being pressed and sets the state to disconnected
- (IBAction)disconnectButtonTapped:(UIBarButtonItem *)sender {
    [self setUIToNotConnectedState];
    connected = NO;
    [self.session disconnect];
    self.statusLabel.text = @"Status: Not Connected";
}

//Monitors whether the state changes and sets the state depending on te change.
- (void)session:(MCSession *)session peer:(MCPeerID *)peerID didChangeState:(MCSessionState)state {
    //NSString *str = [NSString stringWithFormat:@"Status: %@", peerID.displayName];
    if (state == MCSessionStateConnected) {
        [self setUIToConnectedState];
        connected = YES;
    } else if (state == MCSessionStateNotConnected) {
        [self setUIToNotConnectedState];
        connected = NO;
    }
}

//This method recieves the data sent by the peer and updates the property methods. It then calls pollMotion to display the data.
- (void)session:(MCSession *)session didReceiveData:(NSData *)data fromPeer:(MCPeerID *)peerID {
    NSArray* recData = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    _accX = [recData[0] floatValue];
    _accY = [recData[1] floatValue];
    _accZ = [recData[2] floatValue];
    _avgX = [recData[3] floatValue];
    _avgY = [recData[4] floatValue];
    _avgZ = [recData[5] floatValue];
    _varX = [recData[6] floatValue];
    _varY = [recData[7] floatValue];
    _varZ = [recData[8] floatValue];
    _rotPitch = [recData[9] floatValue];
    _rotRoll = [recData[10] floatValue];
    _rotYaw = [recData[11] floatValue];
    [self pollMotion:self.timer];
}

//Dismisses the BrowserViewController upon done being pressed
- (void)browserViewControllerDidFinish:(MCBrowserViewController *)browserViewController {
    [browserViewController dismissViewControllerAnimated:YES completion:nil];
}

//Dismisses the BrowerViewController upon cancel being pressed
- (void)browserViewControllerWasCancelled:(MCBrowserViewController *)browserViewController {
    [browserViewController dismissViewControllerAnimated:YES completion:nil];
}

//Disables Disconnect button, enables browse button, Changes status label.
- (void)setUIToNotConnectedState {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.disconnectButton.enabled = NO;
        self.browseButton.enabled = YES;
        self.statusLabel.text = @"Status: Not Connected";
    });
}

//Disables browse button, enables disconnect button, changes staus label.
- (void)setUIToConnectedState {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.disconnectButton.enabled = YES;
        self.browseButton.enabled = NO;
        self.statusLabel.text = @"Status: Connected";
    });
}
@end
