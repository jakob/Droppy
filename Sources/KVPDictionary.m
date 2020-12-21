//
//  KVPDictionary.m
//  Oktett
//
//  Created by Jakob on 26.04.20.
//  Copyright 2020 __MyCompanyName__. All rights reserved.
//

#import "KVPDictionary.h"
#import "NSError+ConvenienceConstructors.h"

NSString *KVPErrorDomain = @"KVPErrorDomain";

@implementation KVPDictionary

-(void)dealloc {
    [data release];
    [super dealloc];
}

+(KVPDictionary*)dictionaryFromData:(NSData*)data error:(NSError**)error {
    if (![self dataIsValid:data]) {
        [NSError set:error
              domain:@"KVPDictionary"
                code:1
              format:@"Data is not in KVP format."];
        return nil;
    }
    KVPDictionary *dict = [[KVPDictionary alloc] init];
    dict->data = [data copy];
    return [dict autorelease];
}

+(BOOL)dataIsValid:(NSData*)data {
    const uint8_t *bytes = data.bytes;
    const uint8_t *end = bytes + data.length;
    while (bytes<end) {
        bytes += 1 + *bytes; // key
        if (bytes >= end) return NO; // key without value
        bytes += 1 + *bytes; // value
    }
    return bytes == end;
}

-(NSData*)dataForDataKey:(NSData*)needle {
    const uint8_t *needle_bytes = needle.bytes;
    NSUInteger needle_len = needle.length;
    const uint8_t *bytes = data.bytes;
    const uint8_t *end = bytes + data.length;
    while (bytes<end) {
        BOOL keymatch = NO;
        int keylen = *bytes++;
        if (bytes + keylen > end) return nil; // buffer overflow
        if (keylen == needle_len) {
            if (0 == memcmp(bytes, needle_bytes, keylen)) {
                keymatch = YES;
            }
        }
        bytes += keylen;
        if (bytes >= end) return nil; // no value
        int vallen = *bytes++;
        if (bytes + vallen > end) return nil; // buffer overflow
        if (keymatch) {
            return [NSData dataWithBytes:bytes length:vallen];
        }
        bytes += vallen; // value
    }
    return nil;
}

-(NSData*)dataForStringKey:(NSString*)key {
    NSData *dataKey = [key dataUsingEncoding:NSUTF8StringEncoding];
    return [self dataForDataKey:dataKey];
}

-(NSString*)stringForStringKey:(NSString*)key {
    NSData *valueData = [self dataForStringKey:key];
    return [[[NSString alloc] initWithData:valueData encoding:NSUTF8StringEncoding] autorelease];
}

-(BOOL)getUInt16:(uint16_t*)outVal forStringKey:(NSString*)key error:(NSError**)error {
    size_t numBytes = sizeof(*outVal);
    NSData *value = [self dataForStringKey:key];
    if ([value length] != numBytes) {
        [NSError set:error
              domain:@"KVPDictionary"
                code:1
              format:@"Expected length %d, got %d", numBytes, (int)[value length]];
        return NO;
    }
    const uint8_t *int_bytes = [value bytes];
    *outVal = 0;
    for (size_t i = 0; i < numBytes; i++) *outVal += (uint64_t)int_bytes[i] << ((numBytes-1-i)*8);
    return YES;
}

-(BOOL)getUInt32:(uint32_t*)outVal forStringKey:(NSString*)key error:(NSError**)error {
    size_t numBytes = sizeof(*outVal);
    NSData *value = [self dataForStringKey:key];
    if ([value length] != numBytes) {
        [NSError set:error
              domain:@"KVPDictionary"
                code:1
              format:@"Expected length %d, got %d", numBytes, (int)[value length]];
        return NO;
    }
    const uint8_t *int_bytes = [value bytes];
    *outVal = 0;
    for (size_t i = 0; i < numBytes; i++) *outVal += (uint64_t)int_bytes[i] << ((numBytes-1-i)*8);
    return YES;
}

-(BOOL)getUInt64:(uint64_t*)outVal forStringKey:(NSString*)key error:(NSError**)error {
    size_t numBytes = sizeof(*outVal);
    NSData *value = [self dataForStringKey:key];
    if ([value length] != numBytes) {
        [NSError set:error
              domain:@"KVPDictionary"
                code:1
              format:@"Expected length %d, got %d", numBytes, (int)[value length]];
        return NO;
    }
    const uint8_t *int_bytes = [value bytes];
    *outVal = 0;
    for (size_t i = 0; i < numBytes; i++) *outVal += (uint64_t)int_bytes[i] << ((numBytes-1-i)*8);
    return YES;
}


-(NSData *)data {
    return [[data copy] autorelease];
}

-(Ed25519PublicKey *)verifiedPublicKeyForKey:(NSString *)key error:(NSError **)error {
    NSData *keyAndSignature = [self dataForStringKey:key];
    if (!keyAndSignature) {
        [NSError set:error 
              domain:KVPErrorDomain
                code:KVPErrorCodeNoSignature
              format:@"Message is not signed."];
        return nil;
    }
    if (keyAndSignature.length != 96) {
        [NSError set:error 
              domain:KVPErrorDomain
                code:KVPErrorCodeInvalidSignature
              format:@"Signature is not the right length."];
        return nil;
    }
    if (memcmp(keyAndSignature.bytes, data.bytes+data.length-96, 96) != 0) {
        [NSError set:error 
              domain:KVPErrorDomain
                code:KVPErrorCodeInvalidSignature
              format:@"Signature expected at end of message."];
        return nil;
    }
    NSData *keyData = [NSData dataWithBytes:keyAndSignature.bytes length:32];
    Ed25519PublicKey *publicKey = [Ed25519PublicKey publicKeyWithData:keyData error:error];
    if (!publicKey) {
        return nil;
    }
    NSData *signatureData = [NSData dataWithBytes:keyAndSignature.bytes+32 length:64];
    NSData *truncatedData = [NSData dataWithBytes:data.bytes length:data.length-64];
    BOOL isSignatureValid = [publicKey verifySignature:signatureData forMessage:truncatedData error:error];
    if (!isSignatureValid) {
        return nil;
    }
    return publicKey;
}

@end
