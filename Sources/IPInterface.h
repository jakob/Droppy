//
//  IPInterface.h
//  Oktett
//
//  Created by Jakob on 19.04.20.
//  Copyright 2020 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "IPAddress.h"

@interface IPInterface : NSObject {
    NSString *name;
    IPAddress *addr;
    IPAddress *dstaddr;
}

@property(readonly) NSString *name;
@property(readonly) IPAddress *addr;
@property(readonly) IPAddress *dstaddr;

+(NSArray*)broadcastInterfacesWithError:(NSError**)error;


@end
