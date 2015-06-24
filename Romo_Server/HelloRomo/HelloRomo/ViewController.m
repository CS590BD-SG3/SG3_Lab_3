//
//  ViewController.m
//  HelloRomo
//

#import "ViewController.h"
#import "GCDAsyncSocket.h"

#define WELCOME_MSG  0
#define ECHO_MSG     1
#define WARNING_MSG  2

#define NO_TIMEOUT -1.0
#define READ_TIMEOUT 15.0
#define READ_TIMEOUT_EXTENSION 10.0

#define FORWARD @"FORWARD"
#define BACK @"BACK"
#define LEFT @"LEFT"
#define RIGHT @"RIGHT"
#define STOP @"STOP"
#define LAUGH @"LAUGH"

#define FORMAT(format, ...) [NSString stringWithFormat:(format), ##__VA_ARGS__]

@implementation ViewController {
    dispatch_queue_t _socketQueue;
    GCDAsyncSocket *_listenSocket;
    NSMutableArray *_connectedSockets;
    BOOL isRunning;
    IBOutlet id logView;
}

#pragma mark - View Management
- (void)viewDidLoad
{
    NSLog(@"viewDidLoad");
    [super viewDidLoad];
    
    // To receive messages when Robots connect & disconnect, set RMCore's delegate to self
    [RMCore setDelegate:self];
    
    // Grab a shared instance of the Romo character
    self.Romo = [RMCharacter Romo];
    [RMCore setDelegate:self];
    
    [self addGestureRecognizers];
    
    NSString *ipAddress = [self getIPAddress];
    NSLog(@"The iOS Device IP Address is: ");
    NSLog(@"%@", ipAddress);
    
    _socketQueue = dispatch_queue_create("socketQueue", NULL);
    _listenSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:_socketQueue];
    _connectedSockets = [[NSMutableArray alloc] initWithCapacity:1];
    isRunning = NO;
    
    NSError *error = nil;
    if (![_listenSocket acceptOnPort:1234 error:&error])
    {
        NSLog(@"Error accepting listen socket on port: %@", error);
    }
    
    isRunning = YES;
    
    self.Romo.emotion = RMCharacterEmotionCurious;
    self.Romo.expression = RMCharacterExpressionSneeze;
}

- (void)socket:(GCDAsyncSocket *)sender didAcceptNewSocket:(GCDAsyncSocket *)newSocket
{
    @synchronized(_connectedSockets)
    {
        [_connectedSockets addObject:newSocket];
    }
    
    NSString *host = [newSocket connectedHost];
    UInt16 port = [newSocket connectedPort];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        @autoreleasepool {
            [self logInfo:FORMAT(@"Accepted client %@:%hu", host, port)];
        }
    });
    
    /*
    NSString *welcomeMsg = @"Welcome to the Romo Server\r\n";
    NSData *welcomeData = [welcomeMsg dataUsingEncoding:NSUTF8StringEncoding];
    
    [newSocket writeData:welcomeData withTimeout:-1 tag:WELCOME_MSG];
    */
    [newSocket readDataWithTimeout:NO_TIMEOUT tag:0];
}

- (void)socket:(GCDAsyncSocket *)socket didWriteDataWithTag:(long)tag
{
}

- (void)socket:(GCDAsyncSocket *)socket didReadData:(NSData *)data withTag:(long)tag
{
    dispatch_async(dispatch_get_main_queue(), ^{
        @autoreleasepool {
            NSData *strData = [data subdataWithRange:NSMakeRange(0, [data length])];
            NSString *msg = [[NSString alloc] initWithData:strData encoding:NSUTF8StringEncoding];
            if (msg)
            {
                [self logMessage:msg];
                [self perform:msg:socket];
            }
            else
            {
                [self logError:@"Error converting the data received into UTF-8"];
            }
        }
    });
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)socket withError:(NSError *)err
{
    if (socket != _listenSocket)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            @autoreleasepool {
                [self logInfo:FORMAT(@"Client disconnected")];
            }
        });
    }
    
    @synchronized(_connectedSockets)
    {
        [_connectedSockets removeObject:socket];
    }
    
    isRunning = NO;
}

- (void)perform:(NSString *)msg :(GCDAsyncSocket*) socket
{
    NSLog(@"Calling perform with msg: %@", msg);
    if ([msg caseInsensitiveCompare:FORWARD] == NSOrderedSame)
    {
        // Romo will drive Forward
        self.Romo.emotion = RMCharacterEmotionExcited;
        self.Romo.expression = RMCharacterExpressionExcited;
        [self.Romo3 driveForwardWithSpeed:1.0];
    }
    else if([msg caseInsensitiveCompare:BACK] == NSOrderedSame)
    {
        // Romo will drive Backwards
        self.Romo.emotion = RMCharacterEmotionScared;
        self.Romo.expression = RMCharacterExpressionScared;
        [self.Romo3 driveBackwardWithSpeed:1.0];
    }
    else if([msg caseInsensitiveCompare:LEFT] == NSOrderedSame)
    {
        // Romo will drive Left
        self.Romo.emotion = RMCharacterEmotionDelighted;
        self.Romo.expression = RMCharacterExpressionDizzy;
        [self.Romo3 driveWithRadius:-1.0 speed:1.0];
    }
    else if ([msg caseInsensitiveCompare:RIGHT] == NSOrderedSame)
    {
        // Romo will drive Right
        self.Romo.emotion = RMCharacterEmotionDelighted;
        self.Romo.expression = RMCharacterExpressionDizzy;
        [self.Romo3 driveWithRadius:1.0 speed:1.0];
    }
    else if ([msg caseInsensitiveCompare:STOP] == NSOrderedSame)
    {
        // Romo will Stop
        self.Romo.emotion = RMCharacterEmotionSleepy;
        self.Romo.expression = RMCharacterExpressionExhausted;
        [self.Romo3 stopAllMotion];
    }
    else if ([msg caseInsensitiveCompare:LAUGH] == NSOrderedSame)
    {
        self.Romo.emotion = RMCharacterEmotionHappy;
        // Romo will Laugh
        self.Romo.expression = RMCharacterExpressionLaugh;
    }
    else
    {
        self.Romo.emotion = RMCharacterEmotionBewildered;
        self.Romo.expression = RMCharacterExpressionFart;
    }
    
    [socket readDataWithTimeout:NO_TIMEOUT tag:0];
}

- (void)viewWillAppear:(BOOL)animated
{
    // Add Romo's face to self.view whenever the view will appear
    [self.Romo addToSuperview:self.view];
}

#pragma mark - RMCoreDelegate Methods
- (void)robotDidConnect:(RMCoreRobot *)robot
{
    // Currently the only kind of robot is Romo3, so this is just future-proofing
    if ([robot isKindOfClass:[RMCoreRobotRomo3 class]]) {
        self.Romo3 = (RMCoreRobotRomo3 *)robot;
        
        // Change Romo's LED to be solid at 80% power
        [self.Romo3.LEDs setSolidWithBrightness:0.8];
        
        // When we plug Romo in, he get's excited!
        self.Romo.expression = RMCharacterExpressionExcited;
    }
}

- (void)robotDidDisconnect:(RMCoreRobot *)robot
{
    if (robot == self.Romo3) {
        self.Romo3 = nil;
        
        // When we plug Romo in, he get's excited!
        self.Romo.expression = RMCharacterExpressionSad;
    }
}

#pragma mark - Gesture recognizers

- (void)addGestureRecognizers
{
    // Let's start by adding some gesture recognizers with which to interact with Romo
    UISwipeGestureRecognizer *swipeLeft = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipedLeft:)];
    swipeLeft.direction = UISwipeGestureRecognizerDirectionLeft;
    [self.view addGestureRecognizer:swipeLeft];
    
    UISwipeGestureRecognizer *swipeRight = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipedRight:)];
    swipeRight.direction = UISwipeGestureRecognizerDirectionRight;
    [self.view addGestureRecognizer:swipeRight];
    
    UISwipeGestureRecognizer *swipeUp = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipedUp:)];
    swipeUp.direction = UISwipeGestureRecognizerDirectionUp;
    [self.view addGestureRecognizer:swipeUp];
    
    UITapGestureRecognizer *tapReceived = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tappedScreen:)];
    [self.view addGestureRecognizer:tapReceived];
}


- (void)swipedLeft:(UIGestureRecognizer *)sender
{
    // When the user swipes left, Romo will turn in a circle to his left
    [self.Romo3 driveWithRadius:-1.0 speed:1.0];
}

- (void)swipedRight:(UIGestureRecognizer *)sender
{
    // When the user swipes right, Romo will turn in a circle to his right
    [self.Romo3 driveWithRadius:1.0 speed:1.0];
}

// Swipe up to change Romo's emotion to some random emotion
- (void)swipedUp:(UIGestureRecognizer *)sender
{
    int numberOfEmotions = 7;
    
    // Choose a random emotion from 1 to numberOfEmotions
    // That's different from the current emotion
    RMCharacterEmotion randomEmotion = 1 + (arc4random() % numberOfEmotions);
    
    self.Romo.emotion = randomEmotion;
}

// Simply tap the screen to stop Romo
- (void)tappedScreen:(UIGestureRecognizer *)sender
{
    [self.Romo3 stopDriving];
}

- (NSString *)getIPAddress {
    
    NSString *address = @"error";
    struct ifaddrs *interfaces = NULL;
    struct ifaddrs *temp_addr = NULL;
    int success = 0;
    // retrieve the current interfaces - returns 0 on success
    success = getifaddrs(&interfaces);
    if (success == 0) {
        // Loop through linked list of interfaces
        temp_addr = interfaces;
        while(temp_addr != NULL) {
            if(temp_addr->ifa_addr->sa_family == AF_INET) {
                // Check if interface is en0 which is the wifi connection on the iPhone
                if([[NSString stringWithUTF8String:temp_addr->ifa_name] isEqualToString:@"en0"]) {
                    // Get NSString from C String
                    address = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)];
                    
                }
                
            }
            
            temp_addr = temp_addr->ifa_next;
        }
    }
    // Free memory
    freeifaddrs(interfaces);
    return address;
}
        
- (void)logError:(NSString *)msg
{
    NSString *paragraph = [NSString stringWithFormat:@"%@\n", msg];
            
    NSMutableDictionary *attributes = [NSMutableDictionary dictionaryWithCapacity:1];
    [attributes setObject:[UIColor redColor] forKey:NSForegroundColorAttributeName];
            
    NSAttributedString *as = [[NSAttributedString alloc] initWithString:paragraph attributes:attributes];
    NSString *str = [as string];
    NSLog(@"%@", str);
}
        
- (void)logInfo:(NSString *)msg
{
    NSString *paragraph = [NSString stringWithFormat:@"%@\n", msg];
            
    NSMutableDictionary *attributes = [NSMutableDictionary dictionaryWithCapacity:1];
    [attributes setObject:[UIColor purpleColor] forKey:NSForegroundColorAttributeName];
            
    NSAttributedString *as = [[NSAttributedString alloc] initWithString:paragraph attributes:attributes];
            
    NSString *str = [as string];
    NSLog(@"%@", str);
}
        
- (void)logMessage:(NSString *)msg
{
    NSString *paragraph = [NSString stringWithFormat:@"%@\n", msg];
            
    NSMutableDictionary *attributes = [NSMutableDictionary dictionaryWithCapacity:1];
    [attributes setObject:[UIColor blackColor] forKey:NSForegroundColorAttributeName];
            
    NSAttributedString *as = [[NSAttributedString alloc] initWithString:paragraph attributes:attributes];
            
    NSString *str = [as string];
    NSLog(@"%@", str);
}
        
@end
