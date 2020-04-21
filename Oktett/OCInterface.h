//
//  OCInterface.h
//  Oktett
//
//  Created by Jakob on 19.04.20.
//  Copyright 2020 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "OCAddress.h"

@interface OCInterface : NSObject {
    NSString *name;
    OCAddress *addr;
    OCAddress *dstaddr;
}

@property(readonly) NSString *name;
@property(readonly) OCAddress *addr;
@property(readonly) OCAddress *dstaddr;

+(NSArray*)broadcastInterfacesWithError:(NSError**)error;


@end
