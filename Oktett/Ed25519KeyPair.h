//
//  Ed25519KeyPair.h
//  Oktett
//
//  Created by Jakob Egger on 2020-04-28.
//

#import <Foundation/Foundation.h>
#import "sodium.h"
@class Ed25519PublicKey;

@interface Ed25519KeyPair : NSObject {
	uint8_t pk[crypto_sign_ed25519_PUBLICKEYBYTES];
	uint8_t sk[crypto_sign_ed25519_SECRETKEYBYTES];
}

@property(readonly) Ed25519PublicKey *publicKey;

-(NSData*)signatureForMessage:(NSData*)message;
-(BOOL)saveAsGenericKeychainItemWithServiceName:(NSString*)serviceName accountName:(NSString*)accountName error: (NSError**)error;
+(Ed25519KeyPair*)keyPairFromKeychainWithServiceName:(NSString*)serviceName accountName:(NSString*)accountName error:(NSError**)error;
+(Ed25519KeyPair*)currentDeviceKeyPair;

@end
