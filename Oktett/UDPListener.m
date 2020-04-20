//
//  UDPListener.m
//  Oktett
//
//  Created by Jakob on 17.04.20.
//  Copyright 2020 __MyCompanyName__. All rights reserved.
//

#import "UDPListener.h"

#import <sys/types.h>
#import <sys/uio.h>
#import <sys/socket.h>
#import <sys/un.h>
#import <sys/select.h>
#import <sys/time.h>
#import <netdb.h>
#import <unistd.h>
#include <arpa/inet.h>

@implementation UDPListener

@synthesize delegate = _delegate;

-(id)initWithPort:(uint16_t)port
{
    self = [super init];
    if (self) {
        _port = port;
    }
    
    return self;
}

-(void)handleData:(NSData*)data fromIP:(NSString*)ip port:(uint16_t)port {
    [_delegate listener:self didReceiveData:data fromIP:ip port:port];
}



-(BOOL)startListeningWithError:(NSError**)error {
	struct sockaddr_in addr;
	bzero(&addr, sizeof addr);
	addr.sin_family = AF_INET;
	addr.sin_len = sizeof addr;
	addr.sin_port = htons(_port);
	inet_pton(AF_INET, "0.0.0.0", &addr.sin_addr);
	
	_sock = socket(PF_INET, SOCK_DGRAM, IPPROTO_UDP);
	if (_sock<0) {
		if (error) {
			*error = [NSError errorWithDomain: @"UDPListener"
                                         code: errno 
                                     userInfo: [NSDictionary dictionaryWithObjectsAndKeys:
                                                [NSString stringWithFormat:@"socket() failed: %s", strerror(errno)],
                                                NSLocalizedDescriptionKey,
                                                nil
                                                ]
                      ];
		}
		return NO;
	}
    
    int yes = 1;
    int sockoptResult = setsockopt(_sock, SOL_SOCKET, SO_REUSEADDR, &yes, sizeof yes);
    if (sockoptResult == -1) {
        if (error) {
			*error = [NSError errorWithDomain: @"UDPListener"
                                         code: errno 
                                     userInfo: [NSDictionary dictionaryWithObjectsAndKeys:
                                                [NSString stringWithFormat:@"setsockopt() failed: %s", strerror(errno)],
                                                NSLocalizedDescriptionKey,
                                                nil
                                                ]
                      ];
		}
		return NO;
    }

    sockoptResult = setsockopt(_sock, SOL_SOCKET, SO_REUSEPORT, &yes, sizeof yes);
    if (sockoptResult == -1) {
        if (error) {
			*error = [NSError errorWithDomain: @"UDPListener"
                                         code: errno 
                                     userInfo: [NSDictionary dictionaryWithObjectsAndKeys:
                                                [NSString stringWithFormat:@"setsockopt() failed: %s", strerror(errno)],
                                                NSLocalizedDescriptionKey,
                                                nil
                                                ]
                      ];
		}
		return NO;
    }

	
	int bindResult = bind(_sock, (struct sockaddr*)&addr, addr.sin_len);
	if (bindResult == -1) {
		if (error) {
			*error = [NSError errorWithDomain:@"UDPListener" 
                                         code:errno 
                                     userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                                   [NSString stringWithFormat:@"bind() failed: %s", strerror(errno)],
                                                                                   NSLocalizedDescriptionKey,
                                                                                   nil
                                                                                   ]];
		}
		close(_sock);
		return NO;
	}
    
    _sock_src = dispatch_source_create(
                                       DISPATCH_SOURCE_TYPE_READ,
                                       _sock,
                                       0,
                                       dispatch_get_main_queue()
                                       );
    dispatch_source_set_event_handler(_sock_src, ^(void) {
        char bytes[1024];
        
        struct sockaddr_in addr;
        socklen_t addrSize = sizeof addr;
        
        ssize_t recvBytes = recvfrom(_sock, bytes, sizeof bytes, 0, (struct sockaddr *)&addr, &addrSize);
        if (recvBytes == -1) {
            NSLog(@"recvfrom() failed %s", strerror(errno));
            exit(1);
        }
        
        NSData *data = [NSData dataWithBytes:bytes length:recvBytes];
        
        char inetAddr[INET_ADDRSTRLEN];
        inet_ntop(AF_INET, &addr.sin_addr, inetAddr, sizeof inetAddr);
        NSString *remoteAddr = [NSString stringWithUTF8String:inetAddr];

        [self handleData:data fromIP:remoteAddr port:ntohs(addr.sin_port)];
	});
    
    dispatch_resume(_sock_src);
    
    return YES;
}


- (void)dealloc
{
	if (_sock) close(_sock);
    if (_sock_src) dispatch_release(_sock_src);

    [super dealloc];
}

@end
