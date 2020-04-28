//
//  OktettAppDelegate.m
//  Oktett
//
//  Created by Jakob on 17.04.20.
//  Copyright 2020 __MyCompanyName__. All rights reserved.
//

#import "OktettAppDelegate.h"
#import "sodium.h"

@implementation OktettAppDelegate

@synthesize window;

-(void)applicationWillFinishLaunching:(NSNotification *)notification {
    if (sodium_init() < 0) {
        NSLog(@"Failed to init libsodium.");
        exit(1);
    }
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
}

@end
