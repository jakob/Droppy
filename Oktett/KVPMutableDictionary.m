//
//  KVPMutableDictionary.m
//  Oktett
//
//  Created by Jakob on 26.04.20.
//  Copyright 2020 __MyCompanyName__. All rights reserved.
//

#import "KVPMutableDictionary.h"
#import "NSError+ConvenienceConstructors.h"

@implementation KVPMutableDictionary

-(BOOL)setData:(NSData*)valueData forDataKey:(NSData*)keyData error:(NSError**)outError {
    if ([self dataForDataKey:keyData]) {
        [NSError set:outError
              domain:@"KVPDictionary"
                code:2 
              format:@"Key already exists"];
        return NO;
    }
    
    if (keyData.length > 255) {
        [NSError set:outError
              domain:@"KVPDictionary"
                code:3 
              format:@"Key too long"];
        return NO;
    }
    
    if (valueData.length > 255) {
        [NSError set:outError
              domain:@"KVPDictionary"
                code:4
              format:@"Value too lon"];
        return NO;
    }
    
    uint8_t len;
    len = keyData.length;
    [data appendBytes:&len length:1];
    [data appendData:keyData];
    
    len = valueData.length;
    [data appendBytes:&len length:1];
    [data appendData:valueData];
    
    return YES;
}

-(BOOL)setData:(NSData*)valueData forStringKey:(NSString*)key error:(NSError**)outError {
    return [self setData:valueData forDataKey:[key dataUsingEncoding:NSUTF8StringEncoding] error:outError];    
}

-(BOOL)setString:(NSString*)value forStringKey:(NSString*)key error:(NSError**)outError {
    return [self setData:[value dataUsingEncoding:NSUTF8StringEncoding] forStringKey:key error:outError];
}

@end
