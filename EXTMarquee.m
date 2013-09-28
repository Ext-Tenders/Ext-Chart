//
//  EXTMarquee.m
//  Ext Chart
//
//  Created by Bavarious on 23/09/2013.
//  Copyright (c) 2013 Harvard University. All rights reserved.
//

#import "EXTMarquee.h"
#import "NSKeyedArchiver+EXTAdditions.h"


@implementation EXTMarquee

#pragma mark - NSCoding

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:self.string forKey:@"string"];
    [coder encodeRect:self.frame forKey:@"frame"];
    // TODO: encode image representations. Will we accept arbitrary images or PDF only?
}

- (id)initWithCoder:(NSCoder *)decoder {
    self = [super init];
    if (!self)
        return nil;

    _string = [decoder decodeObjectForKey:@"string"];
    _frame = [decoder decodeRectForKey:@"frame"];
    // TODO: decode image representations

    return self;
}

@end
