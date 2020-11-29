//
//  FileReceiveJob.h
//  Oktett
//
//  Created by Jakob on 28.11.20.
//  Copyright 2020 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class TCPConnection;

@interface FileReceiveJob : NSObject {
    
}

-(void)receiveFileInBackgroundFromConnection:(TCPConnection*)connection;
-(NSURL*)moveURLToDownloads:(NSURL*)url basename:(NSString*)basename extension:(NSString*)extension error:(NSError**)error;

@end
