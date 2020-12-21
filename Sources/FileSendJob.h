#import <Foundation/Foundation.h>

@class PDPPeer;

@interface FileSendJob : NSObject {
    PDPPeer *recipient;
    NSURL *url;
}

@property(copy) NSURL *url;
@property(retain) PDPPeer *recipient;
-(void)start;

@end
