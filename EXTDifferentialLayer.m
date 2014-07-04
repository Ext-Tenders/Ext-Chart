//
//  EXTDifferentialLayer.m
//  Ext Chart
//
//  Created by Bavarious on 04/07/2014.
//  Copyright (c) 2014 Harvard University. All rights reserved.
//

#import "EXTDifferentialLayer.h"

@implementation EXTDifferentialLayer

- (instancetype)initWithLayer:(id)layer
{
    self = [super init];
    if (self && [layer isKindOfClass:[EXTDifferentialLayer class]]) {
        EXTDifferentialLayer *otherLayer = layer;
        _differentialData = otherLayer.differentialData;
    }
    return self;
}

@end
