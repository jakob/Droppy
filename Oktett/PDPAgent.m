//
//  PDPAgent.m
//  Oktett
//
//  Created by Jakob on 21.04.20.
//  Copyright 2020 __MyCompanyName__. All rights reserved.
//

#import "PDPAgent.h"
#import "OCMessenger.h"
#import "PDPMessage.h"
#import "sodium.h"

@interface PDPAgent() <OCMessengerDelegate> 
-(void)replyToQuery:(PDPMessage*)query from:(OCAddress*)addr;
-(void)handlePeerIdentificationMessage:(PDPMessage*)message from:(OCAddress*)addr;
@end


@implementation PDPAgent

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
    
    NSData *data = [message dataSignedWithKeyPair:nil error:error];
    BOOL success = data && [messenger broadcastMessage:data port:peerDiscoveryPort error:error];
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
	PDPPeer *localPeer = [PDPPeer localPeer];
    response.messageType = PDPMessageTypeAnnounce;
    response.supportsProtocolVersion1 = localPeer.supportsProtocolVersion1;
    response.supportsEd25519 = localPeer.supportsEd25519;
    response.deviceName = localPeer.deviceName;
    response.deviceModel = localPeer.deviceModel;
    response.requestToken = query.requestToken;
    NSError *sendError = nil;
    NSData *message = [response dataSignedWithKeyPair:[PDPAgent currentDeviceKeyPair] error:&sendError];
    if (!message || ![messenger sendMessage:message to:addr error:&sendError]) {
        NSLog(@"Failed to reply to query: %@", sendError);
    }
    [response release];
}

-(void)handlePeerIdentificationMessage:(PDPMessage*)message from:(OCAddress*)addr {
    NSLog(@"Peer discovered: %@:%d %@ %@", addr.presentationAddress, addr.port, message.deviceModel, message.deviceName);
    PDPPeer *peer = nil;
    if (message.publicKey) {
        for (PDPPeer *existingPeer in peers) {
            if ([existingPeer.publicKey isEqual:message.publicKey]) {
                peer = existingPeer;
                break;
            }
        }
    } else {
        for (PDPPeer *existingPeer in peers) {
            if (existingPeer.publicKey) {
                // if the peer has a public key, all their messages must be signed
                continue;
            }
            if ([[existingPeer.recentAddresses objectAtIndex:0] isEqual:addr]) {
                peer = existingPeer;
                break;
            }
        }
    }
    BOOL isNew = !peer;
    if (isNew) {
        peer = [[PDPPeer alloc] init];
        peer.publicKey = message.publicKey;
        [peers addObject:peer];
        [peer release];
    }
    if (message.deviceModel) peer.deviceModel = message.deviceModel;
    if (message.deviceName) peer.deviceName = message.deviceName;
    peer.supportsProtocolVersion1 = peer.supportsProtocolVersion1;
    peer.supportsEd25519 = peer.supportsEd25519;
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

+(Ed25519KeyPair*)currentDeviceKeyPair {
    static Ed25519KeyPair *keyPair;
    if (keyPair) return keyPair;
    // First check if we already have an accound name
    NSString *accountName = [[NSUserDefaults standardUserDefaults] stringForKey:@"DeviceAccountName"];
    if (accountName) {
        // try to get the key pair from the key chain
        NSError *error = nil;
        keyPair = [[Ed25519KeyPair keyPairFromKeychainWithServiceName:@"PDP Device Key" accountName:accountName error:&error] retain];
        if (keyPair) return keyPair;
        
        // we couldn't get the key pair from the keychain (not found or no permission)
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:@"Could not read device key"];
        [alert setInformativeText:[NSString stringWithFormat:@"%@\n\nYou can generate a new key, but then your device will appear like an unknown device to others.", error.localizedDescription]];
        [alert addButtonWithTitle:@"Quit"];
        [alert addButtonWithTitle:@"Generate New Key"];
        NSInteger result = [alert runModal];
        [alert release];
        if (result == NSAlertFirstButtonReturn) {
            exit(0);
        }
    }
    
    // We need to generate a key!
    accountName = [NSString stringWithFormat:@"PDP Device %08X %08X", randombytes_random(), randombytes_random()];
    keyPair = [[Ed25519KeyPair alloc] init];
    NSError *keychainAddError = nil;
    if ([keyPair saveAsGenericKeychainItemWithServiceName:@"PDP Device Key" accountName:accountName error:&keychainAddError]) {
        NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
        [standardUserDefaults setObject:accountName forKey:@"DeviceAccountName"];
        // Make sure we don't forget the name of our newly generated key in case of crash
        [standardUserDefaults synchronize];
    } else {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:@"Could not save device key"];
        [alert setInformativeText:[NSString stringWithFormat:@"A newly generated device key could not be saved to the keychain because: %@.\n\nYou can continue, but this device will appear as an unknown device to others when you next start the app.", keychainAddError.localizedDescription]];
        [alert addButtonWithTitle:@"Quit"];
        [alert addButtonWithTitle:@"Continue"];
        NSInteger result = [alert runModal];
        [alert release];
        if (result == NSAlertFirstButtonReturn) {
            exit(0);
        }
    }
    return keyPair;
}


@end
