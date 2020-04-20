//
//  NSError+ConvenienceConstructors.m
//  Oktett
//
//  Created by Jakob on 19.04.20.
//  Copyright 2020 __MyCompanyName__. All rights reserved.
//

#import "NSError+ConvenienceConstructors.h"


@implementation NSError (NSError_ConvenienceConstructors)

+(void)set:(NSError**)error domain:(NSString *)domain code:(NSInteger)code format:(NSString*)format, ... {
    if (error) {
        va_list args;
        va_start(args, format);
        NSString *localizedDescription = [[NSString alloc] initWithFormat:format arguments:args];
        va_end(args);
        NSDictionary *userInfo = [[NSDictionary alloc] initWithObjectsAndKeys:localizedDescription, NSLocalizedDescriptionKey, nil];
        [localizedDescription release];
        *error = [NSError errorWithDomain:domain code:code userInfo:userInfo];
        [userInfo release];
    }
}

+(NSError*)errorWithDomain:(NSString *)domain code:(NSInteger)code localizedDescriptionFormat:(NSString*)format, ... {
    va_list args;
    va_start(args, format);
    NSString *localizedDescription = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    NSDictionary *userInfo = [[NSDictionary alloc] initWithObjectsAndKeys:localizedDescription, NSLocalizedDescriptionKey, nil];
    [localizedDescription release];
    NSError *error = [[NSError alloc] initWithDomain:domain code:code userInfo:userInfo];
    [userInfo release];
    return [error autorelease];
}

@end
