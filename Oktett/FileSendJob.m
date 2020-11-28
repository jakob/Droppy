//
//  FileSendJob.m
//  Oktett
//
//  Created by Jakob on 28.11.20.
//  Copyright 2020 __MyCompanyName__. All rights reserved.
//

#import "FileSendJob.h"
#import "TCPConnection.h"
#import "PDPPeer.h"
#import "KVPMutableDictionary.h"
#include <sys/stat.h>
#import "NSError+ConvenienceConstructors.h"

@implementation FileSendJob

@synthesize url;
@synthesize recipient;

-(void)start {    
    NSError *error = nil;
    
    // Try opening the file
    int fd = open([[url path] fileSystemRepresentation], O_RDONLY);
    if (fd==-1) {
        [NSError set:&error 
              domain:@"FileSendJob" 
                code:1
              format:@"open() failed: %s", strerror(errno)];
        [NSApp presentError:error];
        return;
    }
    
    // Get file properties
    struct stat statres;    
    if (-1==fstat(fd, &statres)) {
        [NSError set:&error 
              domain:@"FileSendJob" 
                code:1
              format:@"fstat() failed: %s", strerror(errno)];
        close(fd);
        [NSApp presentError:error];
        return;
    }
    
    // Create file metadata dictionary
    KVPMutableDictionary *dict = [[[KVPMutableDictionary alloc] init] autorelease];
    if (![dict setString:[[url lastPathComponent] stringByDeletingPathExtension] forStringKey:@"basename" error:&error]) {
        close(fd);
        [NSApp presentError:error];
        return;
    }
    if (![dict setString:[url pathExtension] forStringKey:@"extension" error:&error]) {
        close(fd);
        [NSApp presentError:error];
        return;
    }
    if (![dict setUInt64:statres.st_size forStringKey:@"size" error:&error]) {
        close(fd);
        [NSApp presentError:error];
        return;
    }
    // send mtime only if it isn't negative (We want to be ready for the 32bit Y2k38 problem...)
    if (statres.st_mtimespec.tv_sec > 0) {
        uint64_t mtime_nano = 1000000000*statres.st_mtimespec.tv_sec + statres.st_mtimespec.tv_nsec;
        if (![dict setUInt64:mtime_nano forStringKey:@"mtime_nano" error:&error]) {
            close(fd);
            [NSApp presentError:error];
            return;
        }
    }
    
    // open a connection to the recipient
    TCPConnection *connection = [TCPConnection connectTo:[recipient.recentAddresses lastObject] error:&error];
    if (!connection) {
        close(fd);
        [NSApp presentError:error];
        return;
    }
    
    // send file metadata
    if (![connection sendPacket:dict.data error:&error]) {
        close(fd);
        [NSApp presentError:error];
        return;
    }
    
    // read file in 1MB chunks and send them
    int chunksize = 1024*1024;
    char *buffer = malloc(chunksize+1);
    *buffer = 'D';
    int bytesread;
    while ((bytesread = read(fd, buffer+1, chunksize))) {
        if (bytesread == -1) {
            if (errno==EINTR) continue;
            [NSError set:&error 
                  domain:@"FileSendJob" 
                    code:1
                  format:@"read() failed: %s", strerror(errno)];
            close(fd);
            [NSApp presentError:error];
            return;
        }
        NSData *packet = [NSData dataWithBytes:buffer length:bytesread+1];
        if (![connection sendPacket:packet error:&error]) {
            close(fd);
            [NSApp presentError:error];
            return;
        }
    }
    
    close(fd);

    // we're done! send a zero length packet to confirm
    if (![connection sendPacket:[NSData data] error:&error]) {
        [NSApp presentError:error];
        return;
    }
}

@end
