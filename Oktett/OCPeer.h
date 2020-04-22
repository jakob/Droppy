//
//  OCPeer.h
//  Oktett
//
//  Created by Jakob on 21.04.20.
//  Copyright 2020 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OCAddress;

@interface OCPeer : NSObject {
    uint16_t minSupportedProtocol;
    uint16_t maxSupportedProtocol;
    CFUUIDBytes peerUUID;
    NSString *deviceType;
    NSString *shortName;
    NSMutableArray *recentAddresses;
}

@property uint16_t minSupportedProtocol;
@property uint16_t maxSupportedProtocol;
@property CFUUIDRef peerUUID;
@property(copy) NSString *deviceType;
@property(copy) NSString *shortName;
@property(readonly) NSArray *recentAddresses;

-(void)addRecentAddress:(OCAddress*)address;

@end
