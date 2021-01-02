#import <Foundation/Foundation.h>
#import "Ed25519PublicKey.h"
#import "Ed25519KeyPair.h"

typedef enum {
    PDPMessageTypeAnnounce = 'A',
    PDPMessageTypeScan = 'S'
} PDPMessageType;

@interface PDPMessage : NSObject {
    PDPMessageType messageType;
    BOOL supportsUnencryptedConnection;
    BOOL supportsEncryptedConnectionV1;
    NSString *deviceName;
    NSString *deviceModel;
    NSData *requestToken;
    Ed25519PublicKey *publicKey;
    uint16_t tcpListenPort;
}

@property PDPMessageType messageType; 
@property BOOL supportsUnencryptedConnection;
@property BOOL supportsEncryptedConnectionV1;
@property(copy) NSString *deviceName;
@property(copy) NSString *deviceModel;
@property(copy) NSData *requestToken;
@property(retain) Ed25519PublicKey *publicKey;
@property uint16_t tcpListenPort;

-(NSData *)dataSignedWithKeyPair:(Ed25519KeyPair*)keyPair error:(NSError**)error;
+(PDPMessage*)messageFromData:(NSData*)data error:(NSError**)error;

@end
