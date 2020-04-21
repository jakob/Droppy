//
//  OCInterface.m
//  Oktett
//
//  Created by Jakob on 19.04.20.
//  Copyright 2020 __MyCompanyName__. All rights reserved.
//

#import "OCInterface.h"

#include <ifaddrs.h>
#include <arpa/inet.h>
#include <net/if.h>

#import "NSError+ConvenienceConstructors.h"

@implementation OCInterface

@synthesize name, addr, dstaddr;

-(id)initWithStruct:(struct ifaddrs *)ifaddr {
    self = [super init];
    if (self != nil) {
        // copy interface name
        name = [[NSString alloc] initWithUTF8String:ifaddr->ifa_name];
        
        // copy my local network address
        addr = [[OCAddress alloc] initWithSockaddr:ifaddr->ifa_addr];
        
        // copy broadcast address
        if (ifaddr->ifa_dstaddr) {
            dstaddr = [[OCAddress alloc] initWithSockaddr:ifaddr->ifa_dstaddr];
        }
    }
    return self;
}

-(void)dealloc {
    [name release];
    [addr release];
    [dstaddr release];
    [super dealloc];
}

+(NSArray*)broadcastInterfacesWithError:(NSError**)error {

    // fetch a linked list of all network interfaces
    struct ifaddrs *ifaddrs;
    if (getifaddrs(&ifaddrs) == -1) {
        [NSError set: error
              domain: @"UDPSender"
                code: 1
              format: @"getifaddrs() failed: %s", strerror(errno)];
        return NO;
    }

    NSMutableArray *interfaces = [[NSMutableArray alloc] init];
    
    // loop through the linked list
    for(struct ifaddrs *ifaddr=ifaddrs; ifaddr; ifaddr=ifaddr->ifa_next) {
        
        // look for IPv4 addresses only (IPv6 has multicast instead of broadcast)
        if (ifaddr->ifa_addr->sa_family != AF_INET) continue;

        // ignore loopback interfaces
        if (ifaddr->ifa_flags & IFF_LOOPBACK) continue;
        
        // ignore interfaces that for some reason don't have a broadcast address
        if (!(ifaddr->ifa_flags & IFF_BROADCAST) || ifaddr->ifa_dstaddr == NULL) continue;
        
        OCInterface *interface = [[OCInterface alloc] initWithStruct:ifaddr];
        [interfaces addObject:interface];
        [interface release];
    }
    
    freeifaddrs(ifaddrs);

    return [interfaces autorelease];
}


@end

