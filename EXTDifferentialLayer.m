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
static void *_selectedContext = &_selectedContext;

static const CGFloat _kDifferentialLineWidth = 0.25;
static const CGFloat _kHighlightedDifferentialLineWidth = _kDifferentialLineWidth * 5;
static CGColorRef _differentialStrokeColor;


@implementation EXTDifferentialLayer

@synthesize highlighted = _highlighted;
@synthesize highlightColor = _highlightColor;
@synthesize selected = _selected;
@synthesize selectionColor = _selectionColor;


static void commonInit(EXTDifferentialLayer *self)
{
    self.lineWidth = _kDifferentialLineWidth;
    self.strokeColor = _differentialStrokeColor;
    self.lineCap = kCALineCapRound;

    [self addObserver:self forKeyPath:@"highlighted" options:0 context:_highlightedContext];
    [self addObserver:self forKeyPath:@"selected" options:0 context:_selectedContext];
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
        _differential = otherLayer.differential;

        commonInit(self);
    }
    return self;
}

- (void)dealloc
{
    [self removeObserver:self forKeyPath:@"highlighted" context:_highlightedContext];
    [self removeObserver:self forKeyPath:@"selected" context:_selectedContext];

    CGColorRelease(_highlightColor);
    CGColorRelease(_selectionColor);
}

#pragma mark - Properties

- (void)setHighlightColor:(CGColorRef)highlightColor
{
    if (_highlightColor != highlightColor) {
        CGColorRelease(_highlightColor);
        _highlightColor = CGColorCreateCopy(highlightColor);
    }
}

- (void)setSelectionColor:(CGColorRef)selectionColor
{
    if (_selectionColor != selectionColor) {
        CGColorRelease(_selectionColor);
        _selectionColor = CGColorCreateCopy(selectionColor);
    }
}

#pragma mark - NSKeyValueObserving

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == _highlightedContext || context == _selectedContext) [self updateInteractionStatus];
    else [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

- (void)updateInteractionStatus
{
    CGColorRef strokeColor;
    CGFloat lineWidth;

    if (self.selected) {
        strokeColor = self.selectionColor;
        lineWidth = _kHighlightedDifferentialLineWidth;
    }
    else if (self.highlighted) {
        strokeColor = self.highlightColor;
        lineWidth = _kHighlightedDifferentialLineWidth;
    }
    else {
        strokeColor = _differentialStrokeColor;
        lineWidth = _kDifferentialLineWidth;
    }

    self.strokeColor = strokeColor;
    self.lineWidth = lineWidth;
}

@end
