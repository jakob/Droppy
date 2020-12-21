#import "AppDelegate.h"
#import "sodium.h"
#import "PDPAgent.h"

@implementation AppDelegate

@synthesize window;

-(void)applicationWillFinishLaunching:(NSNotification *)notification {
    if (sodium_init() < 0) {
        NSLog(@"Failed to init libsodium.");
        exit(1);
    }
    
    // Make sure we have a device key before any of the UI is loaded
    [PDPAgent currentDeviceKeyPair];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
}

@end
