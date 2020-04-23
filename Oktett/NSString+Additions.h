//
//  NSString+Additions.h
//  Oktett
//
//  Created by Jakob on 23.04.20.
//  Copyright 2020 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSString (NSString_Additions)

-(NSData *)dataUsingEncoding:(NSStringEncoding)encoding maxEncodedLength:(NSInteger)maxLength;

@end
