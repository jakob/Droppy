#import "PDPAgent.h"
#import "UDPMessenger.h"
#import "TCPServer.h"
#import "PDPMessage.h"
#import "sodium.h"


@interface PDPAgent() <UDPMessengerDelegate, TCPServerDelegate> 
-(void)replyToQuery:(PDPMessage*)query from:(IPAddress*)addr;
-(void)handlePeerIdentificationMessage:(PDPMessage*)message from:(IPAddress*)addr;
@end


@implementation PDPAgent

@synthesize delegate;

-(id)init {
    self = [super init];
    if (self) {
        peers = [[NSMutableArray alloc] initWithCapacity:8];
        messenger = [[UDPMessenger alloc] init];
        server = [[TCPServer alloc] init];
        peerDiscoveryPort = 65012;
    }
    return self;
}

-(void)readPeersFromUserDefaults {
    [peers removeAllObjects];
    NSArray *peerDicts = [[NSUserDefaults standardUserDefaults] objectForKey:@"Peers"];
    if ([peerDicts isKindOfClass:[NSArray class]]) {
        for (int i=0; i<[peerDicts count]; i++) {
            NSDictionary *dict = [peerDicts objectAtIndex:i];
            if ([dict isKindOfClass:[NSDictionary class]]) {
                PDPPeer *peer = [[PDPPeer alloc] init];
                if ([peer setDictionaryRepresentation:dict error:nil]) {
                    [peers addObject:peer];
                }
                [peer release];
            }
        }
    }
}

-(void)removePeer:(PDPPeer *)peer {
    Ed25519PublicKey *publicKey = peer.publicKey;
    if (publicKey) {
        NSArray *peerDicts = [[NSUserDefaults standardUserDefaults] objectForKey:@"Peers"];
        if ([peerDicts isKindOfClass:[NSArray class]]) {
            NSMutableArray *mutablePeerDicts = [peerDicts mutableCopy];
            for (int i=[peerDicts count]; i-->0;) {
                NSDictionary *dict = [peerDicts objectAtIndex:i];
                if ([dict isKindOfClass:[NSDictionary class]]) {
                    NSString *deviceKey = [dict objectForKey:@"DeviceKey"];
                    if ([deviceKey isKindOfClass:[NSString class]]) {
                        Ed25519PublicKey *peerPublicKey = [Ed25519PublicKey publicKeyWithStringRepresentation:deviceKey error:nil];
                        if ([peerPublicKey isEqual:publicKey]) {
                            [mutablePeerDicts removeObjectAtIndex:i];
                        }
                    }
                }
            }
            [[NSUserDefaults standardUserDefaults] setObject:mutablePeerDicts forKey:@"Peers"];
            [mutablePeerDicts release];
        }
    }
    [peers removeObject:peer];
}

-(BOOL)setupWithError:(NSError**)error {
    [self readPeersFromUserDefaults];
    BOOL st;
    st = [messenger bindUDPPort: peerDiscoveryPort delegate: self error: error];
    if (!st) return NO;
    st = [server listenOnRandomPortWithDelegate:self error:error];
    if (!st) return NO;
    [PDPPeer localPeer].tcpListenPort = server.port;
    return YES;
}

-(BOOL)scanWithError:(NSError**)error {
    PDPMessage *message = [[PDPMessage alloc] init];
    
    message.messageType = PDPMessageTypeScan;
    message.supportsUnencryptedConnection = NO;
    message.supportsEncryptedConnectionV1 = YES;
    
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

-(void)messenger:(UDPMessenger *)messenger didReceiveData:(NSData *)data from:(IPAddress *)addr {
    NSError *parseError = nil;
    PDPMessage *message = [PDPMessage messageFromData:data error:&parseError];
    if (!message) {
        NSLog(@"Received invalid message: %@", parseError);
    }
    else if (message.messageType == PDPMessageTypeScan) {
        [self replyToQuery:message from:addr];
    }
    else if (message.messageType == PDPMessageTypeAnnounce) {
        [self handlePeerIdentificationMessage:message from:addr];
    }
    else {
        NSLog(@"Received message of unknown type: %02x", message.messageType);
    }
}

-(void)replyToQuery:(PDPMessage*)query from:(IPAddress*)addr {
    PDPMessage *response = [[PDPMessage alloc] init];
	PDPPeer *localPeer = [PDPPeer localPeer];
    response.messageType = PDPMessageTypeAnnounce;
    response.supportsUnencryptedConnection = localPeer.supportsUnencryptedConnection;
    response.supportsEncryptedConnectionV1 = localPeer.supportsEncryptedConnectionV1;
    response.deviceName = localPeer.deviceName;
    response.deviceModel = localPeer.deviceModel;
    response.tcpListenPort = localPeer.tcpListenPort;
    response.requestToken = query.requestToken;
    NSError *sendError = nil;
    NSData *message = [response dataSignedWithKeyPair:[PDPAgent currentDeviceKeyPair] error:&sendError];
    if (!message || ![messenger sendMessage:message to:addr error:&sendError]) {
        NSLog(@"Failed to reply to query: %@", sendError);
    }
    [response release];
}

-(BOOL)announceWithError:(NSError**)error {
    PDPMessage *response = [[PDPMessage alloc] init];
	PDPPeer *localPeer = [PDPPeer localPeer];
    response.messageType = PDPMessageTypeAnnounce;
    response.supportsUnencryptedConnection = localPeer.supportsUnencryptedConnection;
    response.supportsEncryptedConnectionV1 = localPeer.supportsEncryptedConnectionV1;
    response.deviceName = localPeer.deviceName;
    response.deviceModel = localPeer.deviceModel;
    response.tcpListenPort = localPeer.tcpListenPort;
    NSData *message = [response dataSignedWithKeyPair:[PDPAgent currentDeviceKeyPair] error:error];
    BOOL status = message && [messenger broadcastMessage:message port:peerDiscoveryPort error:error];
    [response release];
    return status;
}

-(void)handlePeerIdentificationMessage:(PDPMessage*)message from:(IPAddress*)addr {
    PDPPeer *peer = nil;
    if (message.publicKey) {
        if ([message.publicKey isEqual:[PDPPeer localPeer].publicKey]) {
            return;
        }
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
    peer.tcpListenPort = message.tcpListenPort;
    peer.supportsUnencryptedConnection = peer.supportsUnencryptedConnection;
    peer.supportsEncryptedConnectionV1 = peer.supportsEncryptedConnectionV1;
    [peer addRecentAddress:addr];
    [peer writeToUserDefaults];
    if (isNew) [delegate agent:self discoveredPeer:peer];
    else [delegate agent:self updatedPeer:peer];
}

-(void)server:(TCPServer *)server didAcceptConnection:(TCPConnection *)connection {
    
    [delegate agent:self didAcceptConnection:connection];
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
