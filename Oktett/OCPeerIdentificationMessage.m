//
//  OCPeerIdentificationMessage.m
//  Oktett
//
//  Created by Jakob on 21.04.20.
//  Copyright 2020 __MyCompanyName__. All rights reserved.
//

#import "OCPeerIdentificationMessage.h"

#import "OCQueryMessage.h"
#import "NSError+ConvenienceConstructors.h"
#import "NSString+Additions.h"

@implementation OCPeerIdentificationMessage

@synthesize minSupportedProtocol;
@synthesize maxSupportedProtocol;
@synthesize deviceType;
@synthesize shortName;

-(id)init {
    self = [super init];
    if (self) {
        // init
    }
    return self;
}

+(NSData*)header {
    return [@"Oktett/I" dataUsingEncoding:NSUTF8StringEncoding];
}

-(NSData*)data {
    NSMutableData *data = [[NSMutableData alloc] initWithCapacity:512];
    
    [data appendData:[OCPeerIdentificationMessage header]];
    
    uint16_t u;
    
    u = htons(minSupportedProtocol);
    [data appendBytes:&u length:2];
    
    u = htons(maxSupportedProtocol);
    [data appendBytes:&u length:2];
    
    [data appendBytes:&requestUUID length:sizeof(requestUUID)];

    [data appendBytes:&peerUUID length:sizeof(peerUUID)];

    NSData *deviceTypeData = [deviceType dataUsingEncoding:NSUTF8StringEncoding maxEncodedLength:255];
    uint8_t deviceTypeLength = [deviceTypeData length];
    [data appendBytes:&deviceTypeLength length:1];
    [data appendData:deviceTypeData];

    NSData *truncatedNameData = [shortName dataUsingEncoding:NSUTF8StringEncoding maxEncodedLength:255];
    uint8_t truncatedNameLength = [truncatedNameData length];
    [data appendBytes:&truncatedNameLength length:1];
    [data appendData:truncatedNameData];

    return [data autorelease];
}

+(OCPeerIdentificationMessage*)messageFromData:(NSData*)data error:(NSError**)error {
    NSData *header = [[self class] header];
    if (data.length < [header length] + 4 + 2 * sizeof(CFUUIDBytes) + 2) {
        [NSError set:error
              domain:@"OCMessage"
                code:OCMessageErrorNotRecognized
              format:@"Message too short for an id message"];
        return nil;
    }
    
    const char *bytes = [data bytes];
    
    int offset = 0;
    
    if (memcmp(bytes, [header bytes], [header length])) {
        [NSError set:error
              domain:@"OCMessage"
                code:OCMessageErrorNotRecognized
              format:@"Message does not have correct header"];
        return nil;
    }
    
    OCPeerIdentificationMessage *message = [[OCPeerIdentificationMessage alloc] init];
    
    offset += [header length];
    
    uint16_t u;
    
    memcpy(&u, bytes+offset, 2);
    message.minSupportedProtocol = ntohs(u);
    offset += 2;
    
    memcpy(&u, bytes+offset, 2);
    message.maxSupportedProtocol = ntohs(u);
    offset += 2;
    
    CFUUIDBytes uuid_bytes;
    memcpy(&uuid_bytes, bytes+offset, sizeof(uuid_bytes));
    CFUUIDRef uuid = CFUUIDCreateFromUUIDBytes(kCFAllocatorDefault, uuid_bytes);
    message.requestUUID = uuid;
    CFRelease(uuid);
    offset += sizeof(uuid_bytes);
    
    memcpy(&uuid_bytes, bytes+offset, sizeof(uuid_bytes));
    uuid = CFUUIDCreateFromUUIDBytes(kCFAllocatorDefault, uuid_bytes);
    message.peerUUID = uuid;
    CFRelease(uuid);
    offset += sizeof(uuid_bytes);

    uint8_t namelen;
    memcpy(&namelen, bytes+offset, 1);
    offset += 1;
    
    if (namelen + offset > data.length - 1) {
        [message release];
        [NSError set:error
              domain:@"OCMessage"
                code:OCMessageErrorInvalid
              format:@"Message too short for device type"];
        return nil;
    }
    
    NSString *deviceType = [[NSString alloc] initWithBytes:bytes+offset length:namelen encoding:NSUTF8StringEncoding];
    offset += namelen;
    message.deviceType = deviceType;
    [deviceType release];
    
    memcpy(&namelen, bytes+offset, 1);
    offset += 1;
    
    if (namelen + offset > data.length) {
        [message release];
        [NSError set:error
              domain:@"OCMessage"
                code:OCMessageErrorInvalid
              format:@"Message too short for name"];
        return nil;
    }
    
    NSString *shortName = [[NSString alloc] initWithBytes:bytes+offset length:namelen encoding:NSUTF8StringEncoding];
    offset += namelen;
    message.shortName = shortName;
    [shortName release];

    return [message autorelease];
}

-(CFUUIDRef)requestUUID {
    CFUUIDRef ref = CFUUIDCreateFromUUIDBytes(kCFAllocatorDefault, requestUUID);
    return (CFUUIDRef)[(id)ref autorelease];
}

-(void)setRequestUUID:(CFUUIDRef)newUUID {
    requestUUID = CFUUIDGetUUIDBytes(newUUID);
}

-(CFUUIDRef)peerUUID {
    CFUUIDRef ref = CFUUIDCreateFromUUIDBytes(kCFAllocatorDefault, peerUUID);
    return (CFUUIDRef)[(id)ref autorelease];
}

-(void)setPeerUUID:(CFUUIDRef)newUUID {
    peerUUID = CFUUIDGetUUIDBytes(newUUID);
}

-(void)dealloc {
	[deviceType release];
	[shortName release];
    [super dealloc];
}

@end
