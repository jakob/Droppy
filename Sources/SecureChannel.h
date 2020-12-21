#import <Foundation/Foundation.h>
#import "TCPConnection.h"
#import "sodium.h"

@interface SecureChannel : NSObject {
    TCPConnection *connection;
    crypto_secretstream_xchacha20poly1305_state rx_state, tx_state;
}

-(BOOL)openChannelOverConnection:(TCPConnection*)conn error:(NSError**)error;
-(BOOL)sendPacket:(NSData*)data final:(BOOL)final error:(NSError**)error;
-(NSData*)receivePacketWithMaxLength:(NSUInteger)maxLen final:(BOOL*)final error:(NSError**)error;

@end
