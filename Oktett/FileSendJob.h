//
//  FileSendJob.h
//  Oktett
//
//  Created by Jakob on 28.11.20.
//  Copyright 2020 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class PDPPeer;

@interface FileSendJob : NSObject {
    PDPPeer *recipient;
    NSURL *url;
}

@property(copy) NSURL *url;
@property(retain) PDPPeer *recipient;
-(void)start;

@end
