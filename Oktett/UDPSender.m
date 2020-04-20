//
//  UDPBroadcaster.m
//  Oktett
//
//  Created by Jakob on 19.04.20.
//  Copyright 2020 __MyCompanyName__. All rights reserved.
//

#import "UDPSender.h"

#include <ifaddrs.h>
#include <arpa/inet.h>
#include <net/if.h>
#import "NSError+ConvenienceConstructors.h"


@implementation UDPSender


-(BOOL)broadcastData:(NSData*)data destinationPort:(uint16_t)port {
    
    // fetch a linked list of all network interfaces
    struct ifaddrs *interfaces;
    if (getifaddrs(&interfaces) == -1) {
        [NSError set: error
              domain: @"UDPSender"
                code: OktettErrorUDPSender
              format: @"getifaddrs() failed: %s", strerror(errno)];
        return NO;
    }
    
    // loop through the linked list
    for(struct ifaddrs *interface=interfaces; interface; interface=interface->ifa_next) {
        
        // ignore loopback interfaces
        if (interface->ifa_flags & IFF_LOOPBACK) continue;
        
        // ignore interfaces that don't have a broadcast address
        if (!(interface->ifa_flags & IFF_BROADCAST) || interface->ifa_dstaddr == NULL) continue;
        
        // check the type of the address (IPv4, IPv6)
        int protocol_family;
        struct sockaddr_in ipv4_addr = {0};
        struct sockaddr_in6 ipv6_addr = {0};
        struct sockaddr *addr;
        if (interface->ifa_dstaddr->sa_family == AF_INET) {
            if (interface->ifa_dstaddr->sa_len > sizeof ipv4_addr) {
                NSLog(@"Address too big");
                continue;
            }
            protocol_family = PF_INET;
            memcpy(&ipv4_addr, interface->ifa_dstaddr, interface->ifa_dstaddr->sa_len);
            ipv4_addr.sin_port = htons(port);
            addr = (struct sockaddr *)&ipv4_addr;
            
            char text_addr[255] = {0};
            inet_ntop(AF_INET, &ipv4_addr.sin_addr, text_addr, sizeof text_addr);
            NSLog(@"Sending message to %s:%d", text_addr, ntohs(ipv4_addr.sin_port));
        }
        else if (interface->ifa_dstaddr->sa_family == AF_INET6) {
            if (interface->ifa_dstaddr->sa_len > sizeof ipv6_addr) {
                NSLog(@"Address too big");
                continue;
            }
            protocol_family = PF_INET6;
            memcpy(&ipv6_addr, interface->ifa_dstaddr, interface->ifa_dstaddr->sa_len);
            ipv6_addr.sin6_port = htons(port);
            addr = (struct sockaddr *)&ipv6_addr;
            
            char text_addr[255] = {0};
            inet_ntop(AF_INET6, &ipv6_addr.sin6_addr, text_addr, sizeof text_addr);
            NSLog(@"Sending message to %s:%d", text_addr, ntohs(ipv6_addr.sin6_port));
        }
        else {
            NSLog(@"Unsupported protocol: %d", interface->ifa_dstaddr->sa_family);
            continue;
        }
        
        // create a socket
        int sock = socket(protocol_family, SOCK_DGRAM, IPPROTO_UDP);
        if (sock == -1) {
            NSLog(@"socket() failed: %s", strerror(errno));
            continue;
        }
        
        // configure the socket for broadcast mode
        int yes = 1;
        if (-1 == setsockopt(sock, SOL_SOCKET, SO_BROADCAST, &yes, sizeof yes)) {
            NSLog(@"setsockopt() failed: %s", strerror(errno));
        }
        
        if (-1 == connect(sock, addr, addr->sa_len)) {
            NSLog(@"connect() failed: %s", strerror(errno));
        }
        
        // send the message
        ssize_t sent_bytes = send(sock, data.bytes, data.length, 0);
        if (sent_bytes == -1) {
            NSLog(@"send() failed: %s", strerror(errno));
        }
        else if (sent_bytes<data.length) {
            NSLog(@"send() sent only %d of %d bytes", (int)sent_bytes, (int)data.length);
        }
        
        // close the socket! important! there is only a finite number of file descriptors available!
        if (-1 == close(sock)) {
            NSLog(@"close() failed: %s", strerror(errno));
        }
    }
    
    freeifaddrs(interfaces);
}


@end
