//
//  OktettWindowController.h
//  Oktett
//
//  Created by Jakob on 17.04.20.
//  Copyright 2020 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class OCMessenger;

@interface OktettWindowController : NSWindowController<NSSplitViewDelegate> {
    IBOutlet NSTextView *statusTextView;
    BOOL didSetup;
    OCMessenger *messenger;
}

-(void)setup;
-(IBAction)sayHello:(id)sender;

@end
