#import <Foundation/Foundation.h>

@class IPAddress;
@class Ed25519PublicKey;

@interface PDPPeer : NSObject {
    BOOL supportsProtocolVersion1;
    BOOL supportsEd25519;
    NSString *deviceName;
    NSString *deviceModel;
    NSMutableArray *recentAddresses;
    NSString *incomingTransferMode;
    Ed25519PublicKey *publicKey;
    uint16_t tcpListenPort;
    NSDictionary *dictionaryRepresentation;
}

@property BOOL supportsProtocolVersion1;
@property BOOL supportsEd25519;
@property BOOL acceptIncomingTransfers;
@property(copy) NSString *deviceName;
@property(copy) NSString *deviceModel;
@property(readonly) NSArray *recentAddresses;
@property(retain) Ed25519PublicKey *publicKey;
@property uint16_t tcpListenPort;
@property(readonly) NSString *mostRecentPresentationAddressAndPort;
@property(readonly) NSDictionary *dictionaryRepresentation;

-(void)addRecentAddress:(IPAddress*)address;

-(BOOL)setDictionaryRepresentation:(NSDictionary *)dict error:(NSError**)outError;

-(void)writeToUserDefaults;

+(PDPPeer*)localPeer;

@end
