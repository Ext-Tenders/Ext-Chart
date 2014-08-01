//
//  EXTDifferentialLineLayer.m
//  Ext Chart
//
//  Created by Bavarious on 04/07/2014.
//  Copyright (c) 2014 Harvard University. All rights reserved.
//

#import "EXTDifferentialLineLayer.h"

#pragma mark - Private variables

static void *_highlightedContext = &_highlightedContext;
static void *_selectedObjectContext = &_selectedObjectContext;

static const CGFloat _kLineWidthHighlightFactor = 5.0;
static CGColorRef _differentialStrokeColor;


@implementation EXTDifferentialLineLayer

@synthesize highlighted = _highlighted;
@synthesize highlightColor = _highlightColor;
@synthesize selectedObject = _selectedObject;
@synthesize selectionColor = _selectionColor;


static void commonInit(EXTDifferentialLineLayer *self)
{
    self.strokeColor = _differentialStrokeColor;
    self.lineCap = kCALineCapRound;

    [self addObserver:self forKeyPath:@"highlighted" options:0 context:_highlightedContext];
    [self addObserver:self forKeyPath:@"selectedObject" options:0 context:_selectedObjectContext];
}

+ (void)initialize
{
    if (self == [EXTDifferentialLineLayer class]) {
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
    if (self && [layer isKindOfClass:[EXTDifferentialLineLayer class]]) {
        EXTDifferentialLineLayer *otherLayer = layer;
        _differential = otherLayer.differential;

        commonInit(self);
    }
    return self;
}

- (void)dealloc
{
    [self removeObserver:self forKeyPath:@"highlighted" context:_highlightedContext];
    [self removeObserver:self forKeyPath:@"selectedObject" context:_selectedObjectContext];

    CGColorRelease(_highlightColor);
    CGColorRelease(_selectionColor);
}

#pragma mark - Properties

- (void)setHighlightColor:(CGColorRef)highlightColor
{
    if (_highlightColor != highlightColor) {
        CGColorRelease(_highlightColor);
        _highlightColor = CGColorCreateCopy(highlightColor);
        [self updateInteractionStatus];
    }
}

- (void)setSelectionColor:(CGColorRef)selectionColor
{
    if (_selectionColor != selectionColor) {
        CGColorRelease(_selectionColor);
        _selectionColor = CGColorCreateCopy(selectionColor);
        [self updateInteractionStatus];
    }
}

- (void)setDefaultLineWidth:(CGFloat)defaultLineWidth {
    if (_defaultLineWidth != defaultLineWidth) {
        _defaultLineWidth = defaultLineWidth;
        [self updateInteractionStatus];
    }
}

#pragma mark - NSKeyValueObserving

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == _highlightedContext || context == _selectedObjectContext) [self updateInteractionStatus];
    else [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

- (void)updateInteractionStatus
{
    if (self.selectedObject) {
        self.strokeColor = self.selectionColor;
        self.lineWidth = self.defaultLineWidth * _kLineWidthHighlightFactor;
        self.zPosition = self.selectedZPosition;
    }
    else if (self.highlighted) {
        self.strokeColor = self.highlightColor;
        self.lineWidth = self.defaultLineWidth * _kLineWidthHighlightFactor;
        self.zPosition = self.defaultZPosition;
    }
    else {
        self.strokeColor = _differentialStrokeColor;
        self.lineWidth = self.defaultLineWidth;
        self.zPosition = self.defaultZPosition;
    }
}

@end
