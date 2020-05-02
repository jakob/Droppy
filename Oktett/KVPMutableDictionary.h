//
//  KVPMutableDictionary.h
//  Oktett
//
//  Created by Jakob on 26.04.20.
//  Copyright 2020 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KVPDictionary.h"
#import "Ed25519PublicKey.h"
#import "Ed25519KeyPair.h"

@interface KVPMutableDictionary : KVPDictionary {
    
}

@property(retain) NSMutableData *mutableData;

-(BOOL)setData:(NSData*)valueData forDataKey:(NSData*)keyData error:(NSError**)outError;
-(BOOL)setData:(NSData*)valueData forStringKey:(NSString*)key error:(NSError**)outError;
-(BOOL)setString:(NSString*)value forStringKey:(NSString*)key error:(NSError**)outError;
-(BOOL)signWithKeyPair:(Ed25519KeyPair*)keyPair key:(NSString*)key error:(NSError**)outError;

@end
