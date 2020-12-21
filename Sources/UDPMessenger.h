//
//  UDPMessenger.h
//  Oktett
//
//  Created by Jakob on 21.04.20.
//  Copyright 2020 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "IPAddress.h"
@class UDPMessenger;

@protocol UDPMessengerDelegate <NSObject>

-(void)messenger:(UDPMessenger*)messenger
  didReceiveData:(NSData*)data
            from:(IPAddress*)addr;

@end

@interface UDPMessenger : NSObject {
    int udp_sock;
    int udp_port;
    dispatch_source_t udp_sock_src;
}

-(BOOL)bindUDPPort:(uint16_t)port delegate:(id<UDPMessengerDelegate>)delegate error:(NSError**)error;

-(BOOL)broadcastMessage:(NSData*)message port:(uint16_t)port error:(NSError**)error;

-(BOOL)sendMessage:(NSData*)message to:(IPAddress*)address error:(NSError**)error;

@end
