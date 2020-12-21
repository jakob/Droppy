#import <Cocoa/Cocoa.h>

@class PDPAgent, PDPPeer;

@interface MainWindowController : NSWindowController<NSSplitViewDelegate, NSOutlineViewDelegate, NSOutlineViewDataSource> {
    IBOutlet NSTextView *statusTextView;
    BOOL didSetup;
    PDPAgent *discoveryAgent;
    IBOutlet NSOutlineView *outlineView;
    IBOutlet NSTextField *nameField;
    IBOutlet NSTextField *modelField;
    IBOutlet NSTextField *hexKeyField;
    IBOutlet NSTextField *base58KeyField;
    IBOutlet NSTextField *tcpPortField;
    PDPPeer *selectedPeer;
}

-(void)setup;
-(IBAction)sayHello:(id)sender;
- (IBAction)sendFile:(id)sender;

@end
