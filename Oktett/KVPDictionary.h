//
//  KVPDictionary.h
//  Oktett
//
//  Created by Jakob on 26.04.20.
//  Copyright 2020 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Ed25519PublicKey.h"

typedef enum {
    KVPErrorCodeNoSignature      = 4500001,
    KVPErrorCodeInvalidSignature = 4500002
} KVPErrorCode;

extern NSString *KVPErrorDomain;

@interface KVPDictionary : NSObject {
    NSData *data;
}

@property(readonly) NSData *data;

+(KVPDictionary*)dictionaryFromData:(NSData*)data error:(NSError**)error;

+(BOOL)dataIsValid:(NSData*)data;

-(NSData*)dataForDataKey:(NSData*)needle;

-(NSData*)dataForStringKey:(NSString*)key;

-(NSString*)stringForStringKey:(NSString*)key;

-(BOOL)getUInt16:(uint16_t*)outVal forStringKey:(NSString*)key error:(NSError**)error;
-(BOOL)getUInt32:(uint32_t*)outVal forStringKey:(NSString*)key error:(NSError**)error;
-(BOOL)getUInt64:(uint64_t*)outVal forStringKey:(NSString*)key error:(NSError**)error;

-(Ed25519PublicKey*)verifiedPublicKeyForKey:(NSString*)key error:(NSError**)error;

@end
