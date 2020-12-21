//
//  SecureChannel.m
//  Oktett
//
//  Created by Jakob on 30.11.20.
//  Copyright 2020 __MyCompanyName__. All rights reserved.
//

#import "SecureChannel.h"
#import "TCPConnection.h"
#import "NSError+ConvenienceConstructors.h"
#import "sodium.h"


@implementation SecureChannel

-(BOOL)openChannelOverConnection:(TCPConnection*)conn error:(NSError**)error {
    NSMutableData *my_session_pk = [[[NSMutableData alloc] initWithLength:crypto_kx_PUBLICKEYBYTES] autorelease];
    unsigned char *my_session_sk = sodium_malloc(crypto_kx_SECRETKEYBYTES);
    
    crypto_kx_keypair([my_session_pk mutableBytes], my_session_sk);
    
    sodium_mprotect_noaccess(my_session_sk);
    
    if (![conn sendData:my_session_pk error:error]) {
        sodium_free(my_session_sk);
        return NO;
    }    
    NSData *other_session_pk = [conn receiveDataWithLength:crypto_kx_PUBLICKEYBYTES error:error];
    if (!other_session_pk) {
        sodium_free(my_session_sk);
        return NO;
    }

    unsigned char *rx_key = sodium_malloc(crypto_kx_SESSIONKEYBYTES);
    unsigned char *tx_key = sodium_malloc(crypto_kx_SESSIONKEYBYTES);
    
    sodium_mprotect_readonly(my_session_sk);

    BOOL isServer = memcmp([my_session_pk bytes], [other_session_pk bytes], [my_session_pk length]) > 0;
    int kx_status = (isServer ? crypto_kx_server_session_keys : crypto_kx_client_session_keys)(rx_key, tx_key, [my_session_pk bytes], my_session_sk, [other_session_pk bytes]);
    
    sodium_free(my_session_sk);

    if (kx_status != 0) {
        sodium_free(rx_key);
        sodium_free(tx_key);
        [NSError set:error domain:@"SecureChannel" code:1 format:@"Key exchange failed"];
        return NO;
    }
    
    sodium_mprotect_noaccess(rx_key);
    
    NSMutableData *tx_header = [[[NSMutableData alloc] initWithLength:crypto_secretstream_xchacha20poly1305_HEADERBYTES] autorelease];
    
    crypto_secretstream_xchacha20poly1305_init_push(&tx_state, [tx_header mutableBytes], tx_key);

    sodium_free(tx_key);
    
    if (![conn sendData:tx_header error:error]) {
        return NO;
    }
    
    NSData *rx_header = [conn receiveDataWithLength:crypto_secretstream_xchacha20poly1305_HEADERBYTES error:error];
    if (!rx_header) {
        return NO;
    }
    
    sodium_mprotect_readonly(rx_key);

    BOOL rx_status = crypto_secretstream_xchacha20poly1305_init_pull(&rx_state, [rx_header bytes], rx_key);

    sodium_free(rx_key);
    
    if (rx_status != 0) {
        [NSError set:error domain:@"SecureChannel" code:1 format:@"Key exchange failed"];
        return NO;
    }
    
    connection = [conn retain];
    
    // we've opened a secure channel with ephemeral keys
    // TODO: Authenticate the other end!
    return YES;
}

-(void)dealloc {
    [connection retain];
    [super dealloc];
}

-(BOOL)sendPacket:(NSData *)data error:(NSError **)error {
    return [self sendPacket:data final:NO error:error];
}

-(BOOL)sendPacket:(NSData*)data final:(BOOL)final error:(NSError**)error {
    NSMutableData *encryptedPacket = [[NSMutableData alloc] initWithLength:[data length]+crypto_secretstream_xchacha20poly1305_ABYTES];
    int status = crypto_secretstream_xchacha20poly1305_push( 
        &tx_state,
        [encryptedPacket mutableBytes], NULL,
        [data bytes], [data length],
        NULL, 0,
        final ? crypto_secretstream_xchacha20poly1305_TAG_FINAL : crypto_secretstream_xchacha20poly1305_TAG_MESSAGE
    );
    if (status != 0) {
        [NSError set:error domain:@"SecureChannel" code:1 format:@"Encryption failed"];
        [encryptedPacket release];
        return NO;
    }
    BOOL didSend = [connection sendPacket:encryptedPacket error:error];
    [encryptedPacket release];
    return didSend;
}


-(NSData *)receivePacketWithMaxLength:(NSUInteger)maxLen error:(NSError **)error {
    return [self receivePacketWithMaxLength:maxLen final:NULL error:error];
}

-(NSData*)receivePacketWithMaxLength:(NSUInteger)maxLen final:(BOOL*)final error:(NSError**)error {
    NSData *encryptedPacket = [connection receivePacketWithMaxLength:maxLen+crypto_secretstream_xchacha20poly1305_ABYTES error:error];
    if (!encryptedPacket) {
        return nil;
    }
    if ([encryptedPacket length]<crypto_secretstream_xchacha20poly1305_ABYTES) {
        [NSError set:error domain:@"SecureChannel" code:1 format:@"Received invalid packet"];
        return nil;
    }
    NSMutableData *packet = [[[NSMutableData alloc] initWithLength:[encryptedPacket length]-crypto_secretstream_xchacha20poly1305_ABYTES] autorelease];
    unsigned char tag;
    int status = crypto_secretstream_xchacha20poly1305_pull(
        &rx_state,
        [packet mutableBytes], NULL,
        &tag,
        [encryptedPacket bytes], [encryptedPacket length],
        NULL, 0
    );
    if (status != 0) {
        [NSError set:error domain:@"SecureChannel" code:1 format:@"Decryption failed"];
        return NO;
    }
    if (final) *final = tag == crypto_secretstream_xchacha20poly1305_TAG_FINAL;
    return packet;
}


@end
