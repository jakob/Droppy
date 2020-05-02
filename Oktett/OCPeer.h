//
//  OCPeer.h
//  Oktett
//
//  Created by Jakob on 21.04.20.
//  Copyright 2020 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OCAddress;
@class Ed25519PublicKey;

@interface OCPeer : NSObject {
    BOOL supportsProtocolVersion1;
    BOOL supportsEd25519;
    NSString *deviceName;
    NSString *deviceModel;
    NSMutableArray *recentAddresses;
    Ed25519PublicKey *publicKey;
}

@property BOOL supportsProtocolVersion1;
@property BOOL supportsEd25519;
@property(copy) NSString *deviceName;
@property(copy) NSString *deviceModel;
@property(readonly) NSArray *recentAddresses;
@property(retain) Ed25519PublicKey *publicKey;

-(void)addRecentAddress:(OCAddress*)address;

+(OCPeer*)localPeer;

@end
