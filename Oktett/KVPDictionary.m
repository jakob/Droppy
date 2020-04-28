//
//  KVPDictionary.m
//  Oktett
//
//  Created by Jakob on 26.04.20.
//  Copyright 2020 __MyCompanyName__. All rights reserved.
//

#import "KVPDictionary.h"
#import "NSError+ConvenienceConstructors.h"

@implementation KVPDictionary

-(id)init {
    self = [super init];
    if (self) {
        data = [[NSMutableData alloc] init];
    }
    return self;
}

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
    [dict->data appendData:data];
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

-(NSData *)data {
    return [[data copy] autorelease];
}

@end