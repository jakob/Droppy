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

@end
