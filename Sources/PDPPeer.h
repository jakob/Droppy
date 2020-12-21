#import <Foundation/Foundation.h>

@class IPAddress;
@class Ed25519PublicKey;

@interface PDPPeer : NSObject {
    BOOL supportsProtocolVersion1;
    BOOL supportsEd25519;
    NSString *deviceName;
    NSString *deviceModel;
    NSMutableArray *recentAddresses;
    Ed25519PublicKey *publicKey;
    uint16_t tcpListenPort;
}

@property BOOL supportsProtocolVersion1;
@property BOOL supportsEd25519;
@property(copy) NSString *deviceName;
@property(copy) NSString *deviceModel;
@property(readonly) NSArray *recentAddresses;
@property(retain) Ed25519PublicKey *publicKey;
@property uint16_t tcpListenPort;

-(void)addRecentAddress:(IPAddress*)address;

+(PDPPeer*)localPeer;

@end
