#import <Cocoa/Cocoa.h>

@class PDPAgent, PDPPeer;

@interface MainWindowController : NSWindowController<NSSplitViewDelegate, NSOutlineViewDelegate, NSOutlineViewDataSource> {
    IBOutlet NSTextView *statusTextView;
    BOOL didSetup;
    PDPAgent *discoveryAgent;
    IBOutlet NSOutlineView *outlineView;
    IBOutlet NSTextField *nameField;
    IBOutlet NSTextField *base58KeyField;
    IBOutlet NSTextField *recentAddressField;
    IBOutlet NSButton *incomingTransfersCheckbox;
    PDPPeer *selectedPeer;
}

-(void)setup;
-(IBAction)sayHello:(id)sender;
- (IBAction)sendFile:(id)sender;
-(IBAction)takeAcceptsIncomingTranfersFromCheckbox:(NSButton*)checkbox;

@end
