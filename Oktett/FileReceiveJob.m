//
//  FileReceiveJob.m
//  Oktett
//
//  Created by Jakob on 28.11.20.
//  Copyright 2020 __MyCompanyName__. All rights reserved.
//

#import "FileReceiveJob.h"

#import "TCPConnection.h"
#import "KVPDictionary.h"
#import "NSError+ConvenienceConstructors.h"

@implementation FileReceiveJob

-(BOOL)presentError:(NSError*)error {
    [NSApp performSelectorOnMainThread:@selector(presentError:) withObject:error waitUntilDone:NO];
    return NO;
}

-(void)receiveFileInBackgroundFromConnection:(TCPConnection*)connection {
    [self performSelectorInBackground:@selector(receiveFileFromConnection:) withObject:connection];
}

-(void)receiveFileFromConnection:(TCPConnection*)connection {
    NSError *error = nil;
    
    // Try to get file metadata
    NSData *metadata = [connection receivePacketWithMaxLength:5000 error:&error];
    if (!metadata) {
        [self presentError:error];
        return;
    }
    KVPDictionary *dict = [KVPDictionary dictionaryFromData:metadata error:&error];
    if (!dict) {
        [self presentError:error];
        return;
    }
    
    
    NSURL *url = [NSURL fileURLWithPath:NSTemporaryDirectory()];
    
    NSString *basename = [dict stringForStringKey:@"basename"];
    if ([basename length]==0) basename = @"received_file";
    url = [url URLByAppendingPathComponent:basename];
    
    NSString *extension = [dict stringForStringKey:@"extension"];
    if ([extension length]) url = [url URLByAppendingPathExtension:extension];
    
    // Try opening the file
    int fd = open([[url path] fileSystemRepresentation], O_WRONLY|O_CREAT|O_EXCL);
    if (fd==-1) {
        [NSError set:&error 
              domain:@"FileReceiveJob" 
                code:1
              format:@"open() failed: %s", strerror(errno)];
        [self presentError:error];
        return;
    }
    
    NSData *data;
    
    while ((data = [connection receivePacketWithMaxLength:10*1024*1024 error:&error])) {
        if ([data length] == 0) {
            close(fd);
            // we're done!
            [[NSWorkspace sharedWorkspace] activateFileViewerSelectingURLs:[NSArray arrayWithObject:url]];
            return;
        }
        char packetType = *(char*)[data bytes];
        if (packetType != 'D') {
            [NSError set:&error 
                  domain:@"FileReceiveJob" 
                    code:1
                  format:@"Invalid packet type: %c", packetType];
            close(fd);
            [self presentError:error];
            return;
        }
        const void *payload = [data bytes]+1;
        int payload_len = [data length] - 1;
        int written = write(fd, payload, payload_len);
        if (written==-1) {
            [NSError set:&error 
                  domain:@"FileSendJob" 
                    code:1
                  format:@"write() failed: %s", strerror(errno)];
            close(fd);
            [self presentError:error];
            return;
        }
        if (written!=payload_len) {
            [NSError set:&error 
                  domain:@"FileSendJob" 
                    code:1
                  format:@"Short write(): %d written of %d bytes", written, payload_len];
            close(fd);
            [self presentError:error];
            return;
        }
    }
    [self presentError:error];
}

@end
