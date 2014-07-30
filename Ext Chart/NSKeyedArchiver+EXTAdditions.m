//
//  NSKeyedArchiver+EXTAdditions.m
//  Ext Chart
//
//  Created by Bavarious on 03/09/2013.
//  Copyright (c) 2013 Harvard University. All rights reserved.
//

#import "NSKeyedArchiver+EXTAdditions.h"


@implementation NSKeyedArchiver (EXTAdditions)

- (void)extEncodeIntPoint:(EXTIntPoint)point forKey:(NSString *)key {
    [self encodeInteger:point.x forKey:[key stringByAppendingString:@".x"]];
    [self encodeInteger:point.y forKey:[key stringByAppendingString:@".y"]];
}

- (void)extEncodeIntSize:(EXTIntSize)size forKey:(NSString *)key {
    [self encodeInteger:size.width forKey:[key stringByAppendingString:@".width"]];
    [self encodeInteger:size.height forKey:[key stringByAppendingString:@".height"]];
}

- (void)extEncodeIntRect:(EXTIntRect)rect forKey:(NSString *)key {
    [self extEncodeIntPoint:rect.origin forKey:[key stringByAppendingString:@".origin"]];
    [self extEncodeIntSize:rect.size forKey:[key stringByAppendingString:@".size"]];
}

@end


@implementation NSKeyedUnarchiver (EXTAdditions)

- (EXTIntPoint)extDecodeIntPointForKey:(NSString *)key {
    EXTIntPoint point = {0};

    NSString *xKey = [key stringByAppendingString:@".x"];
    NSString *yKey = [key stringByAppendingString:@".y"];

    if ([self containsValueForKey:xKey] && [self containsValueForKey:yKey]) {
        point.x = [self decodeIntegerForKey:xKey];
        point.y = [self decodeIntegerForKey:yKey];
    }

    return point;
}

- (EXTIntSize)extDecodeIntSizeForKey:(NSString *)key {
    EXTIntSize size = {0};

    NSString *widthKey = [key stringByAppendingString:@".width"];
    NSString *heightKey = [key stringByAppendingString:@".height"];

    if ([self containsValueForKey:widthKey] && [self containsValueForKey:heightKey]) {
        size.width = [self decodeIntegerForKey:widthKey];
        size.height = [self decodeIntegerForKey:heightKey];
    }

    return size;
}

- (EXTIntRect)extDecodeIntRectForKey:(NSString *)key {
    EXTIntRect rect = {0};

    NSString *originKey = [key stringByAppendingString:@".origin"];
    NSString *sizeKey = [key stringByAppendingString:@".size"];

    if ([self containsValueForKey:[originKey stringByAppendingString:@".x"]] &&
        [self containsValueForKey:[originKey stringByAppendingString:@".y"]] &&
        [self containsValueForKey:[sizeKey stringByAppendingString:@".width"]] &&
        [self containsValueForKey:[sizeKey stringByAppendingString:@".height"]]) {

        rect.origin = [self extDecodeIntPointForKey:originKey];
        rect.size = [self extDecodeIntSizeForKey:sizeKey];
    }
    
    return rect;
}

@end
