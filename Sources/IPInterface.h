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
