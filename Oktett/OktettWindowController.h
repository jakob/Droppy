//
//  OktettWindowController.h
//  Oktett
//
//  Created by Jakob on 17.04.20.
//  Copyright 2020 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class PDPAgent;

@interface OktettWindowController : NSWindowController<NSSplitViewDelegate, NSOutlineViewDelegate, NSOutlineViewDataSource> {
    IBOutlet NSTextView *statusTextView;
    BOOL didSetup;
    PDPAgent *discoveryAgent;
    IBOutlet NSOutlineView *outlineView;
}

-(void)setup;
-(IBAction)sayHello:(id)sender;

@end
