#import <Foundation/Foundation.h>

#import "IPAddress.h"

@interface TCPConnection : NSObject {
    int tcp_sock;
    IPAddress* remoteAddress;
}

@property(readonly) IPAddress* remoteAddress;

-(id)initWithSocket:(int)sock remoteAddress:(IPAddress*)address;

+(TCPConnection*)connectTo:(IPAddress*)address error:(NSError**)outError;

-(BOOL)sendData:(NSData*)data error:(NSError**)outError;
-(NSData*)receiveDataWithLength:(NSUInteger)length error:(NSError**)outError;

-(BOOL)sendPacket:(NSData*)data error:(NSError**)error;
-(NSData*)receivePacketWithMaxLength:(NSUInteger)maxLen error:(NSError**)error;

-(void)close;

@end
