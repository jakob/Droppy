#import "UDPMessenger.h"

#import "NSError+ConvenienceConstructors.h"
#import "IPInterface.h"

@implementation UDPMessenger

-(void)dealloc {
    if (udp_sock) close(udp_sock);
    if (udp_sock_src) dispatch_release(udp_sock_src);
    [super dealloc];
}

-(BOOL)bindUDPPort:(uint16_t)port delegate:(id<UDPMessengerDelegate>)delegate error:(NSError **)error {
    // ensure that we don't try to connect twice
    if (udp_sock) {
        [NSError set: error
              domain: @"UDPMessenger"
                code: 1
              format: @"Can't bind to port: messenger already bound."];
        return NO;        
    }
    
    struct sockaddr_in bindaddr;
    bindaddr.sin_len = sizeof(bindaddr);
    bindaddr.sin_family = AF_INET;
    bindaddr.sin_addr.s_addr = INADDR_ANY;
    bindaddr.sin_port = htons(port);
    
    // create a socket
    int sock = socket(PF_INET, SOCK_DGRAM, IPPROTO_UDP);
    if (sock == -1) {
        [NSError set: error
              domain: @"UDPMessenger"
                code: 1
              format: @"socket() failed: %s", strerror(errno)];
        return NO;        
    }
    
    // configure the socket for broadcast mode
    int yes = 1;
    if (-1 == setsockopt(sock, SOL_SOCKET, SO_BROADCAST, &yes, sizeof yes)) {
        [NSError set: error
              domain: @"UDPMessenger"
                code: 1
              format: @"setsockopt() failed: %s", strerror(errno)];
        close(sock);
        return NO;
    }
    
    // bind the socket to the local port and address
    if (-1 == bind(sock, (struct sockaddr*)&bindaddr, sizeof(bindaddr))) {
        [NSError set: error
              domain: @"UDPMessenger"
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
        NSMutableData *data = [[NSMutableData alloc] initWithLength:4096];
        IPAddress *srcaddr = [[IPAddress alloc] init];
        socklen_t sa_len = srcaddr.maxlen;
        ssize_t recvBytes = recvfrom(udp_sock, [data mutableBytes], [data length], 0, srcaddr.addr, &sa_len);
        if (recvBytes == -1) {
            // TODO: Add proper error handling
            NSLog(@"recvfrom() failed %s", strerror(errno));
            exit(1);
        }
        [data setLength:recvBytes];
        [delegate messenger:self didReceiveData:data from:srcaddr];
        [data release];
        [srcaddr release];
	});
    dispatch_resume(udp_sock_src);
    
    return YES;
}

-(BOOL)broadcastMessage:(NSData*)message port:(uint16_t)port error:(NSError**)error {
    
    // ensure that socket is bound to a local port
    if (!udp_sock) {
        [NSError set: error
              domain: @"UDPMessenger"
                code: 1
              format: @"Must bind UDP socket before ssend."];
        return NO;        
    }
    
    NSArray *interfaces = [IPInterface broadcastInterfacesWithError:error];
    if (!interfaces) return NO;
    
    // Make sure there is at least one network interface
    if (![interfaces count]) {
        [NSError set: error
              domain: @"UDPMessenger"
                code: 1
              format: @"No network interfaces found."];
        return NO;        
    }
    
    // send the message on all interfaces
    NSMutableArray *errors = [[NSMutableArray alloc] initWithCapacity:[interfaces count]];
    for (IPInterface *interface in interfaces) {
        IPAddress *destination = [interface.dstaddr copy];
        destination.port = port;
        // send the message
        NSError *sendError = nil;
        if (![self sendMessage:message to:destination error:&sendError]) {
            [errors addObject:sendError];
        }
        [destination release];
    }
    if ([errors count]) {
        // return first error
        if (error) {
            *error = [[[errors objectAtIndex:0] retain] autorelease];
        }
        [errors release];
        return NO;
    }
    
    [errors release];
    return YES;
}

-(BOOL)sendMessage:(NSData *)message to:(IPAddress *)address error:(NSError **)error {
    ssize_t sent_bytes = sendto(udp_sock, message.bytes, message.length, 0, address.addr, address.len);
    if (sent_bytes == -1) {
        [NSError set:error domain:@"IPInterface"
                code: 1
              format: @"send() failed: %s", strerror(errno)];
        return NO;
    }
    else if (sent_bytes < message.length) {
        [NSError set:error domain:@"IPInterface"
                code: 1
              format: @"send() sent only %d of %d bytes", (int)sent_bytes, (int)message.length];
        return NO;
    }
    return YES;
}

@end
