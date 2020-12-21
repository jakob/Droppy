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
        char big_nibble = (*bin >> 4) & 0xF;
        *(curr++) = big_nibble < 0xA ? '0' + big_nibble : 'A' + (big_nibble - 0xA);
        char small_nibble = *bin & 0xF;
        *(curr++) = small_nibble < 0xA ? '0' + small_nibble : 'A' + (small_nibble - 0xA);
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

-(NSString*)base58EncodedString {
	NSMutableData *xData = [self mutableCopy];
	const char *alphabet = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz";
	uint8_t *x = [xData mutableBytes];
	size_t xlen = [xData length];
	size_t reslen = ceil(log(256) / log(58) * (double)xlen);
	char *res = malloc(reslen);
	for (size_t k = reslen; k-->0; ) {
		
		// divide x by 58
		// division is performed in place
		// r is the remainder of the division
		// this algorithm is kinda how you learned to do division in school
		// except that we use bytes instead of digits
		uint16_t r = 0;
		for (int i = 0; i < xlen; i++) {
			uint16_t dividend = (r << 8) + x[i];
			x[i] = dividend / 58;
			r = dividend % 58;
		}
		
		// the remainder is the least significant digit of the result
		// (k is counting backwards)
		res[k] = alphabet[r];
	};
	// after reslen iterations, x will be all zeros
	// this method may end up with leading 1s
	[xData release];
	NSString *result = [[NSString alloc] initWithBytes:res length:reslen encoding:NSASCIIStringEncoding];
	free(res);
	return [result autorelease];
}

@end
