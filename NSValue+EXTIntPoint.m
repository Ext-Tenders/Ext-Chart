//
//  NSValue+EXTIntPoint.m
//  Ext Chart
//
//  Created by Bavarious on 11/07/2014.
//  Copyright (c) 2014 Harvard University. All rights reserved.
//

#import "NSValue+EXTIntPoint.h"

@implementation NSValue (EXTIntPoint)

+ (instancetype)extValueWithIntPoint:(EXTIntPoint)point
{
    return [NSValue valueWithBytes:&point objCType:@encode(EXTIntPoint)];
}

- (EXTIntPoint)extIntPointValue
{
    EXTIntPoint result;
    [self getValue:&result];
    return result;
}

@end
