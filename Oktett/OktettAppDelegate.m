//
//  OktettAppDelegate.m
//  Oktett
//
//  Created by Jakob on 17.04.20.
//  Copyright 2020 __MyCompanyName__. All rights reserved.
//

#import "OktettAppDelegate.h"

@implementation OktettAppDelegate

@synthesize window;

-(void)applicationWillFinishLaunching:(NSNotification *)notification {
    srandomdev();
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
}

@end
