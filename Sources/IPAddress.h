#import <Foundation/Foundation.h>

#include "sys/socket.h"
#include "arpa/inet.h"


@interface IPAddress : NSObject<NSCopying> {
    struct sockaddr_storage addr;
}

@property(readonly) struct sockaddr *addr;
@property(readonly) socklen_t len;
@property(readonly) socklen_t maxlen;
@property(readonly) NSString *presentationAddress;
@property uint16_t port;
@property(readonly) sa_family_t family;

-(id)initWithSockaddr:(struct sockaddr*)anAddr;

@end
