//
//  NSUserDefaults+EXTAdditions.m
//  Ext Chart
//
//  Created by Bavarious on 11/08/2013.
//  Copyright (c) 2013 Harvard University. All rights reserved.
//

#import "NSUserDefaults+EXTAdditions.h"

@implementation NSUserDefaults (EXTAdditions)

- (NSColor *)extColorForKey:(NSString *)key {
    NSData *colorData = [self dataForKey:key];
    return colorData ? [NSUnarchiver unarchiveObjectWithData:colorData] : nil;
}

@end
