//
//  EXTMultAnnotationLayer.m
//  Ext Chart
//
//  Created by Eric Peterson on 7/11/14.
//  Copyright (c) 2014 Harvard University. All rights reserved.
//

#import "EXTMultAnnotationLayer.h"

#pragma mark - Private variables

static CGColorRef _multAnnotationStrokeColor;


@implementation EXTMultAnnotationLineLayer

static void commonInit(EXTMultAnnotationLineLayer *self)
{
    self.lineCap = kCALineCapRound;
    self.strokeColor = _multAnnotationStrokeColor;
}

+ (void)initialize
{
    if (self == [EXTMultAnnotationLineLayer class]) {
        _multAnnotationStrokeColor = CGColorCreateCopy([[NSColor blackColor] CGColor]);
    }
}

- (instancetype)init
{
    self = [super init];
    commonInit(self);
    return self;
}

- (instancetype)initWithLayer:(id)layer
{
    self = [super init];
    if (self && [layer isKindOfClass:[EXTMultAnnotationLineLayer class]]) {
        EXTMultAnnotationLineLayer *otherLayer = layer;
        _annotation = otherLayer.annotation;
        
        commonInit(self);
    }
    return self;
}

#pragma mark - Properties

- (void)setDefaultLineWidth:(CGFloat)defaultLineWidth {
    if (_defaultLineWidth != defaultLineWidth) {
        _defaultLineWidth = defaultLineWidth;
        self.lineWidth = defaultLineWidth;
    }
}

@end
