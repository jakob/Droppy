#import <Foundation/Foundation.h>


@interface NSString (NSString_Additions)

-(NSData *)dataUsingEncoding:(NSStringEncoding)encoding maxEncodedLength:(NSInteger)maxLength;

@end
