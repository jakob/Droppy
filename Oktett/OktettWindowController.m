//
//  OktettWindowController.m
//  Oktett
//
//  Created by Jakob on 17.04.20.
//  Copyright 2020 __MyCompanyName__. All rights reserved.
//

#import "OktettWindowController.h"

#import "OCPeerDiscoveryAgent.h"

@interface OktettWindowController() <OCPeerDiscoveryAgentDelegate> {
    
}
@end

@implementation OktettWindowController

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}


-(void)awakeFromNib {
    [self setup];
}


-(void)setup {
    if (didSetup) return;
    didSetup = YES;
    
    NSError *error = nil;
    discoveryAgent = [[OCPeerDiscoveryAgent alloc] init];
    discoveryAgent.delegate = self;
    OCPeer *identity = [[OCPeer alloc] init];
    identity.shortName = [NSString stringWithFormat:@"%@'s Computer", NSUserName()];
    CFUUIDRef uuid = CFUUIDCreate(kCFAllocatorDefault);
    identity.peerUUID = uuid;
    CFRelease(uuid);
    discoveryAgent.identity = identity;
    if (![discoveryAgent setupWithError:&error]) {
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            [self presentError:error modalForWindow:self.window delegate:nil didPresentSelector:NULL contextInfo:NULL];
        });
    }
}

-(void)agent:(OCPeerDiscoveryAgent *)agent discoveredPeer:(OCPeer *)peer {
    NSString *message = [NSString stringWithFormat:@"%@\nDiscovered peer: %@\n\n", [NSDate date], peer.shortName];
    [statusTextView replaceCharactersInRange:NSMakeRange(0, 0) withString:message];
    [statusTextView didChangeText];
    [statusTextView setNeedsDisplay:YES];
}

-(void)agent:(OCPeerDiscoveryAgent *)agent updatedPeer:(OCPeer *)peer {
    NSString *message = [NSString stringWithFormat:@"%@\nUpdated peer: %@\n\n", [NSDate date], peer.shortName];
    [statusTextView replaceCharactersInRange:NSMakeRange(0, 0) withString:message];
    [statusTextView didChangeText];
    [statusTextView setNeedsDisplay:YES];
}

-(IBAction)sayHello:(id)sender {   
    NSError *error = nil;
    if (![discoveryAgent scanWithError:&error]) {
        [self presentError:error modalForWindow:self.window delegate:nil didPresentSelector:NULL contextInfo:NULL];
    }
}

- (void)dealloc
{
    [discoveryAgent release];
    [super dealloc];
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

-(void)splitView:(NSSplitView *)splitView resizeSubviewsWithOldSize:(NSSize)oldSize {
    // first, resize the last view to fit full width
    NSArray *subviews = [splitView subviews];
    NSView *lastView = [subviews objectAtIndex:[subviews count]-1];
    NSRect lastViewFrame = [lastView frame];
    CGFloat deltaX = NSMaxX([splitView bounds]) - NSMaxX(lastViewFrame);
    lastViewFrame.size.width += deltaX;
    [lastView setFrame:lastViewFrame];
    
    // now call adjustsubviews to set vertical positions
    [splitView adjustSubviews];
}

@end
