//
//  OktettWindowController.m
//  Oktett
//
//  Created by Jakob on 17.04.20.
//  Copyright 2020 __MyCompanyName__. All rights reserved.
//

#import "OktettWindowController.h"

#import "OCMessenger.h"

@interface OktettWindowController() <OCMessengerDelegate> {
    
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

    messenger = [[OCMessenger alloc] init];
    if (![messenger bindUDPPort:65012 delegate:self error:&error]) {
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            [self presentError:error modalForWindow:self.window delegate:nil didPresentSelector:NULL contextInfo:NULL];
        });
    }
}

-(void)messenger:(OCMessenger *)messenger didReceiveData:(NSData *)data from:(OCAddress *)addr {
    NSString *message = [NSString stringWithFormat:@"%@\nMessage from %@:%d\n%s\n\n", [NSDate date], addr.presentationAddress, addr.port, data.bytes];
    [statusTextView replaceCharactersInRange:NSMakeRange(0, 0) withString:message];
    [statusTextView didChangeText];
    [statusTextView setNeedsDisplay:YES];
}

-(IBAction)sayHello:(id)sender {   
    NSError *error = nil;
    NSData *message = [@"Hello!\n" dataUsingEncoding:NSUTF8StringEncoding];
    if (![messenger broadcastMessage:message port:65012 error:&error]) {
        [self presentError:error modalForWindow:self.window delegate:nil didPresentSelector:NULL contextInfo:NULL];
    }
}

- (void)dealloc
{
    [messenger release];
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
