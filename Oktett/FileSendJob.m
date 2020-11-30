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
#import "SecureChannel.h"

@interface FileSendJob() {
}
-(BOOL)sendFileFromFileDescriptor:(int)fd metadata:(KVPDictionary*)metadata error:(NSError**)error;
@end

@implementation FileSendJob

@synthesize url;
@synthesize recipient;

-(void)start {
    [self performSelectorInBackground:@selector(doWork) withObject:nil];
}

-(void)doWork {
    NSError *error = nil;
    BOOL didSend = NO;
    
    NSAutoreleasePool *threadPool = [[NSAutoreleasePool alloc] init];
    
    NSNumber *isDir;
    if (![url getResourceValue:&isDir forKey:NSURLIsDirectoryKey error:&error]) {
        [NSApp performSelectorOnMainThread:@selector(presentError:) withObject:error waitUntilDone:NO];
        [threadPool drain];
        return;
    }
    
    if ([isDir boolValue]) {
        // Create file metadata dictionary
        KVPMutableDictionary *dict = [[[KVPMutableDictionary alloc] init] autorelease];
        if (![dict setString:[[url lastPathComponent] stringByDeletingPathExtension] forStringKey:@"basename" error:&error]) {
            [NSApp performSelectorOnMainThread:@selector(presentError:) withObject:error waitUntilDone:NO];
            [threadPool drain];
            return;
        }
        if (![dict setString:@"zip" forStringKey:@"extension" error:&error]) {
            [NSApp performSelectorOnMainThread:@selector(presentError:) withObject:error waitUntilDone:NO];
            [threadPool drain];
            return;
        }        

        NSTask *ditto = [[NSTask alloc] init];
        [ditto setLaunchPath:@"/usr/bin/ditto"];
        [ditto setArguments:[NSArray arrayWithObjects:@"-c", @"-k", @"--sequesterRsrc", @"--keepParent", [url path], @"-", nil]];
        NSPipe *outPipe = [[NSPipe alloc] init];
        [ditto setStandardOutput:outPipe];
        [ditto launch];
        
        didSend = [self sendFileFromFileDescriptor:[[outPipe fileHandleForReading] fileDescriptor] metadata:dict error:&error];
    }
    else
    {
        // Try opening the file
        int fd = open([[url path] fileSystemRepresentation], O_RDONLY);
        if (fd==-1) {
            [NSError set:&error 
                  domain:@"FileSendJob" 
                    code:1
                  format:@"open() failed: %s", strerror(errno)];
            [NSApp performSelectorOnMainThread:@selector(presentError:) withObject:error waitUntilDone:NO];
            [threadPool drain];
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
            [NSApp performSelectorOnMainThread:@selector(presentError:) withObject:error waitUntilDone:NO];
            [threadPool drain];
            return;
        }
        
        // Create file metadata dictionary
        KVPMutableDictionary *dict = [[[KVPMutableDictionary alloc] init] autorelease];
        if (![dict setString:[[url lastPathComponent] stringByDeletingPathExtension] forStringKey:@"basename" error:&error]) {
            close(fd);
            [NSApp performSelectorOnMainThread:@selector(presentError:) withObject:error waitUntilDone:NO];
            [threadPool drain];
            return;
        }
        if (![dict setString:[url pathExtension] forStringKey:@"extension" error:&error]) {
            close(fd);
            [NSApp performSelectorOnMainThread:@selector(presentError:) withObject:error waitUntilDone:NO];
            [threadPool drain];
            return;
        }
        if (![dict setUInt64:statres.st_size forStringKey:@"size" error:&error]) {
            close(fd);
            [NSApp performSelectorOnMainThread:@selector(presentError:) withObject:error waitUntilDone:NO];
            [threadPool drain];
            return;
        }
        // send mtime only if it isn't negative (We want to be ready for the 32bit Y2k38 problem...)
        if (statres.st_mtimespec.tv_sec > 0) {
            uint64_t mtime_nano = 1000000000*(uint64_t)statres.st_mtimespec.tv_sec + (uint64_t)statres.st_mtimespec.tv_nsec;
            if (![dict setUInt64:mtime_nano forStringKey:@"mtime_nano" error:&error]) {
                close(fd);
                [NSApp performSelectorOnMainThread:@selector(presentError:) withObject:error waitUntilDone:NO];
                [threadPool drain];
                return;
            }
        }
        
        didSend = [self sendFileFromFileDescriptor:fd metadata:dict error:&error];
        
        close(fd);
    }
    if (!didSend) [NSApp presentError:error];
}

-(BOOL)sendFileFromFileDescriptor:(int)fd metadata:(KVPDictionary*)metadata error:(NSError**)error {
    // open a connection to the recipient
	IPAddress *address = [[[recipient.recentAddresses lastObject] copy] autorelease];
	address.port = recipient.tcpListenPort;
    TCPConnection *connection = [TCPConnection connectTo:address error:error];
    if (!connection) return NO;
    
    // Open secure channel
    SecureChannel *channel = [[[SecureChannel alloc] init] autorelease];
    if (![channel openChannelOverConnection:connection error:error]) {
        return NO;
    }
    connection = (id)channel;

    // send file metadata
    if (![connection sendPacket:metadata.data error:error]) {
        return NO;
    }
    
    // read file in 1MB chunks and send them
    int chunksize = 1024*1024;
    char *buffer = malloc(chunksize+1);
    *buffer = 'D';
    int bytesread;
    while ((bytesread = read(fd, buffer+1, chunksize))) {
        NSAutoreleasePool *loopPool = [[NSAutoreleasePool alloc] init];
        if (bytesread == -1) {
            if (errno==EINTR) continue;
            [NSError set:error 
                  domain:@"FileSendJob" 
                    code:1
                  format:@"read() failed: %s", strerror(errno)];
            return NO;
        }
        NSData *packet = [NSData dataWithBytes:buffer length:bytesread+1];
        if (![connection sendPacket:packet error:error]) {
            return NO;
        }
        [loopPool drain];
    }
    
    // we're done! send a zero length packet to confirm
    if (![connection sendPacket:[NSData data] error:error]) {
        return NO;
    }
    
    return YES;
}

@end
