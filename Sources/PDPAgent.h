#import <Foundation/Foundation.h>
#import "PDPPeer.h"

@class PDPAgent;
@class UDPMessenger;
@class Ed25519KeyPair;
@class TCPServer;
@class TCPConnection;

@protocol PDPAgentDelegate
-(void)agent:(PDPAgent*)agent discoveredPeer:(PDPPeer*)peer;
-(void)agent:(PDPAgent*)agent updatedPeer:(PDPPeer*)peer;
-(void)agent:(PDPAgent*)agent didAcceptConnection:(TCPConnection*)connection;
@end

@interface PDPAgent : NSObject {
    NSMutableArray *peers;
    UDPMessenger *messenger;
    TCPServer *server;
    uint16_t peerDiscoveryPort;
    id<PDPAgentDelegate> delegate;
    NSData *lastScanToken;
}

@property(readonly) NSArray *peers;
@property(assign) id<PDPAgentDelegate> delegate;

-(BOOL)setupWithError:(NSError**)error;

-(BOOL)scanWithError:(NSError**)error;
-(BOOL)announceWithError:(NSError**)error;

+(Ed25519KeyPair*)currentDeviceKeyPair;

-(void)removePeer:(PDPPeer*)peer;

@end
