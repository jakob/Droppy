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

+(OCPeer*)localPeer {
	static OCPeer *localPeer;
	if (!localPeer) {
		localPeer = [[OCPeer alloc] init];
		
		/* Peer UUID is created randomly and stored in user defaults */
		NSData *uuidData = [[NSUserDefaults standardUserDefaults] dataForKey:@"PeerUUID"];
		CFUUIDRef peerUUID;
		if (uuidData.length != sizeof(CFUUIDBytes)) {
			// looks like we do not a valid uuid
			// generate a new one
			peerUUID = CFUUIDCreate(kCFAllocatorDefault);
			NSMutableData *newData = [[NSMutableData alloc] initWithLength:sizeof(CFUUIDBytes)];
			*((CFUUIDBytes*)[newData mutableBytes]) = CFUUIDGetUUIDBytes(peerUUID);
			[[NSUserDefaults standardUserDefaults] setObject:newData forKey:@"PeerUUID"];
			[newData release];
		} else {
			peerUUID = CFUUIDCreateFromUUIDBytes(kCFAllocatorDefault, *((CFUUIDBytes*)uuidData.bytes));
		}
		localPeer.peerUUID = peerUUID;
		CFRelease(peerUUID);

		/* Get computer model, eg. MacBookPro12,1 */
		CFStringRef computerModel = nil;
		io_service_t pexpdev;
		if ((pexpdev = IOServiceGetMatchingService(kIOMasterPortDefault, IOServiceMatching("IOPlatformExpertDevice"))))
		{
			CFDataRef data = IORegistryEntryCreateCFProperty(pexpdev, CFSTR("model"), kCFAllocatorDefault, 0);
			if (data) {
				computerModel = CFStringCreateWithBytes(kCFAllocatorDefault, CFDataGetBytePtr(data), CFDataGetLength(data), kCFStringEncodingUTF8, false);
				CFRelease(data);
			}
		}
		if (computerModel) {
			localPeer.deviceType = (id)computerModel;
			CFRelease(computerModel);
		} else {
			localPeer.deviceType = @"Unknown";
		}

	}
	
	/* Get computer name */
	CFStringRef computername = CSCopyMachineName();
	localPeer.shortName = (id)computername;
	CFRelease(computername);
	// Alternative method to get computer name
	// #import <SystemConfiguration/SystemConfiguration.h>
	// CFStringRef computername = SCDynamicStoreCopyComputerName(nil, nil);
	
	return localPeer;
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
	[deviceType release];
	[shortName release];
    [super dealloc];
}

@end
