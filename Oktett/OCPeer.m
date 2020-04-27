//
//  OCPeer.m
//  Oktett
//
//  Created by Jakob on 21.04.20.
//  Copyright 2020 __MyCompanyName__. All rights reserved.
//

#import "OCPeer.h"


@implementation OCPeer

@synthesize supportsProtocolVersion1;
@synthesize deviceName;
@synthesize deviceModel;

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

        localPeer.supportsProtocolVersion1 = YES;
        
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
			localPeer.deviceModel = (id)computerModel;
			CFRelease(computerModel);
		} else {
			localPeer.deviceModel = @"UnknownDevice";
		}

	}
	
	/* Get computer name */
	CFStringRef deviceName = CSCopyMachineName();
	localPeer.deviceName = (id)deviceName;
	CFRelease(deviceName);
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

-(void)dealloc {
    [recentAddresses release];
	[deviceModel release];
	[deviceName release];
    [super dealloc];
}

@end
