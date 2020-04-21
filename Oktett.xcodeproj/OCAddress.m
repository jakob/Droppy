//
//  OCAddress.m
//  Oktett
//
//  Created by Jakob on 20.04.20.
//  Copyright 2020 __MyCompanyName__. All rights reserved.
//

#import "OCAddress.h"


@implementation OCAddress

-(id)initWithSockaddr:(struct sockaddr*)anAddr {
    self = [super init];
    if (self) {
        memcpy(&addr, anAddr, anAddr->sa_len);
    }
    return self;
}

-(struct sockaddr *)addr {
    return (void*)&addr;
}

-(socklen_t)len {
    return addr.ss_len;
}

-(socklen_t)maxlen {
    return sizeof(struct sockaddr_storage);
}

-(NSString*)presentationAddress {
    if (addr.ss_family == AF_INET) {
        struct sockaddr_in *addr_in = (void*)&addr;
        char pres[64] = {0};
        inet_ntop(AF_INET, &addr_in->sin_addr, pres, sizeof pres);
        return [NSString stringWithCString:pres encoding:NSUTF8StringEncoding];
    }
    else if (addr.ss_family == AF_INET6) {
        struct sockaddr_in6 *addr_in = (void*)&addr;
        char pres[64] = {0};
        inet_ntop(AF_INET6, &addr_in->sin6_addr, pres, sizeof pres);
        return [NSString stringWithCString:pres encoding:NSUTF8StringEncoding];
    }
    else {
        return @"";
    }
}

-(void)setPort:(uint16_t)port {
    if (addr.ss_family == AF_INET) {
        ((struct sockaddr_in*)&addr)->sin_port = htons(port);
    }
    else if (addr.ss_family == AF_INET6) {
        ((struct sockaddr_in6*)&addr)->sin6_port = htons(port);
    }
}

-(uint16_t)port {
    if (addr.ss_family == AF_INET) {
        return ntohs(((struct sockaddr_in*)&addr)->sin_port);
    }
    else if (addr.ss_family == AF_INET6) {
        return ntohs(((struct sockaddr_in6*)&addr)->sin6_port);
    }
    return 0;
}

-(sa_family_t)family {
    return addr.ss_family;
}

-(id)copyWithZone:(NSZone *)zone {
    OCAddress *copy = [[OCAddress allocWithZone:zone] init];
    copy->addr = addr;
    return copy;
}

@end
