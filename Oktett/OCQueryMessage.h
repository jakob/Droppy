//
//  OCQueryMessage.h
//  Oktett
//
//  Created by Jakob on 21.04.20.
//  Copyright 2020 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

enum OCMessageError {
    OCMessageErrorNotRecognized = 99090,
    OCMessageErrorInvalid = 99091
};

@interface OCQueryMessage : NSObject {
    uint16_t minSupportedProtocol;
    uint16_t maxSupportedProtocol;
    CFUUIDBytes requestUUID;
}

@property uint16_t minSupportedProtocol;
@property uint16_t maxSupportedProtocol;
@property CFUUIDRef requestUUID;

-(NSData*)data;
+(OCQueryMessage*)messageFromData:(NSData*)data error:(NSError**)error;

@end
