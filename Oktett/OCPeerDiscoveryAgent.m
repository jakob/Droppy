//
//  OCPeerDiscoveryAgent.m
//  Oktett
//
//  Created by Jakob on 21.04.20.
//  Copyright 2020 __MyCompanyName__. All rights reserved.
//

#import "OCPeerDiscoveryAgent.h"
#import "OCMessenger.h"
#import "PDPMessage.h"
#import "sodium.h"

@interface OCPeerDiscoveryAgent() <OCMessengerDelegate> 
-(void)replyToQuery:(PDPMessage*)query from:(OCAddress*)addr;
-(void)handlePeerIdentificationMessage:(PDPMessage*)message from:(OCAddress*)addr;
@end


@implementation OCPeerDiscoveryAgent

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
    PDPMessage *message = [[PDPMessage alloc] init];
    
    message.supportsProtocolVersion1 = YES;
    message.messageType = PDPMessageTypeScan;
    
    [lastScanToken release];
    NSMutableData *mutableToken = [[NSMutableData alloc] initWithLength:12];
    randombytes_buf(mutableToken.mutableBytes, 12);
    lastScanToken = [mutableToken copy];
    [mutableToken release];
    message.requestToken = lastScanToken;
    
    NSData *data = [message data];
    BOOL success = [messenger broadcastMessage:data port:peerDiscoveryPort error:error];
    [message release];
    
    return success;
}

-(void)messenger:(OCMessenger *)messenger didReceiveData:(NSData *)data from:(OCAddress *)addr {
    NSError *parseError = nil;
    PDPMessage *message = [PDPMessage messageFromData:data error:&parseError];
    if (!message) {
        NSLog(@"Received invalid message: %@", parseError);
    }
    if (message.messageType == PDPMessageTypeScan) {
        [self replyToQuery:message from:addr];
    }
    else if (message.messageType == PDPMessageTypeAnnounce) {
        [self handlePeerIdentificationMessage:message from:addr];
    }
    else {
        NSLog(@"Received message of unknown type: %02x", message.messageType);
    }
}

-(void)replyToQuery:(PDPMessage*)query from:(OCAddress*)addr {
    NSLog(@"Replying to query message from %@:%d requestToken: %@", addr.presentationAddress, addr.port, query.requestToken);
    PDPMessage *response = [[PDPMessage alloc] init];
	OCPeer *localPeer = [OCPeer localPeer];
    response.messageType = PDPMessageTypeAnnounce;
    response.supportsProtocolVersion1 = localPeer.supportsProtocolVersion1;
    response.deviceName = localPeer.deviceName;
    response.deviceModel = localPeer.deviceModel;
    response.requestToken = query.requestToken;
    NSError *sendError = nil;
    if (![messenger sendMessage:[response data] to:addr error:&sendError]) {
        NSLog(@"Failed to reply to query: %@", sendError);
    }
    [response release];
}

-(void)handlePeerIdentificationMessage:(PDPMessage*)message from:(OCAddress*)addr {
    NSLog(@"Peer discovered: %@:%d %@ %@", addr.presentationAddress, addr.port, message.deviceModel, message.deviceName);
    OCPeer *peer = nil;
    for (OCPeer *existingPeer in peers) {
        if ([[existingPeer.recentAddresses objectAtIndex:0] isEqual:addr]) {
            // it's a match!
            peer = existingPeer;
            break;
        }
    }
    BOOL isNew = !peer;
    if (isNew) {
        peer = [[OCPeer alloc] init];
        [peers addObject:peer];
        [peer release];
    }
    if (message.deviceModel) peer.deviceModel = message.deviceModel;
    if (message.deviceName) peer.deviceName = message.deviceName;
    peer.supportsProtocolVersion1 = peer.supportsProtocolVersion1;
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
