#import "NSData+EncodingHelpers.h"
#import "sodium.h"
#import "NSError+ConvenienceConstructors.h"

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
	static const char *alphabet = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz";
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
	// this method results in a fixed length result
	// it does not remove leading 1s
	[xData release];
	NSString *result = [[NSString alloc] initWithBytes:res length:reslen encoding:NSASCIIStringEncoding];
	free(res);
	return [result autorelease];
}

+(NSData*)dataWithLength:(size_t)xlen fromBase58EncodedString:(NSString*)str error:(NSError**)outError {
    // digvals maps from ASCII to base58 digit value (using the bitcoin alphabet)
    // looking up digits in this table is probably faster than doing a bunch of comparisons but I haven't actually tried it
    // invalid digits are marked with the value 255
    static uint8_t digvals[128] = {
        255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,
        255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,
        255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,
        255,   0,   1,   2,   3,   4,   5,   6,   7,   8, 255, 255, 255, 255, 255, 255,
        255,   9,  10,  11,  12,  13,  14,  15,  16, 255,  17,  18,  19,  20,  21, 255,
         22,  23,  24,  25,  26,  27,  28,  29,  30,  31,  32, 255, 255, 255, 255, 255,
        255,  33,  34,  35,  36,  37,  38,  39,  40,  41,  42,  43, 255,  44,  45,  46,
         47,  48,  49,  50,  51,  52,  53,  54,  55,  56,  57, 255, 255, 255, 255, 255
    };
    const char *digits = [str UTF8String];
    size_t ndigits = strlen(digits);
    uint8_t *x = calloc(1, xlen);
    uint8_t allbits = 0; // if the high bit is set, we have an invalid digit
    uint8_t overflowbits = 0; // if any bit is set, we have an overflow
    for (int i = 0; i<ndigits; i++) {
        uint8_t digit = digits[i];
        uint8_t digval = digvals[digit & 0x7F];
        allbits |= digval; // invalid digits will set the high bit
        allbits |= digit; // any non-ascii character will set the high bit
        // the following loop multiplies the number x by 58 and adds digval
        uint16_t mulres = digval;
        for (int j = xlen; j-->0;) {
            mulres += x[j] * 58;
            x[j] = mulres & 0xFF;
            mulres >>= 8;
        }
        overflowbits |= mulres; // if mulres is not zero here, then we need more than xlen bytes to store the value
    }
    allbits &= 0x80; // only the high bit signifies an invalid digit
    if (overflowbits || allbits) {
        // by checking for errors only at the very end, we reduce branches in the loop which may make the code faster
        // note: this is probably premature optimisation since I haven't actually done any benchmarks
        if (overflowbits) {
            [NSError set:outError domain:@"NSData+EncodingHelpers" code:1 format:@"Overflow while decoding Base58 encoded value."];
        }
        else {
            [NSError set:outError domain:@"NSData+EncodingHelpers" code:1 format:@"Invalid digit in Base58 encoded value."];
        }
        free(x);
        return nil;
    }
    return [[[NSData alloc] initWithBytesNoCopy:x length:xlen freeWhenDone:YES] autorelease];
}

@end
