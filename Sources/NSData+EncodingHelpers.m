#import "NSData+EncodingHelpers.h"
#import "sodium.h"

@implementation NSData (NSData_EncodingHelpers)

-(NSString*)fast_hex {
    NSUInteger binlen = [self length];
    NSUInteger hexlen = binlen*2 + binlen/4;
    char *hex = malloc(hexlen);
    char *curr = hex;
    const char *bin = [self bytes];
    char i = 0;
    const char const *end = bin + binlen;
    while (bin<end) {
        char nibble = *bin & 0xF;
        if (nibble < 0xA) *(curr++) = '0' + nibble;
        else *(curr++) = 'A' + (nibble - 0xA);
        nibble = (*bin >> 4) & 0xF;
        if (nibble < 0xA) *(curr++) = '0' + nibble;
        else *(curr++) = 'A' + (nibble - 0xA);
        if (i%4==3) *(curr++) = i%16==15 ? '\n' : ' ';
        bin++;
        i++;
    }
    NSString *str = [[NSString alloc] initWithBytesNoCopy:hex length:hexlen encoding:NSASCIIStringEncoding freeWhenDone:YES];
    return [str autorelease];
}

-(NSString*)sodium_base64 {
    NSUInteger binlen = [self length];
    size_t b64len = sodium_base64_encoded_len(binlen, sodium_base64_VARIANT_ORIGINAL_NO_PADDING);
    char *b64 = malloc(b64len);
    sodium_bin2base64(b64, b64len, [self bytes], binlen, sodium_base64_VARIANT_ORIGINAL_NO_PADDING);
    NSString *b64_string = [[NSString alloc] initWithCString:b64 encoding:NSASCIIStringEncoding];
    free(b64);
    return [b64_string autorelease];
}

@end
