//
//  OktettWindowController.h
//  Oktett
//
//  Created by Jakob on 17.04.20.
//  Copyright 2020 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class PDPAgent, PDPPeer;

@interface OktettWindowController : NSWindowController<NSSplitViewDelegate, NSOutlineViewDelegate, NSOutlineViewDataSource> {
    IBOutlet NSTextView *statusTextView;
    BOOL didSetup;
    PDPAgent *discoveryAgent;
    IBOutlet NSOutlineView *outlineView;
    IBOutlet NSTextField *nameField;
    IBOutlet NSTextField *modelField;
    IBOutlet NSTextField *hexKeyField;
    IBOutlet NSTextField *base64KeyField;
    IBOutlet NSTextField *tcpPortField;
    PDPPeer *selectedPeer;
}

-(void)setup;
-(IBAction)sayHello:(id)sender;
- (IBAction)sendFile:(id)sender;

@end
