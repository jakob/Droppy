//
//  KVPDictionary.h
//  Oktett
//
//  Created by Jakob on 26.04.20.
//  Copyright 2020 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface KVPDictionary : NSObject {
    NSMutableData *data;
}

@property(readonly) NSData *data;

+(KVPDictionary*)dictionaryFromData:(NSData*)data error:(NSError**)error;

+(BOOL)dataIsValid:(NSData*)data;

-(NSData*)dataForDataKey:(NSData*)needle;

-(NSData*)dataForStringKey:(NSString*)key;

-(NSString*)stringForStringKey:(NSString*)key;


@end
