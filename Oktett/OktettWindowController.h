//
//  OktettWindowController.h
//  Oktett
//
//  Created by Jakob on 17.04.20.
//  Copyright 2020 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface OktettWindowController : NSWindowController {
    IBOutlet NSTextView *statusTextView;
    BOOL didSetup;
    NSArray *interfaces;
}

-(void)setup;
-(IBAction)sayHello:(id)sender;

@end
