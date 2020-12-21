#import <Foundation/Foundation.h>
#import "sodium.h"
@class Ed25519PublicKey;

@interface Ed25519KeyPair : NSObject {
	uint8_t pk[crypto_sign_ed25519_PUBLICKEYBYTES];
	uint8_t sk[crypto_sign_ed25519_SECRETKEYBYTES];
}

@property(readonly) Ed25519PublicKey *publicKey;

-(NSData*)signatureForMessage:(NSData*)message error:(NSError**)error;
-(BOOL)saveAsGenericKeychainItemWithServiceName:(NSString*)serviceName accountName:(NSString*)accountName error: (NSError**)error;
+(Ed25519KeyPair*)keyPairFromKeychainWithServiceName:(NSString*)serviceName accountName:(NSString*)accountName error:(NSError**)error;

@end
