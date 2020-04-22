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
    [outlineView expandItem:[outlineView itemAtRow:1]];
    [outlineView expandItem:[outlineView itemAtRow:0]];
}


-(NSString*)computerModel {
	static NSString *computerModel = nil;
	if (!computerModel) {
		io_service_t pexpdev;
		if ((pexpdev = IOServiceGetMatchingService(kIOMasterPortDefault, IOServiceMatching("IOPlatformExpertDevice"))))
		{
			CFDataRef data = IORegistryEntryCreateCFProperty(pexpdev, CFSTR("model"), kCFAllocatorDefault, 0);
			if (data) {
				computerModel = (id)CFStringCreateWithBytes(kCFAllocatorDefault, CFDataGetBytePtr(data), CFDataGetLength(data), kCFStringEncodingUTF8, false);
				CFRelease(data);
			}
		}
		if (!computerModel) computerModel = @"unknown";
	}
	return computerModel;
}

-(void)setup {
    if (didSetup) return;
    didSetup = YES;
    
    NSError *error = nil;
    discoveryAgent = [[OCPeerDiscoveryAgent alloc] init];
    discoveryAgent.delegate = self;
    OCPeer *identity = [[OCPeer alloc] init];
	
	/* Get computer name */
	CFStringRef computername = CSCopyMachineName();
	identity.shortName = (id)computername;
	CFRelease(computername);
	// Alternative method to get computer name
	// #import <SystemConfiguration/SystemConfiguration.h>
	// CFStringRef computername = SCDynamicStoreCopyComputerName(nil, nil);
	
	/* Get machine name*/
	identity.deviceType = [self computerModel];
	
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
	NSString *message = [NSString stringWithFormat:@"%@\nDiscovered peer: %@ (%@)\n\n", [NSDate date], peer.shortName, peer.deviceType];
    [statusTextView replaceCharactersInRange:NSMakeRange(0, 0) withString:message];
    [statusTextView didChangeText];
    [statusTextView setNeedsDisplay:YES];
    [outlineView reloadData];
}

-(void)agent:(OCPeerDiscoveryAgent *)agent updatedPeer:(OCPeer *)peer {
    NSString *message = [NSString stringWithFormat:@"%@\nUpdated peer: %@\n\n", [NSDate date], peer.shortName];
    [statusTextView replaceCharactersInRange:NSMakeRange(0, 0) withString:message];
    [statusTextView didChangeText];
    [statusTextView setNeedsDisplay:YES];
    [outlineView reloadData];
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

-(NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item {
    if (item == nil) {
        return 2;
    }
    if ([item isEqual:@"My Stuff"]) {
        return 1;
    }
    if ([item isEqual:@"Discovered Stuff"]) {
        return discoveryAgent.peers.count;
    }
    return 0;
}

-(BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item {
    if ([item isKindOfClass:[NSString class]]) {
        return YES;
    }
    return NO;
}

-(id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item {
    if (item == nil) {
        if (index==0) {
            return @"My Stuff";
        }
        if (index==1) {
            return @"Discovered Stuff";
        }
    }
    if ([item isEqual:@"My Stuff"]) {
        return discoveryAgent.identity;
    }
    if ([item isEqual:@"Discovered Stuff"]) {
        return [discoveryAgent.peers objectAtIndex:index];
    }
    return nil;
}

-(id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item {
    if ([item isKindOfClass:[NSString class]]) {
        return item;
    }
    if ([item isKindOfClass:[OCPeer class]]) {
        return [item shortName];
    }
    return nil;
}
@end
