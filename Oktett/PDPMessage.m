//
//  PDPMessage.m
//  Oktett
//
//  Created by Jakob on 26.04.20.
//  Copyright 2020 __MyCompanyName__. All rights reserved.
//

#import "PDPMessage.h"
#import "KVPDictionary.h"
#import "KVPMutableDictionary.h"
#import "NSError+ConvenienceConstructors.h"
#import "NSString+Additions.h"

@implementation PDPMessage

@synthesize messageType;
@synthesize supportsProtocolVersion1;
@synthesize supportsEd25519;
@synthesize deviceName;
@synthesize deviceModel;
@synthesize requestToken;
@synthesize publicKey;
@synthesize tcpListenPort;

-(void)dealloc{
	[deviceName release];
	[deviceModel release];
	[requestToken release];
	[publicKey release];
	[super dealloc];
}

+(PDPMessage *)messageFromData:(NSData *)data error:(NSError **)error {
    
    // first check the header
    if (data.length < 5) {
        [NSError set:error
              domain:@"PDPMessage"
                code:1
              format:@"Message is too short."];
        return nil;
    }
    if (memcmp(data.bytes, "\03PDP", 4) != 0) {
        [NSError set:error
              domain:@"PDPMessage"
                code:1
              format:@"Message does not have PDP header."];
        return nil;
    }
    
    // Now try to parse the KVP dictionary
    KVPDictionary *dict = [KVPDictionary dictionaryFromData:data error:error];
    if (!dict) return nil;

    // Extract the PDP header data and ensure it has minimum length
    NSData *pdp = [dict dataForStringKey:@"PDP"];
    if (pdp.length < 2) {
        [NSError set:error
              domain:@"PDPMessage"
                code:1
              format:@"PDP Message header is too short."];
        return nil;
    }
    
    PDPMessage *message = [[PDPMessage alloc] init];
    
    // Parse the PDP header data
    const uint8_t *pdp_bytes = pdp.bytes;
    message.messageType = pdp_bytes[0];
    uint8_t flags = pdp_bytes[1];
    message.supportsProtocolVersion1 = flags & 0x01 ? YES : NO;
    message.supportsEd25519 = flags & 0x02 ? YES : NO;
    
    // Extract optional fields
    message.deviceName = [dict stringForStringKey:@"N"];
    message.deviceModel = [dict stringForStringKey:@"M"];
    message.requestToken = [dict dataForStringKey:@"T"];
    
    uint16_t port;
    if ([dict getUInt16:&port forStringKey:@"p" error:nil]) {
        message.tcpListenPort = port;
    }
    
    NSError *signatureError = nil;
    Ed25519PublicKey *publicKey = [dict verifiedPublicKeyForKey:@"K" error:&signatureError];
    if (publicKey) {
        message.publicKey = publicKey;
    } else {
        if ([[signatureError domain] isEqualToString:KVPErrorDomain] && [signatureError code]==KVPErrorCodeNoSignature) {
            // unsigned message is allowed
        } else {
            // message with broken signature is not allowed
            // return error!
            if (error) *error = signatureError;
            [message release];
            return nil;
        }
    }
    
    return [message autorelease];
}


-(NSData *)dataSignedWithKeyPair:(Ed25519KeyPair*)keyPair error:(NSError**)error {
    KVPMutableDictionary *dict = [[KVPMutableDictionary alloc] init];
    
    // Write Header
    NSMutableData *pdp = [[NSMutableData alloc] initWithLength:2];
    uint8_t *pdp_bytes = pdp.mutableBytes;
    pdp_bytes[0] = self.messageType;
    if (self.supportsProtocolVersion1) pdp_bytes[1] |= 0x01;
    if (self.supportsEd25519) pdp_bytes[1] |= 0x02;
    if (![dict setData:pdp forStringKey:@"PDP" error:error]) {
        [pdp release];
        [dict release];
        return nil;
    }
    [pdp release];
    
    NSData *truncatedName = [self.deviceName dataUsingEncoding:NSUTF8StringEncoding maxEncodedLength:255];
    if (truncatedName) {
        if (![dict setData:truncatedName forStringKey:@"N" error:error]) {
            [dict release];
            return nil;
        }
    }
        
    NSData *truncatedModel = [self.deviceModel dataUsingEncoding:NSUTF8StringEncoding maxEncodedLength:255];
    if (truncatedModel) {
        if (![dict setData:truncatedModel forStringKey:@"M" error:error]) {
            [dict release];
            return nil;
        }
    }
    
    if (self.requestToken) {
        if (![dict setData:self.requestToken forStringKey:@"T" error:error]) {
            [dict release];
            return nil;
        }
    }
    
    if (tcpListenPort) {
        if (![dict setUInt16:tcpListenPort forStringKey:@"p" error:error]) {
            [dict release];
            return nil;
        }
    }

    
    if (keyPair) {
        if (![dict signWithKeyPair:keyPair key:@"K" error:error]) {
            [dict release];
            return nil;
        }
    }
    
    NSData *data = [dict data];
    [dict release];
    
    return data;
}


@end
