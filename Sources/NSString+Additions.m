#import "NSString+Additions.h"


@implementation NSString (NSString_Additions)


-(NSData *)dataUsingEncoding:(NSStringEncoding)encoding maxEncodedLength:(NSInteger)maxLength {
    NSInteger length = [self length];
    NSInteger truncatedLength;
    NSString *truncatedString;
    if (length < maxLength) {
        truncatedLength = length;
        truncatedString = self;
    } else {
        truncatedLength = maxLength;
        truncatedString = [self substringToIndex:maxLength];
    }
    NSData *truncatedStringData = [truncatedString dataUsingEncoding:encoding];
    while (truncatedStringData.length > maxLength) {
        // the string is too long!
        // we don't know how many characters we need to chop off, but we can make an estimate based on average character length
        int chopLen = ceilf((float)truncatedLength/(float)truncatedStringData.length*(float)(truncatedStringData.length-maxLength));
        if (truncatedLength - chopLen < 5) chopLen = 1; // more precise truncation for very short strings
        if (chopLen < 1) chopLen = 1; // chop at least one character
        truncatedLength -= chopLen;
        [self substringToIndex:truncatedLength];
        truncatedStringData = [truncatedString dataUsingEncoding:encoding];
    }
    return truncatedStringData;
}


@end
