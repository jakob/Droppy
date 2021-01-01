#import <Foundation/Foundation.h>
#import "sodium.h"


@interface Ed25519PublicKey : NSObject {
	uint8_t pk[crypto_sign_ed25519_PUBLICKEYBYTES];
}

@property(readonly) NSData *data;
@property(readonly) NSString *stringRepresentation;

+(Ed25519PublicKey*)publicKeyWithData:(NSData*)data error:(NSError**)error;
+(Ed25519PublicKey*)publicKeyWithStringRepresentation:(NSString*)str error:(NSError**)error;

-(BOOL)verifySignature:(NSData*)sig forMessage:(NSData*)message error:(NSError**)error;

@end
