//
//  PDPMessage.m
//  Oktett
//
//  Created by Jakob on 26.04.20.
//  Copyright 2020 __MyCompanyName__. All rights reserved.
//

#import "PDPMessage.h"
#import "KVPDictionary.h"
#import "KVPMutableDictionary.h"
#import "NSError+ConvenienceConstructors.h"
#import "NSString+Additions.h"

@implementation PDPMessage

@synthesize messageType;
@synthesize supportsProtocolVersion1;
@synthesize deviceName;
@synthesize deviceModel;
@synthesize requestToken;

-(void)dealloc{
	[deviceName release];
	[deviceModel release];
	[requestToken release];
	[super dealloc];
}

+(PDPMessage *)messageFromData:(NSData *)data error:(NSError **)error {
    
    // first check the header
    if (data.length < 5) {
        [NSError set:error
              domain:@"PDPMessage"
                code:1
              format:@"Message is too short."];
        return nil;
    }
    if (memcmp(data.bytes, "\03PDP", 4) != 0) {
        [NSError set:error
              domain:@"PDPMessage"
                code:1
              format:@"Message does not have PDP header."];
        return nil;
    }
    
    // Now try to parse the KVP dictionary
    KVPDictionary *dict = [KVPDictionary dictionaryFromData:data error:error];
    if (!dict) return nil;

    // Extract the PDP header data and ensure it has minimum length
    NSData *pdp = [dict dataForStringKey:@"PDP"];
    if (pdp.length < 2) {
        [NSError set:error
              domain:@"PDPMessage"
                code:1
              format:@"PDP Message header is too short."];
        return nil;
    }
    
    PDPMessage *message = [[PDPMessage alloc] init];
    
    // Parse the PDP header data
    const uint8_t *pdp_bytes = pdp.bytes;
    message.messageType = pdp_bytes[0];
    uint8_t flags = pdp_bytes[1];
    message.supportsProtocolVersion1 = flags & 0x01 ? YES : NO;
    
    // Extract optional fields
    message.deviceName = [dict stringForStringKey:@"N"];
    message.deviceModel = [dict stringForStringKey:@"M"];
    message.requestToken = [dict dataForStringKey:@"T"];
    
    return [message autorelease];
}


-(NSData *)data {
    KVPMutableDictionary *dict = [[KVPMutableDictionary alloc] init];
    
    // Write Header
    NSMutableData *pdp = [[NSMutableData alloc] initWithLength:2];
    uint8_t *pdp_bytes = pdp.mutableBytes;
    pdp_bytes[0] = self.messageType;
    if (self.supportsProtocolVersion1) pdp_bytes[1] |= 0x01;
    NSError *error = nil;
    if (![dict setData:pdp forStringKey:@"PDP" error:&error]) goto error;
    [pdp release];
    
    NSData *truncatedName = [self.deviceName dataUsingEncoding:NSUTF8StringEncoding maxEncodedLength:255];
    if (truncatedName) {
        if (![dict setData:truncatedName forStringKey:@"N" error:&error]) goto error;
    }
        
    NSData *truncatedModel = [self.deviceModel dataUsingEncoding:NSUTF8StringEncoding maxEncodedLength:255];
    if (truncatedModel) {
        if (![dict setData:truncatedModel forStringKey:@"M" error:&error]) goto error;
    }
    
    if (self.requestToken) {
        if (![dict setData:self.requestToken forStringKey:@"T" error:&error]) goto error;
    }
    
    NSData *data = [dict data];
    [dict release];
    
    return data;
    
error:
    NSLog(@"Unexpected error in [PDPMessage data]: %@", error);
    exit(1);
}


@end
