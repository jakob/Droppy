//
//  NSData+EncodingHelpers.h
//  Oktett
//
//  Created by Jakob on 28.11.20.
//  Copyright 2020 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSData (NSData_EncodingHelpers)

-(NSString*)fast_hex;
-(NSString*)sodium_base64;

@end
