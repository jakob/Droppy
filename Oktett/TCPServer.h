//
//  TCPServer.h
//  Oktett
//
//  Created by Jakob on 28.11.20.
//  Copyright 2020 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "TCPConnection.h"

@class TCPServer;

@protocol TCPServerDelegate <NSObject>

-(void)server:(TCPServer*)server didAcceptConnection:(TCPConnection*)connection;

@end


@interface TCPServer : NSObject {
    int listen_sock;
    int listen_port;
    dispatch_source_t listen_sock_src;
}

-(BOOL)listenOnRandomPortWithDelegate:(id<TCPServerDelegate>)delegate error:(NSError**)error;

-(BOOL)listenOnPort:(uint16_t)port delegate:(id<TCPServerDelegate>)delegate error:(NSError**)error;

@end
