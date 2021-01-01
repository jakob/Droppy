#import <Foundation/Foundation.h>


@interface NSData (NSData_EncodingHelpers)

-(NSString*)fast_hex;
-(NSString*)sodium_base64;
-(NSString*)base58EncodedString;
+(NSData*)dataWithLength:(size_t)xlen fromBase58EncodedString:(NSString*)str error:(NSError**)outError;

@end
