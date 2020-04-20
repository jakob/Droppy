//
//  OCInterface.h
//  Oktett
//
//  Created by Jakob on 19.04.20.
//  Copyright 2020 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OCInterface;

@protocol OCInterfaceDelegate <NSObject>

-(void)interface:(OCInterface*)interface
  didReceiveData:(NSData*)data
     fromAddress:(NSData*)addr;

@end



@interface OCInterface : NSObject {
    NSString *name;
    struct sockaddr *addr;
    struct sockaddr *dstaddr;
    int udp_sock;
    int udp_port;
    dispatch_source_t udp_sock_src;
}

+(NSArray*)broadcastInterfacesWithError:(NSError**)error;

-(BOOL)bindUDPPort:(uint16_t)port delegate:(id<OCInterfaceDelegate>)delegate error:(NSError**)error;

-(BOOL)broadcastMessage:(NSData*)message port:(uint16_t)port error:(NSError**)error;

@end
