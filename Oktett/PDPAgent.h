//
//  PDPAgent.h
//  Oktett
//
//  Created by Jakob on 21.04.20.
//  Copyright 2020 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PDPPeer.h"

@class PDPAgent;
@class OCMessenger;
@class Ed25519KeyPair;

@protocol PDPAgentDelegate
-(void)agent:(PDPAgent*)agent discoveredPeer:(PDPPeer*)peer;
-(void)agent:(PDPAgent*)agent updatedPeer:(PDPPeer*)peer;
@end

@interface PDPAgent : NSObject {
    NSMutableArray *peers;
    OCMessenger *messenger;
    uint16_t peerDiscoveryPort;
    id<PDPAgentDelegate> delegate;
    NSData *lastScanToken;
}

@property(readonly) NSArray *peers;
@property(assign) id<PDPAgentDelegate> delegate;

-(BOOL)setupWithError:(NSError**)error;

-(BOOL)scanWithError:(NSError**)error;

+(Ed25519KeyPair*)currentDeviceKeyPair;

@end
