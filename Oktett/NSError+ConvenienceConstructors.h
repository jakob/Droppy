//
//  NSError+ConvenienceConstructors.h
//  Oktett
//
//  Created by Jakob on 19.04.20.
//  Copyright 2020 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


enum OktettError {
    OktettErrorUDPSender = 5000,
};



@interface NSError (NSError_ConvenienceConstructors)

+(void)set:(NSError**)error domain:(NSString *)domain code:(NSInteger)code format:(NSString*)format, ... NS_FORMAT_FUNCTION(4,5);

+(NSError*)errorWithDomain:(NSString *)domain code:(NSInteger)code localizedDescriptionFormat:(NSString*)format, ... NS_FORMAT_FUNCTION(3,4);

@end
