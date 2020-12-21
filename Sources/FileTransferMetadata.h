#import <Foundation/Foundation.h>


@interface FileTransferMetadata : NSObject {
    NSString *basename;
    NSString *extension;
    uint64_t length;
    uint64_t mtime_in_nanoseconds;
}

@end
