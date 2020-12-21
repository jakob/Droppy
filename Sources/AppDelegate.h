//
//  AppDelegate.h
//  Oktett
//
//  Created by Jakob on 17.04.20.
//  Copyright 2020 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface AppDelegate : NSObject <NSApplicationDelegate> {
@private
    NSWindow *window;
}

@property (assign) IBOutlet NSWindow *window;

@end
