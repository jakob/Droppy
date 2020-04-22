//
//  OCQueryMessage.m
//  Oktett
//
//  Created by Jakob on 21.04.20.
//  Copyright 2020 __MyCompanyName__. All rights reserved.
//

#import "OCQueryMessage.h"
#import "NSError+ConvenienceConstructors.h"

@implementation OCQueryMessage

@synthesize minSupportedProtocol, maxSupportedProtocol;

-(id)init {
    self = [super init];
    if (self) {
        CFUUIDRef uuid = CFUUIDCreate(kCFAllocatorDefault);
        requestUUID = CFUUIDGetUUIDBytes(uuid);
        CFRelease(uuid);
    }
    return self;
}

+(NSData*)header {
    return [@"Oktett/Q" dataUsingEncoding:NSUTF8StringEncoding];
}

-(NSData*)data {
    NSMutableData *data = [[NSMutableData alloc] initWithCapacity:512];
    
    [data appendData:[OCQueryMessage header]];
    
    uint16_t u;
    
    u = htons(minSupportedProtocol);
    [data appendBytes:&u length:2];
    
    u = htons(maxSupportedProtocol);
    [data appendBytes:&u length:2];
    
    [data appendBytes:&requestUUID length:sizeof(requestUUID)];
    
    return [data autorelease];
}

+(OCQueryMessage*)messageFromData:(NSData*)data error:(NSError**)error {
    NSData *header = [[self class] header];
    if (data.length < [header length] + 4 + sizeof(CFUUIDBytes)) {
        [NSError set:error
              domain:@"OCMessage"
                code:OCMessageErrorNotRecognized
              format:@"Message too short for a query message"];
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
    
    OCQueryMessage *message = [[OCQueryMessage alloc] init];
    
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
    
    return [message autorelease];
}

-(CFUUIDRef)requestUUID {
    CFUUIDRef ref = CFUUIDCreateFromUUIDBytes(kCFAllocatorDefault, requestUUID);
    return (CFUUIDRef)[(id)ref autorelease];
}

-(void)setRequestUUID:(CFUUIDRef)newUUID {
    requestUUID = CFUUIDGetUUIDBytes(newUUID);
}

-(void)dealloc {
    [super dealloc];
}

@end
