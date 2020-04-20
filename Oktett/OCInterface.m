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

-(id)initWithStruct:(struct ifaddrs *)ifaddr {
    self = [super init];
    if (self != nil) {
        // copy interface name
        name = [[NSString alloc] initWithUTF8String:ifaddr->ifa_name];
        
        // copy my local network address
        addr = malloc(ifaddr->ifa_addr->sa_len);
        memcpy(addr, ifaddr->ifa_addr, ifaddr->ifa_addr->sa_len);
        
        // copy broadcast address
        if (ifaddr->ifa_dstaddr) {
            dstaddr = malloc(ifaddr->ifa_addr->sa_len);
            memcpy(dstaddr, ifaddr->ifa_dstaddr, ifaddr->ifa_dstaddr->sa_len);
        }
    }
    return self;
}

-(void)dealloc {
    [name release];
    free(addr);
    if (dstaddr) free(dstaddr);
    if (udp_sock) close(udp_sock);
    if (udp_sock_src) dispatch_release(udp_sock_src);
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
        
        // ignore loopback interfaces
        if (ifaddr->ifa_flags & IFF_LOOPBACK) continue;
        
        // ignore interfaces that don't have a broadcast address
        if (!(ifaddr->ifa_flags & IFF_BROADCAST) || ifaddr->ifa_dstaddr == NULL) continue;
        
        OCInterface *interface = [[OCInterface alloc] initWithStruct:ifaddr];
        [interfaces addObject:interface];
        [interface release];
    }
    
    freeifaddrs(ifaddrs);

    return [interfaces autorelease];
}

-(BOOL)bindUDPPort:(uint16_t)port delegate:(id<OCInterfaceDelegate>)delegate error:(NSError **)error {
    // ensure that we don't try to connect twice
    if (udp_sock) {
        [NSError set: error
              domain: @"OCInterface"
                code: 1
              format: @"Can't bind to interface: interface already bound."];
        return NO;        
    }
    
    // set bind addr according to address family
    int protocol_family;
    struct sockaddr_storage bindaddr_storage = { 0 };
    struct sockaddr *bindaddr = (void*)&bindaddr_storage;
    if (addr->sa_family == AF_INET) {
        protocol_family = PF_INET;
        struct sockaddr_in *bindaddr_in = (void*)bindaddr;
        bindaddr_in->sin_port = htons(port);
        bindaddr_in->sin_family = addr->sa_family;
        bindaddr_in->sin_len = sizeof (struct sockaddr_in);
        bindaddr_in->sin_addr.s_addr = INADDR_ANY;
    }
    else if (addr->sa_family == AF_INET6) {
        protocol_family = PF_INET6;
        struct sockaddr_in6 *bindaddr_in6 = (void*)bindaddr;
        bindaddr_in6->sin6_port = htons(port);
        bindaddr_in6->sin6_family = addr->sa_family;
        bindaddr_in6->sin6_len = sizeof (struct sockaddr_in6);
    }
    else {
        [NSError set: error
              domain: @"OCInterface"
                code: 1
              format: @"Unsupported address family: %d.", addr->sa_family];
        return NO;        
    }
    
    // create a socket
    int sock = socket(protocol_family, SOCK_DGRAM, IPPROTO_UDP);
    if (sock == -1) {
        [NSError set: error
              domain: @"OCInterface"
                code: 1
              format: @"socket() failed: %s", strerror(errno)];
        return NO;        
    }
    
    // configure the socket for broadcast mode
    int yes = 1;
    if (-1 == setsockopt(sock, SOL_SOCKET, SO_BROADCAST, &yes, sizeof yes)) {
        [NSError set: error
              domain: @"OCInterface"
                code: 1
              format: @"setsockopt() failed: %s", strerror(errno)];
        close(sock);
        return NO;
    }
    
    // bind the socket to the local port and address
    if (-1 == bind(sock, bindaddr, bindaddr->sa_len)) {
        [NSError set: error
              domain: @"OCInterface"
                code: 1
              format: @"bind() failed: %s", strerror(errno)];
        close(sock);
        return NO;
    }
    
    // all good!
    udp_sock = sock;
    udp_port = port;
    
    // send incoming packets to delegate
    udp_sock_src = dispatch_source_create( 
        DISPATCH_SOURCE_TYPE_READ,
        udp_sock,
        0 /* unused */,
        dispatch_get_main_queue()
    );
                                       
    dispatch_source_set_event_handler(udp_sock_src, ^(void) {
        char bytes[4096];
        
        socklen_t src_addr_len = addr->sa_len;
        struct sockaddr *src_addr = malloc(src_addr_len);
        
        ssize_t recvBytes = recvfrom(udp_sock, bytes, sizeof bytes, 0, src_addr, &src_addr_len);
        if (recvBytes == -1) {
            NSLog(@"recvfrom() failed %s", strerror(errno));
            exit(1);
        }
        
        NSData *data = [NSData dataWithBytes:bytes length:recvBytes];
        NSData *src_addr_data = [NSData dataWithBytesNoCopy:src_addr length:src_addr_len freeWhenDone:YES];
        
        [delegate interface:self didReceiveData:data fromAddress:src_addr_data];
	});
    dispatch_resume(udp_sock_src);

    return YES;
}

-(BOOL)broadcastMessage:(NSData*)message port:(uint16_t)port error:(NSError**)error {
    // ensure that socket is bound to a local port
    if (!udp_sock) {
        [NSError set: error
              domain: @"OCInterface"
                code: 1
              format: @"Must bind UDP socket before ssend."];
        return NO;        
    }
    
    // check address family and set the port
    int protocol_family;
    if (dstaddr->sa_family == AF_INET) {
        protocol_family = PF_INET;
        struct sockaddr_in *addr_in = (void*)dstaddr;
        addr_in->sin_port = htons(port);
    }
    else if (addr->sa_family == AF_INET6) {
        protocol_family = PF_INET6;
        struct sockaddr_in6 *addr_in6 = (void*)dstaddr;
        addr_in6->sin6_port = htons(port);
    }
    else {
        [NSError set: error
              domain: @"OCInterface"
                code: 1
              format: @"Unsupported address family: %d.", dstaddr->sa_family];
        return NO;        
    }

    // send the message
    ssize_t sent_bytes = sendto(udp_sock, message.bytes, message.length, 0, dstaddr, dstaddr->sa_len);
    if (sent_bytes == -1) {
        [NSError set: error
              domain: @"OCInterface"
                code: 1
              format: @"send() failed: %s", strerror(errno)];
        return NO;        
    }
    else if (sent_bytes < message.length) {
        [NSError set: error
              domain: @"OCInterface"
                code: 1
              format: @"send() sent only %d of %d bytes", (int)sent_bytes, (int)message.length];
        return NO;        
    }
    
    return YES;
}

@end

