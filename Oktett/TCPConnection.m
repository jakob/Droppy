//
//  TCPConnection.m
//  Oktett
//
//  Created by Jakob on 28.11.20.
//  Copyright 2020 __MyCompanyName__. All rights reserved.
//

#import "TCPConnection.h"

#import "NSError+ConvenienceConstructors.h"

@implementation TCPConnection

@synthesize remoteAddress;

-(void)dealloc {
    if (tcp_sock) close(tcp_sock);
    [remoteAddress release];
    [super dealloc];
}

-(id)initWithSocket:(int)sock remoteAddress:(IPAddress *)address {
    self = [super init];
    if (self) {
        tcp_sock = sock;
        remoteAddress = [address retain];
    }
    return self;
}

+(TCPConnection *)connectTo:(IPAddress *)address error:(NSError **)error {
    // create a socket
    int sock = socket(PF_INET, SOCK_STREAM, IPPROTO_TCP);
    if (sock == -1) {
        [NSError set: error
              domain: @"TCPConnection"
                code: 1
              format: @"socket() failed: %s", strerror(errno)];
        return NO;        
    }

    // connect to the remote address
    if (-1 == connect(sock, address.addr, address.len)) {
        [NSError set: error
              domain: @"TCPConnection"
                code: 1
              format: @"connect() failed: %s", strerror(errno)];
        return NO;        
    }
    
    TCPConnection *connection = [[TCPConnection alloc] initWithSocket:sock remoteAddress:address];
    return [connection autorelease];
}

-(BOOL)sendData:(NSData *)data error:(NSError **)error {
    ssize_t total = 0;
    ssize_t len = [data length];
    const void *bytes = [data bytes];
    while (total < len) {
        ssize_t sent = send(tcp_sock, bytes + total, len - total, 0);
        if (sent == -1) {
            if (errno == EINTR) continue;
            [NSError set: error
                  domain: @"TCPConnection"
                    code: 1
                  format: @"send() failed: %s", strerror(errno)];
            return NO;        
        }
        if (sent == 0) {
            [NSError set: error
                  domain: @"TCPConnection"
                    code: 1
                  format: @"send() sent 0 bytes"];
            return NO;        
        }
        total += sent;
    }
    return YES;
}

-(NSData *)receiveDataWithLength:(NSUInteger)length error:(NSError **)error {
    NSMutableData *mutableData = [[NSMutableData alloc] initWithLength:length];
    ssize_t total = 0;
    void *bytes = [mutableData mutableBytes];
    while (total < length) {
        ssize_t received = recv(tcp_sock, bytes + total, length - total, 0);
        if (received == -1) {
            if (errno == EINTR) continue;
            [NSError set: error
                  domain: @"TCPConnection"
                    code: 1
                  format: @"recv() failed: %s", strerror(errno)];
            [mutableData release];
            return nil;        
        }
        if (received == 0) {
            [NSError set: error
                  domain: @"TCPConnection"
                    code: 1
                  format: @"Reached end of stream"];
            [mutableData release];
            return nil;        
        }
        total += received;
    }
    return [mutableData autorelease];
}

-(void)close {
    if (!tcp_sock) {
        //TODO: Error Handling
        NSLog(@"Trying to close closed connection");
        exit(1);
    }
    close(tcp_sock);
    tcp_sock = 0;
}

@end
