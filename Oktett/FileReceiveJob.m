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
#import "NSData+EncodingHelpers.h"
#include <sys/stat.h>
#include <sys/time.h>
#import "SecureChannel.h"

@implementation FileReceiveJob

-(void)receiveFileInBackgroundFromConnection:(TCPConnection*)connection {
    [self performSelectorInBackground:@selector(receiveFileFromConnection:) withObject:connection];
}

-(void)receiveFileFromConnection:(TCPConnection*)connection {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NSError *error = nil;

    // Open secure channel
    SecureChannel *channel = [[[SecureChannel alloc] init] autorelease];
    if (![channel openChannelOverConnection:connection error:&error]) {
        [NSApp performSelectorOnMainThread:@selector(presentError:) withObject:error waitUntilDone:NO];
        [pool release];
        return;
    }
    connection = (id)channel;
    
    // Try to get file metadata
    NSData *metadata = [connection receivePacketWithMaxLength:5000 error:&error];
    if (!metadata) {
        [NSApp performSelectorOnMainThread:@selector(presentError:) withObject:error waitUntilDone:NO];
        [pool release];
        return;
    }
    KVPDictionary *dict = [KVPDictionary dictionaryFromData:metadata error:&error];
    if (!dict) {
        [NSApp performSelectorOnMainThread:@selector(presentError:) withObject:error waitUntilDone:NO];
        [pool release];
        return;
    }
    
    // Read and sanitize basename
    NSString *basename = [dict stringForStringKey:@"basename"];
    if ([basename length]==0) basename = @"file";
    basename = [basename stringByReplacingOccurrencesOfString:@"/" withString:@":"];
    if ([basename hasPrefix:@"."]) basename = [@"_" stringByAppendingString:basename];

    // Read and sanitize extension (can be nil or zero length)
    NSString *extension = [dict stringForStringKey:@"extension"];
    extension = [extension stringByReplacingOccurrencesOfString:@"/" withString:@":"];

    // Generate a random string to avoid collisions
    NSString *alphabet = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890";
    unichar randomCharacters[6];
    for (int i=0; i<6; i++) {
        randomCharacters[i] = [alphabet characterAtIndex:randombytes_uniform([alphabet length])];
    }
    NSString *randomString = [NSString stringWithCharacters:randomCharacters length:6];

    NSURL *url = [NSURL fileURLWithPath:NSTemporaryDirectory()];
    url = [url URLByAppendingPathComponent:basename];
    url = [url URLByAppendingPathExtension:randomString];
    if ([extension length]) url = [url URLByAppendingPathExtension:extension];

    // Try opening the file
    int fd = open([[url path] fileSystemRepresentation], O_WRONLY|O_CREAT|O_EXCL, S_IRUSR|S_IWUSR|S_IRGRP|S_IWGRP);
    if (fd==-1) {
        [NSError set:&error 
              domain:@"FileReceiveJob" 
                code:1
              format:@"open() failed: %s", strerror(errno)];
        [NSApp performSelectorOnMainThread:@selector(presentError:) withObject:error waitUntilDone:NO];
        [pool release];
        return;
    }
    
    BOOL success = NO;
    while (1) {
        NSAutoreleasePool *loopPool = [[NSAutoreleasePool alloc] init];
        NSData *data = [connection receivePacketWithMaxLength:10*1024*1024 error:&error];
        if (!data) {
            break;
        }
        if ([data length] == 0) {
            // we're done!
            success = YES;
            break;
        }
        char packetType = *(char*)[data bytes];
        if (packetType != 'D') {
            [NSError set:&error 
                  domain:@"FileReceiveJob" 
                    code:1
                  format:@"Invalid packet type: %c", packetType];
            break;
        }
        const void *payload = [data bytes]+1;
        int payload_len = [data length] - 1;
        int written = write(fd, payload, payload_len);
        if (written==-1) {
            [NSError set:&error 
                  domain:@"FileSendJob" 
                    code:1
                  format:@"write() failed: %s", strerror(errno)];
            break;
        }
        if (written!=payload_len) {
            [NSError set:&error 
                  domain:@"FileSendJob" 
                    code:1
                  format:@"Short write(): %d written of %d bytes", written, payload_len];
            break;
        }
        [loopPool drain];
    }
    
    if (success) {
        // Try to set the file modification date, if needed
        // This is not critical, so we ignore errors that happen here
        uint64_t mtime_nano;
        if ([dict getUInt64:&mtime_nano forStringKey:@"mtime_nano" error:nil]) {
            struct timeval times[2];
            gettimeofday(&times[0], NULL); // access time
            times[1].tv_sec = (__darwin_time_t)(mtime_nano / 1000000000);
            times[1].tv_usec = (__darwin_suseconds_t)((mtime_nano / 1000) % 1000000);
            futimes(fd, times);
        }
    }
    
    close(fd);
    
    if (!success) {
        [NSApp performSelectorOnMainThread:@selector(presentError:) withObject:error waitUntilDone:NO];
        [pool release];
        return;
    }
    
    // try to move file to download folder
    NSURL *finalURL = [self moveURLToDownloads:url basename:basename extension:extension error:&error];
    if (!finalURL) {
        [NSApp performSelectorOnMainThread:@selector(presentError:) withObject:error waitUntilDone:YES];
        [[NSWorkspace sharedWorkspace] activateFileViewerSelectingURLs:[NSArray arrayWithObject:url]];
        [pool release];
        return;
    }
    
    // we're done!
    [[NSWorkspace sharedWorkspace] activateFileViewerSelectingURLs:[NSArray arrayWithObject:finalURL]];
    
    [pool release];
}

-(NSURL*)moveURLToDownloads:(NSURL*)url basename:(NSString*)basename extension:(NSString*)extension error:(NSError**)error {
    NSFileManager *fm = [[[NSFileManager alloc] init] autorelease];
    NSURL *downloadsURL = [fm URLForDirectory:NSDownloadsDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:error];
    if (!downloadsURL) return nil;
    if ([basename length]==0) {
        basename = @"file";
    }
    NSURL *targetURL = [downloadsURL URLByAppendingPathComponent:basename];
    if ([extension length]) targetURL = [targetURL URLByAppendingPathExtension:extension];
    int i = 1;
    NSError *localError = nil;
    BOOL fileMoveSuccess = [fm moveItemAtURL:url toURL:targetURL error:&localError];
    if (!fileMoveSuccess) {
        struct stat st;
        BOOL fileExists;
        if ([[localError domain] isEqual:@"NSCocoaErrorDomain"] && [localError code]==516 /* NSFileWriteFileExistsError */) {
            fileExists = YES;
        }
        else if (NSAppKitVersionNumber < 1138 /* NSAppKitVersionNumber10_7 */ && [[localError domain] isEqual:@"NSCocoaErrorDomain"] && [localError code]==NSFileWriteUnknownError) {
            fileExists = 0 == lstat([[targetURL path] fileSystemRepresentation], &st);
        }
        else {
            fileExists = NO;
        }
        if (fileExists) {
            do {
                targetURL = [downloadsURL URLByAppendingPathComponent:[basename stringByAppendingFormat:@" %d", ++i]];
                if ([extension length]) targetURL = [targetURL URLByAppendingPathExtension:extension];
                fileExists = 0 == lstat([[targetURL path] fileSystemRepresentation], &st);
            } while (fileExists);
            fileMoveSuccess = [fm moveItemAtURL:url toURL:targetURL error:&localError];
        }
    }
    return fileMoveSuccess ? targetURL : nil;
}

@end
