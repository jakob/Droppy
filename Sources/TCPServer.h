#import <Foundation/Foundation.h>

#import "TCPConnection.h"

@class TCPServer;

@protocol TCPServerDelegate <NSObject>

-(void)server:(TCPServer*)server didAcceptConnection:(TCPConnection*)connection;

@end


@interface TCPServer : NSObject {
    int listen_sock;
    uint16_t listen_port;
    dispatch_source_t listen_sock_src;
}

@property(readonly) uint16_t port;

-(BOOL)listenOnRandomPortWithDelegate:(id<TCPServerDelegate>)delegate error:(NSError**)error;

-(BOOL)listenOnPort:(uint16_t)port delegate:(id<TCPServerDelegate>)delegate error:(NSError**)error;

@end
