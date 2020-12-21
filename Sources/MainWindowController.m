//
//  OktettWindowController.m
//  Oktett
//
//  Created by Jakob on 17.04.20.
//  Copyright 2020 __MyCompanyName__. All rights reserved.
//

#import "MainWindowController.h"

#import "PDPAgent.h"
#import "NSData+EncodingHelpers.h"
#import "TCPConnection.h"
#import "FileReceiveJob.h"
#import "FileSendJob.h"

@interface MainWindowController() <PDPAgentDelegate> {
}
@end

@implementation MainWindowController

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


-(void)setup {
    if (didSetup) return;
    didSetup = YES;
    
    NSError *error = nil;
    discoveryAgent = [[PDPAgent alloc] init];
    discoveryAgent.delegate = self;
    if (![discoveryAgent setupWithError:&error]) {
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            [self presentError:error modalForWindow:self.window delegate:nil didPresentSelector:NULL contextInfo:NULL];
        });
    }
}

-(void)agent:(PDPAgent *)agent discoveredPeer:(PDPPeer *)peer {
	NSString *message = [NSString stringWithFormat:@"%@\nDiscovered peer: %@ (%@)\n\n", [NSDate date], peer.deviceName, peer.deviceModel];
    [statusTextView replaceCharactersInRange:NSMakeRange(0, 0) withString:message];
    [statusTextView didChangeText];
    [statusTextView setNeedsDisplay:YES];
    [outlineView reloadData];
}

-(void)agent:(PDPAgent *)agent updatedPeer:(PDPPeer *)peer {
    NSString *message = [NSString stringWithFormat:@"%@\nUpdated peer: %@\n\n", [NSDate date], peer.deviceName];
    [statusTextView replaceCharactersInRange:NSMakeRange(0, 0) withString:message];
    [statusTextView didChangeText];
    [statusTextView setNeedsDisplay:YES];
    [outlineView reloadData];
}

-(void)agent:(PDPAgent *)agent didAcceptConnection:(TCPConnection *)connection {
    FileReceiveJob *job = [[FileReceiveJob alloc] init];
    [job receiveFileInBackgroundFromConnection:connection];
    [job release];
}

-(IBAction)sayHello:(id)sender {   
    NSError *error = nil;
    if (![discoveryAgent scanWithError:&error]) {
        [self presentError:error modalForWindow:self.window delegate:nil didPresentSelector:NULL contextInfo:NULL];
    }
	[outlineView expandItem:@"Discovered Stuff"];
}

- (IBAction)sendFile:(id)sender {
    if (!selectedPeer) {
        NSBeep();
        return;
    }
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    [panel setCanChooseDirectories:YES];
    [panel setPrompt:@"Send"];
    [panel beginSheetModalForWindow:self.window completionHandler:^(NSInteger result) {
        if (result==NSFileHandlingPanelOKButton) {
            FileSendJob *job = [[FileSendJob alloc] init];
            job.url = [panel URL];
            job.recipient = selectedPeer;
            [job start];
            [job release];
        }
    }];
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
    CGFloat deltaX = [splitView frame].size.width - oldSize.width;
    int resizableViewIndex = 1;
    NSArray *subviews = [splitView subviews];
    for (int i=0; i<[subviews count]; i++) {
        if (i == resizableViewIndex) {
            NSView *sv = [subviews objectAtIndex:i];
            NSRect frame = [sv frame];
            frame.size.width += deltaX;
            [sv setFrame:frame];
        }
        else if (i>resizableViewIndex) {
            NSView *sv = [subviews objectAtIndex:i];
            NSRect frame = [sv frame];
            frame.origin.x += deltaX;
            [sv setFrame:frame];
        }
    }
    
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

-(BOOL)outlineView:(NSOutlineView*)outlineView isGroupItem:(id)item {
    if ([item isKindOfClass:[NSString class]]) {
        return YES;
    }
    return NO;
}

-(BOOL)outlineView:(NSOutlineView *)outlineView shouldEditTableColumn:(NSTableColumn *)tableColumn item:(id)item {
    return NO;
}

-(BOOL)outlineView:(NSOutlineView *)outlineView shouldSelectItem:(id)item {
    if ([item isKindOfClass:[NSString class]]) {
        return NO;
    }
    return YES;
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
        return [PDPPeer localPeer];
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
    if ([item isKindOfClass:[PDPPeer class]]) {
        return [item deviceName];
    }
    return nil;
}

-(void)setSelectedPeer:(PDPPeer*)peer {
    selectedPeer = peer;
    
    [nameField setStringValue:peer.deviceName ?: @""];
    [modelField setStringValue:peer.deviceModel ?: @""];
    [hexKeyField setStringValue:[[peer.publicKey data] fast_hex] ?: @""];
    [base64KeyField setStringValue:[[peer.publicKey data] sodium_base64] ?: @""];
    [tcpPortField setStringValue:[NSString stringWithFormat:@"%hu", peer.tcpListenPort]];
    
    [nameField setEditable:peer == [PDPPeer localPeer]];
    
    [nameField setEnabled:!!peer];
    [modelField setEnabled:!!peer];
    [hexKeyField setEnabled:!!peer];
    [base64KeyField setEnabled:!!peer];
    [tcpPortField setEnabled:!!peer];
}

-(void)outlineViewSelectionDidChange:(NSNotification *)notification {
    id item = [outlineView itemAtRow:[outlineView selectedRow]];
    if ([item isKindOfClass:[PDPPeer class]]) {
        [self setSelectedPeer: item];
    } else {
        [self setSelectedPeer: nil];
    }
}

@end
