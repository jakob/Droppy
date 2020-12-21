//
//  FileTransferMetadata.h
//  Oktett
//
//  Created by Jakob on 28.11.20.
//  Copyright 2020 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface FileTransferMetadata : NSObject {
    NSString *basename;
    NSString *extension;
    uint64_t length;
    uint64_t mtime_in_nanoseconds;
}

@end
