//
//  Ed25519PublicKey.h
//  Oktett
//
//  Created by Jakob Egger on 2020-04-28.
//

#import <Foundation/Foundation.h>
#import "sodium.h"


@interface Ed25519PublicKey : NSObject {
	uint8_t pk[crypto_sign_ed25519_PUBLICKEYBYTES];
}

@property(readonly) NSData *data;

+(Ed25519PublicKey*)publicKeyWithData:(NSData*)data error:(NSError**)error;

-(BOOL)verifySignature:(NSData*)sig forMessage:(NSData*)message error:(NSError**)error;

@end
