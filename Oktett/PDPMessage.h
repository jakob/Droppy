//
//  PDPMessage.h
//  Oktett
//
//  Created by Jakob on 26.04.20.
//  Copyright 2020 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Ed25519PublicKey.h"
#import "Ed25519KeyPair.h"

typedef enum {
    PDPMessageTypeAnnounce = 'A',
    PDPMessageTypeScan = 'S'
} PDPMessageType;

@interface PDPMessage : NSObject {
    PDPMessageType messageType;
    BOOL supportsProtocolVersion1;
    BOOL supportsEd25519;
    NSString *deviceName;
    NSString *deviceModel;
    NSData *requestToken;
    Ed25519PublicKey *publicKey;
}

@property PDPMessageType messageType; 
@property BOOL supportsProtocolVersion1;
@property BOOL supportsEd25519;
@property(copy) NSString *deviceName;
@property(copy) NSString *deviceModel;
@property(copy) NSData *requestToken;
@property(retain) Ed25519PublicKey *publicKey;

-(NSData *)dataSignedWithKeyPair:(Ed25519KeyPair*)keyPair error:(NSError**)error;
+(PDPMessage*)messageFromData:(NSData*)data error:(NSError**)error;

@end
