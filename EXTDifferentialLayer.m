//
//  EXTDifferentialLayer.m
//  Ext Chart
//
//  Created by Bavarious on 04/07/2014.
//  Copyright (c) 2014 Harvard University. All rights reserved.
//

#import "EXTDifferentialLayer.h"

#pragma mark - Private variables

static void *_highlightedContext = &_highlightedContext;
static const CGFloat _kDifferentialLineWidth = 0.25;
static const CGFloat _kHighlightedDifferentialLineWidth = _kDifferentialLineWidth * 5;
static CGColorRef _differentialStrokeColor;


@implementation EXTDifferentialLayer

@synthesize highlighted = _highlighted;


static void commonInit(EXTDifferentialLayer *self)
{
    self.lineWidth = _kDifferentialLineWidth;
    self.strokeColor = _differentialStrokeColor;
    self.lineCap = kCALineCapRound;

    [self addObserver:self forKeyPath:@"highlighted" options:NSKeyValueObservingOptionNew context:_highlightedContext];
}

+ (void)initialize
{
    if (self == [EXTDifferentialLayer class]) {
        _differentialStrokeColor = CGColorCreateCopy([[NSColor blackColor] CGColor]);
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
    if (self && [layer isKindOfClass:[EXTDifferentialLayer class]]) {
        EXTDifferentialLayer *otherLayer = layer;
        _differentialData = otherLayer.differentialData;

        commonInit(self);
    }
    return self;
}

- (void)dealloc
{
    [self removeObserver:self forKeyPath:@"highlighted" context:_highlightedContext];
    CGColorRelease(_highlightColor);
}

#pragma mark - Properties

- (void)setHighlightColor:(CGColorRef)highlightColor
{
    if (_highlightColor != highlightColor) {
        CGColorRelease(_highlightColor);
        _highlightColor = CGColorCreateCopy(highlightColor);
    }
}

#pragma mark - NSKeyValueObserving

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == _highlightedContext) {
        bool highlighted = [change[NSKeyValueChangeNewKey] boolValue];

        if (highlighted) {
            self.strokeColor = self.highlightColor;
            self.lineWidth = _kHighlightedDifferentialLineWidth;
        }
        else {
            self.strokeColor = _differentialStrokeColor;
            self.lineWidth = _kDifferentialLineWidth;
        }
    }
}


@end
