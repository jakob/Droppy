#import "TCPServer.h"

#import "NSError+ConvenienceConstructors.h"

@implementation TCPServer

-(void)dealloc {
    if (listen_sock) close(listen_sock);
    if (listen_sock_src) dispatch_release(listen_sock_src);
    [super dealloc];
}

-(BOOL)listenOnRandomPortWithDelegate:(id<TCPServerDelegate>)delegate error:(NSError**)error {
    return [self listenOnPort:0 delegate:delegate error:error];
}

-(BOOL)listenOnPort:(uint16_t)port delegate:(id<TCPServerDelegate>)delegate error:(NSError **)error {
    // ensure that we don't try to listen twice
    if (listen_sock) {
        [NSError set: error
              domain: @"TCPServer"
                code: 1
              format: @"Can't listen on port: server already bound."];
        return NO;        
    }

    struct sockaddr_in bindaddr;
    bindaddr.sin_len = sizeof(bindaddr);
    bindaddr.sin_family = AF_INET;
    bindaddr.sin_addr.s_addr = INADDR_ANY;
    bindaddr.sin_port = htons(port);

    // create a socket
    int sock = socket(PF_INET, SOCK_STREAM, IPPROTO_TCP);
    if (sock == -1) {
        [NSError set: error
              domain: @"TCPServer"
                code: 1
              format: @"socket() failed: %s", strerror(errno)];
        return NO;        
    }
    
    // bind the socket to the local port and address
    if (-1 == bind(sock, (struct sockaddr*)&bindaddr, sizeof(bindaddr))) {
        [NSError set: error
              domain: @"TCPServer"
                code: 1
              format: @"bind() failed: %s", strerror(errno)];
        close(sock);
        return NO;
    }
    
    // if we bound to port 0 (random port), we need to get the port with getsockname()
    if (!port) {
        socklen_t bindaddr_len = sizeof(bindaddr);
        if (-1 == getsockname(sock, (struct sockaddr*)&bindaddr, &bindaddr_len)) {
            [NSError set: error
                  domain: @"TCPServer"
                    code: 1
                  format: @"getsockname() failed: %s", strerror(errno)];
            close(sock);
            return NO;
        }
        port = ntohs(bindaddr.sin_port);
    }
    
    // listen for incoming connections
    if (-1 == listen(sock, 999)) {
        [NSError set: error
              domain: @"TCPServer"
                code: 1
              format: @"listen() failed: %s", strerror(errno)];
        close(sock);
        return NO;
    }
    
    listen_sock = sock;
    listen_port = port;
    
    // send incoming packets to delegate
    listen_sock_src = dispatch_source_create( 
                                          DISPATCH_SOURCE_TYPE_READ,
                                          listen_sock,
                                          0 /* unused */,
                                          dispatch_get_main_queue()
                                          );
    
    dispatch_source_set_event_handler(listen_sock_src, ^(void) {
        struct sockaddr_storage addr_storage;
        struct sockaddr *addr = (struct sockaddr *)&addr_storage;
        socklen_t addrlen = sizeof(addr);
        int sock = accept(listen_sock, addr, &addrlen);
        if (sock == -1) {
            // TODO: Handle error gracefully!
            NSLog(@"accept() failed: %s", strerror(errno));
            exit(1);
        }
        IPAddress *address = [[IPAddress alloc] initWithSockaddr:addr];
        TCPConnection *connection = [[TCPConnection alloc] initWithSocket:sock remoteAddress:address];
        [delegate server:self didAcceptConnection:connection];
        [address release];
        [connection release];
	});
    dispatch_resume(listen_sock_src);
    
    return YES;
}

-(uint16)port {
    return listen_port;
}

@end
