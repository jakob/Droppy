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
    BOOL supportsProtocolVersion1;
    NSString *deviceName;
    NSString *deviceModel;
    NSMutableArray *recentAddresses;
}

@property BOOL supportsProtocolVersion1;
@property(copy) NSString *deviceName;
@property(copy) NSString *deviceModel;
@property(readonly) NSArray *recentAddresses;

-(void)addRecentAddress:(OCAddress*)address;

+(OCPeer*)localPeer;

@end
