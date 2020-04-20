//
//  OktettWindowController.m
//  Oktett
//
//  Created by Jakob on 17.04.20.
//  Copyright 2020 __MyCompanyName__. All rights reserved.
//

#import "OktettWindowController.h"

#import "OCInterface.h"

@interface OktettWindowController() <OCInterfaceDelegate> {
    
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

    interfaces = [[OCInterface broadcastInterfacesWithError:&error] retain];
    if (!interfaces) {
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            [self presentError:error modalForWindow:self.window delegate:nil didPresentSelector:NULL contextInfo:NULL];
        });
    }
    for (OCInterface *interface in interfaces) {
        if (![interface bindUDPPort:65012 delegate:self error:&error]) {
            dispatch_async(dispatch_get_main_queue(), ^(void) {
                [self presentError:error modalForWindow:self.window delegate:nil didPresentSelector:NULL contextInfo:NULL];
            });
        }
    }
}

-(void)interface:(OCInterface *)interface didReceiveData:(NSData *)data fromAddress:(NSData *)addr {
    NSString *message = [NSString stringWithFormat:@"%@\nMessage\n%s\n\n", [NSDate date], data.bytes];
    [statusTextView replaceCharactersInRange:NSMakeRange(0, 0) withString:message];
    [statusTextView didChangeText];
    [statusTextView setNeedsDisplay:YES];
}

-(IBAction)sayHello:(id)sender {   
    NSError *error = nil;
    NSData *message = [@"Hello!\n" dataUsingEncoding:NSUTF8StringEncoding];
    for (OCInterface *interface in interfaces) {
        if (![interface broadcastMessage:message port:65012 error:&error]) {
            [self presentError:error modalForWindow:self.window delegate:nil didPresentSelector:NULL contextInfo:NULL];
            return;
        }
    }
}

- (void)dealloc
{
    [interfaces release];
    [super dealloc];
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

@end
