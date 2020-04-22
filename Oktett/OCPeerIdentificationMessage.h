//
//  OCPeerIdentificationMessage.h
//  Oktett
//
//  Created by Jakob on 21.04.20.
//  Copyright 2020 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OCPeerIdentificationMessage : NSObject {
    uint16_t minSupportedProtocol;
    uint16_t maxSupportedProtocol;
    CFUUIDBytes requestUUID;
    CFUUIDBytes peerUUID;
    NSString *deviceType;
    NSString *shortName;
}

@property uint16_t minSupportedProtocol;
@property uint16_t maxSupportedProtocol;
@property CFUUIDRef requestUUID;
@property CFUUIDRef peerUUID;
@property(copy) NSString *deviceType;
@property(copy) NSString *shortName;

-(NSData*)data;
+(OCPeerIdentificationMessage*)messageFromData:(NSData*)data error:(NSError**)error;

@end
