#import <Foundation/Foundation.h>

@class TCPConnection;

@interface FileReceiveJob : NSObject {
    
}

-(void)receiveFileInBackgroundFromConnection:(TCPConnection*)connection;
-(NSURL*)moveURLToDownloads:(NSURL*)url basename:(NSString*)basename extension:(NSString*)extension error:(NSError**)error;

@end
