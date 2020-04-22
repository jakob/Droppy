//
//  OCPeerDiscoveryAgent.h
//  Oktett
//
//  Created by Jakob on 21.04.20.
//  Copyright 2020 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OCPeer.h"

#define MIN_PEER_DISCOVERY_PROTOCOL_VERSION 1
#define MAX_PEER_DISCOVERY_PROTOCOL_VERSION 1

@class OCPeerDiscoveryAgent;
@class OCMessenger;

@protocol OCPeerDiscoveryAgentDelegate
-(void)agent:(OCPeerDiscoveryAgent*)agent discoveredPeer:(OCPeer*)peer;
-(void)agent:(OCPeerDiscoveryAgent*)agent updatedPeer:(OCPeer*)peer;
@end

@interface OCPeerDiscoveryAgent : NSObject {
    OCPeer *identity;
    NSMutableArray *peers;
    OCMessenger *messenger;
    uint16_t peerDiscoveryPort;
    id<OCPeerDiscoveryAgentDelegate> delegate;
}

@property(retain) OCPeer *identity;
@property(readonly) NSArray *peers;
@property(assign) id<OCPeerDiscoveryAgentDelegate> delegate;

-(BOOL)setupWithError:(NSError**)error;

-(BOOL)scanWithError:(NSError**)error;


@end
