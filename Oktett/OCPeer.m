//
//  OCPeer.m
//  Oktett
//
//  Created by Jakob on 21.04.20.
//  Copyright 2020 __MyCompanyName__. All rights reserved.
//

#import "OCPeer.h"


@implementation OCPeer

@synthesize minSupportedProtocol;
@synthesize maxSupportedProtocol;
@synthesize deviceType;
@synthesize shortName;

-(id)init {
    self = [super init];
    if (self) {
        recentAddresses = [[NSMutableArray alloc] initWithCapacity:1];
    }
    return self;
}

-(void)addRecentAddress:(OCAddress*)address {
    NSInteger numRecentAddresses = recentAddresses.count;
    if (numRecentAddresses) {
        if ([[recentAddresses objectAtIndex:numRecentAddresses-1] isEqual:address]) {
            return;
        }
        [recentAddresses removeObject:address];
    }
    [recentAddresses addObject:address];
}

-(NSArray *)recentAddresses {
    return [[recentAddresses copy] autorelease];
}

-(CFUUIDRef)peerUUID {
    CFUUIDRef ref = CFUUIDCreateFromUUIDBytes(kCFAllocatorDefault, peerUUID);
    return (CFUUIDRef)[(id)ref autorelease];
}

-(void)setPeerUUID:(CFUUIDRef)newUUID {
    peerUUID = CFUUIDGetUUIDBytes(newUUID);
}

-(void)dealloc {
    [recentAddresses release];
    [super dealloc];
}

@end
