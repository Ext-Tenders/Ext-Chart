//
//  NSKeyedArchiver+EXTAdditions.h
//  Ext Chart
//
//  Created by Bavarious on 03/09/2013.
//  Copyright (c) 2013 Harvard University. All rights reserved.
//

@import Foundation;


@interface NSKeyedArchiver (EXTAdditions)

/*! Encodes an EXTIntPoint as two integers with keys key.x and key.y */
- (void)extEncodeIntPoint:(EXTIntPoint)point forKey:(NSString *)key;

/*! Encodes an EXTIntSize as two integers with keys key.width and key.height */
- (void)extEncodeIntSize:(EXTIntSize)size forKey:(NSString *)key;

/*! Encodes an EXTIntRect as an EXTIntPoint with key key.origin and
 an EXTIntSize with key key.size */
- (void)extEncodeIntRect:(EXTIntRect)rect forKey:(NSString *)key;

@end


@interface NSKeyedUnarchiver (EXTAdditions)

/*! Decodes an EXTIntPoint from two integers with keys key.x and key.y.
 Returns {0} if either key is not present in the archive. */
- (EXTIntPoint)extDecodeIntPointForKey:(NSString *)key;

/*! Decodes an EXTIntSize from two integers with keys key.width and key.height.
 Returns {0} if either key is not present in the archive. */
- (EXTIntSize)extDecodeIntSizeForKey:(NSString *)key;

/*! Decodes an EXTIntRect as an EXTIntPoint with key key.origin and
 an EXTIntSize with key key.size.
 Returns {0} if either key is not present in the archive. */
- (EXTIntRect)extDecodeIntRectForKey:(NSString *)key;

@end
