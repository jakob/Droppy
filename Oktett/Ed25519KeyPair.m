//
//  Ed25519KeyPair.m
//  Oktett
//
//  Created by Jakob Egger on 2020-04-28.
//

#import <Security/Security.h>
#import "Ed25519KeyPair.h"
#import "Ed25519PublicKey.h"
#import "NSError+ConvenienceConstructors.h"

@implementation Ed25519KeyPair

-(id)init {
	self = [super init];
	if (self) {
		crypto_sign_ed25519_keypair(pk, sk);
	}
	return self;
}

-(id)initWithoutKey {
	self = [super init];
	return self;
}

-(Ed25519PublicKey*)publicKey {
	NSData *data = [[NSData alloc] initWithBytes:pk length:crypto_sign_ed25519_PUBLICKEYBYTES];
    NSError *publicKeyMakeError = nil;
	Ed25519PublicKey *publicKey = [Ed25519PublicKey publicKeyWithData:data error:&publicKeyMakeError];
    if (!publicKey) {
        NSLog(@"Could not make public key: %@", publicKeyMakeError);
        exit(1);
    }
	[data release];
	return publicKey;
}

-(NSData*)signatureForMessage:(NSData*)message error:(NSError**)error {
	uint8_t sig[crypto_sign_ed25519_BYTES];
    int status = crypto_sign_detached(sig, NULL, message.bytes, message.length, sk);
	if (status != 0) {
        [NSError set:error
              domain:@"Ed25519"
                code:1
              format:@"Message signing failed (status code %d).", status];
        return nil;
    }
	return [NSData dataWithBytes:sig length:crypto_sign_ed25519_BYTES];
}

-(BOOL)saveAsGenericKeychainItemWithServiceName:(NSString*)serviceName accountName:(NSString*)accountName error: (NSError**)error {
	OSStatus status = SecKeychainAddGenericPassword(
		NULL /* Default Keychain */,
		(UInt32)[serviceName lengthOfBytesUsingEncoding:NSUTF8StringEncoding], [serviceName UTF8String],
		(UInt32)[accountName lengthOfBytesUsingEncoding:NSUTF8StringEncoding], [accountName UTF8String],
		sizeof(sk), sk, 
		NULL /* We don't need the resulting keychain item */
	);
	if (status != errSecSuccess) {
		CFStringRef errorMessage = SecCopyErrorMessageString(status, NULL);
		[NSError set: error
			  domain: @"Security"
				code: status
			  format: @"Could not save private key to keychain because: %@", errorMessage];
		CFRelease(errorMessage);
		return NO;
	}
	return YES;
}

+(Ed25519KeyPair*)keyPairFromKeychainWithServiceName:(NSString*)serviceName accountName:(NSString*)accountName error:(NSError**)error {
	UInt32 pwLength = 0;
	void *pw = nil;
	OSStatus status = SecKeychainFindGenericPassword(
		NULL /* Default Keychain */,
		(UInt32)[serviceName lengthOfBytesUsingEncoding:NSUTF8StringEncoding], [serviceName UTF8String],
		(UInt32)[accountName lengthOfBytesUsingEncoding:NSUTF8StringEncoding], [accountName UTF8String],
		&pwLength, &pw,
		NULL /* We don't need the keychain item itself, only the password */
	);
	if (status != errSecSuccess) {
		if (pw) SecKeychainItemFreeContent(NULL, pw);
		CFStringRef errorMessage = SecCopyErrorMessageString(status, NULL);
		[NSError set: error
			  domain: @"Security"
				code: status
			  format: @"Could not get private key because: %@", errorMessage];
		CFRelease(errorMessage);
		return NO;
	}
	if (pwLength != crypto_sign_ed25519_SECRETKEYBYTES) {
		if (pw) SecKeychainItemFreeContent(NULL, pw);
		[NSError set: error
			  domain: @"Ed25519"
				code: 1
			  format: @"Secret key had unexpected length (expected %d, got %d))", crypto_sign_ed25519_SECRETKEYBYTES, pwLength];
		return NO;
	}
	
	Ed25519KeyPair *keyPair = [[Ed25519KeyPair alloc] initWithoutKey];
	
	memcpy(keyPair->sk, pw, crypto_sign_ed25519_SECRETKEYBYTES);
	SecKeychainItemFreeContent(NULL, pw);
	
	int convert_status = crypto_sign_ed25519_sk_to_pk(keyPair->pk, keyPair->sk);
	if (convert_status != 0) {
		[keyPair release];
		[NSError set: error
			  domain: @"Ed25519"
				code: 1
			  format: @"Could not convert secret key to public key (status code %d)", convert_status];
		return NO;
	}
	
	return [keyPair autorelease];
}

+(Ed25519KeyPair*)currentDeviceKeyPair {
    static Ed25519KeyPair *keyPair;
    if (keyPair) return keyPair;
    // First check if we already have an accound name
    NSString *accountName = [[NSUserDefaults standardUserDefaults] stringForKey:@"DeviceAccountName"];
    if (accountName) {
        // try to get the key pair from the key chain
        NSError *error = nil;
        keyPair = [[self keyPairFromKeychainWithServiceName:@"OktettPeerDiscoveryKey" accountName:accountName error:&error] retain];
        if (keyPair) return keyPair;
        
        // we couldn't get the key pair from the keychain (not found or no permission)
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:@"Could not read device key"];
        [alert setInformativeText:[NSString stringWithFormat:@"%@\n\nYou can generate a new key, but then your device will appear like an unknown device to others.", error.localizedDescription]];
        [alert addButtonWithTitle:@"Quit"];
        [alert addButtonWithTitle:@"Generate New Key"];
        NSInteger result = [alert runModal];
        [alert release];
        if (result == NSAlertFirstButtonReturn) {
            exit(0);
        }
    }
    
    // We need to generate a key!
    accountName = [NSString stringWithFormat:@"Device%08X%08X", randombytes_random(), randombytes_random()];
    keyPair = [[Ed25519KeyPair alloc] init];
    NSError *keychainAddError = nil;
    if ([keyPair saveAsGenericKeychainItemWithServiceName:@"OktettPeerDiscoveryKey" accountName:accountName error:&keychainAddError]) {
        NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
        [standardUserDefaults setObject:accountName forKey:@"DeviceAccountName"];
        // Make sure we don't forget the name of our newly generated key in case of crash
        [standardUserDefaults synchronize];
    } else {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:@"Could not save device key"];
        [alert setInformativeText:[NSString stringWithFormat:@"A newly generated device key could not be saved to the keychain because: %@.\n\nYou can continue, but this device will appear as an unknown device to others when you next start the app.", keychainAddError.localizedDescription]];
        [alert addButtonWithTitle:@"Quit"];
        [alert addButtonWithTitle:@"Continue"];
        NSInteger result = [alert runModal];
        [alert release];
        if (result == NSAlertFirstButtonReturn) {
            exit(0);
        }
    }
    return keyPair;
}

@end
