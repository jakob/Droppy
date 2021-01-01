#import <Cocoa/Cocoa.h>

@class PDPAgent, PDPPeer;

@interface MainWindowController : NSWindowController<NSSplitViewDelegate, NSOutlineViewDelegate, NSOutlineViewDataSource> {
    BOOL didSetup;
    PDPAgent *discoveryAgent;
    IBOutlet NSOutlineView *outlineView;
    IBOutlet NSTextField *nameField;
    IBOutlet NSTextField *base58KeyField;
    IBOutlet NSView *fileDropView;
    IBOutlet NSButton *incomingTransfersCheckbox;
    IBOutlet NSButton *removePeerButton;
    PDPPeer *selectedPeer;
}

-(void)setup;
-(IBAction)sayHello:(id)sender;
- (IBAction)sendFile:(id)sender;
-(IBAction)takeAcceptsIncomingTranfersFromCheckbox:(NSButton*)checkbox;
-(IBAction)removePeer:(id)sender;

@end
