//
//  OCMessenger.h
//  Oktett
//
//  Created by Jakob on 21.04.20.
//  Copyright 2020 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "OCAddress.h"
@class OCMessenger;

@protocol OCMessengerDelegate <NSObject>

-(void)messenger:(OCMessenger*)messenger
  didReceiveData:(NSData*)data
            from:(OCAddress*)addr;

@end

@interface OCMessenger : NSObject {
    int udp_sock;
    int udp_port;
    dispatch_source_t udp_sock_src;
}

-(BOOL)bindUDPPort:(uint16_t)port delegate:(id<OCMessengerDelegate>)delegate error:(NSError**)error;

-(BOOL)broadcastMessage:(NSData*)message port:(uint16_t)port error:(NSError**)error;

-(BOOL)sendMessage:(NSData*)message to:(OCAddress*)address error:(NSError**)error;

@end
