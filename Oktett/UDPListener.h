//
//  UDPListener.h
//  Oktett
//
//  Created by Jakob on 17.04.20.
//  Copyright 2020 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class UDPListener;

@protocol UDPListenerDelegate <NSObject>

-(void)listener:(UDPListener*)c
     didReceiveData:(NSData*)data
             fromIP:(NSString*)ip
               port:(uint16_t)port;

@end

@interface UDPListener : NSObject {
    uint16_t _port;
    int _sock;
    dispatch_source_t _sock_src;
    id<UDPListenerDelegate> _delegate;
}

@property(assign) id<UDPListenerDelegate> delegate;

-(id)initWithPort:(uint16_t)port;
-(BOOL)startListeningWithError:(NSError**)error;

@end
