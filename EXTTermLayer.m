//
//  EXTTermLayer.m
//  Ext Chart
//
//  Created by Bavarious on 04/07/2014.
//  Copyright (c) 2014 Harvard University. All rights reserved.
//

#import "EXTTermLayer.h"

@implementation EXTTermLayer

- (instancetype)initWithLayer:(id)layer
{
    self = [super initWithLayer:layer];
    if (self && [layer isKindOfClass:[EXTTermLayer class]]) {
        EXTTermLayer *otherLayer = layer;
        _termData = otherLayer.termData;
    }
    return self;
}

@end
