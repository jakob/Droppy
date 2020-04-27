//
//  PDPMessage.h
//  Oktett
//
//  Created by Jakob on 26.04.20.
//  Copyright 2020 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    PDPMessageTypeAnnounce = 'A',
    PDPMessageTypeScan = 'S'
} PDPMessageType;

@interface PDPMessage : NSObject {
    PDPMessageType messageType;
    BOOL supportsProtocolVersion1;
    NSString *deviceName;
    NSString *deviceModel;
    NSData *requestToken;
}

@property PDPMessageType messageType; 
@property BOOL supportsProtocolVersion1;
@property(copy) NSString *deviceName;
@property(copy) NSString *deviceModel;
@property(copy) NSData *requestToken;

-(NSData*)data;
+(PDPMessage*)messageFromData:(NSData*)data error:(NSError**)error;

@end
