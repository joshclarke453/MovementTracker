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
@property (weak, nonatomic) IBOutlet UIView *xPos;
@property (weak, nonatomic) IBOutlet UIView *yPos;
@property (weak, nonatomic) IBOutlet UIView *zPos;
@property (weak, nonatomic) IBOutlet UIView *rollPos;
@property (weak, nonatomic) IBOutlet UIView *pitchPos;
@property (weak, nonatomic) IBOutlet UIView *yawPos;
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
    [self setUIToNotConnectedState];
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
    NSArray* rots = [NSArray arrayWithObjects:[NSNumber numberWithFloat:rot.x],[NSNumber numberWithFloat:rot.y],[NSNumber numberWithFloat:rot.z], nil];
    NSArray* rotViews = [NSArray arrayWithObjects:self.pitchPos, self.rollPos, self.yawPos, nil];
    [self addAcceleration:acc];
    NSArray* nf = [NSArray arrayWithObjects:[NSNumber numberWithFloat:acc.x],[NSNumber numberWithFloat:acc.y],[NSNumber numberWithFloat:acc.z], nil];
    NSArray* lp = [NSArray arrayWithObjects:[NSNumber numberWithFloat:_avgX],[NSNumber numberWithFloat:_avgY],[NSNumber numberWithFloat:_avgZ], nil];
    NSArray* hp = [NSArray arrayWithObjects:[NSNumber numberWithFloat:_varX],[NSNumber numberWithFloat:_varY],[NSNumber numberWithFloat:_varZ], nil];
    NSArray* accViews = [NSArray arrayWithObjects:self.xPos, self.yPos, self.zPos, nil];
    float scale = 100;
    float rotScale = 50;
    UIView *v = nil;
    for (int i=0 ; i<=2 ; i++) {
        v = rotViews[i];
        if ([rots[i] floatValue] >= 0) {
            v.backgroundColor = [UIColor redColor];
            CGRect frame = v.frame;
            frame.origin.y = 751 + ([rots[i] floatValue]*rotScale);
            frame.size.height = -[rots[i] floatValue] * rotScale;
            v.frame = frame;
        } else {
            v.backgroundColor = [UIColor greenColor];
            CGRect frame = v.frame;
            frame.size.height = [rots[i] floatValue] * rotScale;
            frame.origin.y = 751;
            v.frame = frame;
        }
    }
    switch (_filterMode) {
        case FILTERNO:
            for (int i = 0 ; i <=2 ; i++) {
                v = accViews[i];
                if ([nf[i] floatValue] >= 0) {
                    v.backgroundColor = [UIColor redColor];
                    CGRect frame = v.frame;
                    frame.origin.y = 281 + ([nf[i] floatValue]*scale);
                    frame.size.height = -[nf[i] floatValue] * scale;
                    v.frame = frame;
                } else {
                    v.backgroundColor = [UIColor greenColor];
                    CGRect frame = v.frame;
                    frame.size.height = [nf[i] floatValue] * scale;
                    frame.origin.y = 281;
                    v.frame = frame;
                }
            }
        case FILTERLOW:
            for (int i = 0 ; i <= 2 ; i++) {
                v = accViews[i];
                if ([lp[i] floatValue] >= 0) {
                    v.backgroundColor = [UIColor redColor];
                    CGRect frame = v.frame;
                    frame.origin.y = 281 + ([lp[i] floatValue]);
                    frame.size.height = -[lp[i] floatValue] * scale;
                    v.frame = frame;
                } else {
                    v.backgroundColor = [UIColor greenColor];
                    CGRect frame = v.frame;
                    frame.size.height = [lp[i] floatValue] * scale;
                    frame.origin.y = 281;
                    v.frame = frame;
                }
            }
            break;
        case FILTERHIGH:
            for (int i = 0 ; i <= 2 ; i++) {
                v = accViews[i];
                if ([hp[i] floatValue] >= 0) {
                    v.backgroundColor = [UIColor redColor];
                    CGRect frame = v.frame;
                    frame.origin.y = 281 + ([hp[i] floatValue]);
                    frame.size.height = -[hp[i] floatValue] * scale;
                    v.frame = frame;
                } else {
                    v.backgroundColor = [UIColor greenColor];
                    CGRect frame = v.frame;
                    frame.size.height = [hp[i] floatValue] * scale;
                    frame.origin.y = 281;
                    v.frame = frame;
                }
            }
            break;
    }
    [self.view setNeedsDisplay];
}

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
    MCSession *temp = [[MCSession alloc] initWithPeer:myPeerID securityIdentity:nil encryptionPreference: MCEncryptionNone];
    self.session = temp;
    self.session.delegate = self;
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
    //NSString *str = [NSString stringWithFormat:@"Status: %@", peerID.displayName];
    if (state == MCSessionStateConnected) {
        //[self.statusLabel setText:@"Status: Connected"];
        [self setUIToConnectedState];
        connected = YES;
    } else if (state == MCSessionStateNotConnected) {
        //[self.statusLabel setText:@"Status: Disconnected"];
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
}

- (void)setUIToConnectedState {
    self.disconnectButton.enabled = YES;
    self.browseButton.enabled = NO;
}
@end
