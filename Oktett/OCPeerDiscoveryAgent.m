//
//  OCPeerDiscoveryAgent.m
//  Oktett
//
//  Created by Jakob on 21.04.20.
//  Copyright 2020 __MyCompanyName__. All rights reserved.
//

#import "OCPeerDiscoveryAgent.h"
#import "OCMessenger.h"
#import "OCQueryMessage.h"
#import "OCPeerIdentificationMessage.h"

@interface OCPeerDiscoveryAgent() <OCMessengerDelegate> {
}
-(void)replyToQuery:(OCQueryMessage*)query from:(OCAddress*)addr;
-(void)handlePeerIdentificationMessage:(OCPeerIdentificationMessage*)message from:(OCAddress*)addr;
@end


@implementation OCPeerDiscoveryAgent

@synthesize identity;
@synthesize delegate;

-(id)init {
    self = [super init];
    if (self) {
        peers = [[NSMutableArray alloc] initWithCapacity:8];
        messenger = [[OCMessenger alloc] init];
        peerDiscoveryPort = 65012;
    }
    return self;
}

-(BOOL)setupWithError:(NSError**)error {
    return [messenger bindUDPPort: peerDiscoveryPort
                         delegate: self
                            error: error];
}

-(BOOL)scanWithError:(NSError**)error {
    OCQueryMessage *message = [[OCQueryMessage alloc] init];
    message.minSupportedProtocol = MIN_PEER_DISCOVERY_PROTOCOL_VERSION;
    message.maxSupportedProtocol = MAX_PEER_DISCOVERY_PROTOCOL_VERSION;
    
    NSData *data = [message data];
    BOOL success = [messenger broadcastMessage:data port:peerDiscoveryPort error:error];
    [message release];
    
    return success;
}

-(void)messenger:(OCMessenger *)messenger didReceiveData:(NSData *)data from:(OCAddress *)addr {
    NSError *parseError = nil;
    {
        OCQueryMessage *message = [OCQueryMessage messageFromData:data error:&parseError];
        if (message) {
            [self replyToQuery:message from:addr];
            return;
        }
    }
    
    {
        OCPeerIdentificationMessage *message = [OCPeerIdentificationMessage messageFromData:data error:&parseError];
        if (message) {
            [self handlePeerIdentificationMessage:message from:addr];
            return;
        }
    }
}

-(void)replyToQuery:(OCQueryMessage*)query from:(OCAddress*)addr {
    NSLog(@"Replying to query message from %@:%d requestUUID: %@", addr.presentationAddress, addr.port, query.requestUUID);
    OCPeerIdentificationMessage *response = [[OCPeerIdentificationMessage alloc] init];
    response.minSupportedProtocol = identity.minSupportedProtocol;
    response.maxSupportedProtocol = identity.maxSupportedProtocol;
    response.requestUUID = query.requestUUID;
    response.peerUUID = identity.peerUUID;
    response.deviceType = identity.deviceType;
    response.shortName = identity.shortName;
    NSError *sendError = nil;
    if (![messenger sendMessage:[response data] to:addr error:&sendError]) {
        NSLog(@"Failed to reply to query: %@", sendError);
    }
    [response release];
}

-(void)handlePeerIdentificationMessage:(OCPeerIdentificationMessage*)message from:(OCAddress*)addr {
    NSLog(@"Peer discovered: %@:%d %@ %@", addr.presentationAddress, addr.port, message.deviceType, message.shortName);
    OCPeer *peer = nil;
    CFUUIDRef peerUUID = message.peerUUID;
    for (OCPeer *existingPeer in peers) {
        if (CFEqual(existingPeer.peerUUID, peerUUID)) {
            // it's a match!
            peer = existingPeer;
            break;
        }
    }
    BOOL isNew = !peer;
    if (isNew) {
        peer = [[OCPeer alloc] init];
        peer.peerUUID = peerUUID;
        [peers addObject:peer];
        [peer release];
    }
    peer.deviceType = message.deviceType;
    peer.shortName = message.shortName;
    peer.minSupportedProtocol = peer.minSupportedProtocol;
    peer.maxSupportedProtocol = peer.maxSupportedProtocol;
    [peer addRecentAddress:addr];
    if (isNew) [delegate agent:self discoveredPeer:peer];
    else [delegate agent:self updatedPeer:peer];
}

-(void)dealloc {
    [messenger release];
    [peers release];
	[super dealloc];
}

-(NSArray *)peers {
    return [[peers copy] autorelease];
}

@end
