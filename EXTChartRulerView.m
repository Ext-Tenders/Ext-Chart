//
//  EXTChartRulerView.m
//  Ext Chart
//
//  Created by Bavarious on 15/06/2014.
//  Copyright (c) 2014 Harvard University. All rights reserved.
//

#import "EXTChartRulerView.h"


static const CGFloat _ruleLength = 16.0;
static const CGFloat _bigHashMarkLength = 13.0;
static const CGFloat _smallHashMarkLength = 6.0;
static const CGFloat _labelPosition = 2.0;
static const CGFloat _labelFontSize = 8.0;
static const CGFloat _hashMarkWidth = 0.5;
static const CGFloat _hashMarkHalfWidth = _hashMarkWidth / 2;

static NSDictionary *_labelAttrs;

static NSString *const _needsRedrawKey = @"needsRedraw";
static void *_needsRedrawContext = &_needsRedrawContext;


@implementation EXTChartRulerView

- (instancetype)initWithScrollView:(NSScrollView *)scrollView orientation:(NSRulerOrientation)orientation {
    self = [super initWithScrollView:scrollView orientation:orientation];
    if (self) {
        [self addObserver:self forKeyPath:_needsRedrawKey options:0 context:_needsRedrawContext];
    }
    return self;
}

- (void)dealloc {
    [self removeObserver:self forKeyPath:_needsRedrawKey context:_needsRedrawContext];
}

- (void)drawHashMarksAndLabelsInRect:(NSRect)rect {
    const bool horizontal = self.orientation == NSHorizontalRuler;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSMutableParagraphStyle *parStyle = NSParagraphStyle.defaultParagraphStyle.mutableCopy;
        parStyle.alignment = NSCenterTextAlignment;
        _labelAttrs = @{NSFontAttributeName : [NSFont systemFontOfSize:_labelFontSize],
                        NSForegroundColorAttributeName : NSColor.blackColor,
                        NSParagraphStyleAttributeName : parStyle};
    });

    const NSSize unitStepInSelf = [self convertSize:(NSSize){self.unitToPointsConversionFactor, self.unitToPointsConversionFactor} fromView:self.scrollView.contentView];
    const NSPoint viewOriginInSelf = [self convertPoint:(NSPoint){self.originOffset, self.originOffset} fromView:self.scrollView.contentView];
    const NSRect viewBoundsInSelf = [self convertRect:self.scrollView.contentView.bounds fromView:self.scrollView.contentView];

    NSInteger firstVisibleHashMarkIndex;
    NSInteger lastVisibleHashMarkIndex;
    CGFloat hashPosition;
    NSRect labelFrame;

    if (horizontal) {
        firstVisibleHashMarkIndex = (NSInteger)(floor(ceil(NSMinX(viewBoundsInSelf) - viewOriginInSelf.x) / unitStepInSelf.width));
        lastVisibleHashMarkIndex = (NSInteger)(ceil(floor(NSMaxX(viewBoundsInSelf) - viewOriginInSelf.x) / unitStepInSelf.width));
        hashPosition = (firstVisibleHashMarkIndex * unitStepInSelf.width) + viewOriginInSelf.x - _hashMarkHalfWidth;
        labelFrame = (NSRect){
            .origin.x = hashPosition + _hashMarkWidth,
            .origin.y = self.baselineLocation + _labelPosition,
            .size.width = unitStepInSelf.width - _hashMarkWidth,
            .size.height = _ruleLength
        };
    }
    else {
        firstVisibleHashMarkIndex = (NSInteger)(floor(ceil(NSMinY(viewBoundsInSelf) - viewOriginInSelf.y) / unitStepInSelf.height));
        lastVisibleHashMarkIndex = (NSInteger)(ceil(floor(NSMaxY(viewBoundsInSelf) - viewOriginInSelf.y) / unitStepInSelf.height));
        hashPosition = (firstVisibleHashMarkIndex * unitStepInSelf.height) + viewOriginInSelf.y - _hashMarkHalfWidth;
        labelFrame = (NSRect){
            .origin.y = self.baselineLocation + _labelPosition,
            .origin.x = hashPosition + _hashMarkWidth,
            .size.height = _ruleLength,
            .size.width = unitStepInSelf.width - _hashMarkWidth,
        };
    }

    const CGFloat baselineLocation = self.baselineLocation;
    const CGFloat reflectedBaselineLocation = self.baselineLocation + _ruleLength;

    [NSGraphicsContext saveGraphicsState];
    NSAffineTransform *labelTransform = nil;
    if (!horizontal) {
        labelTransform = [NSAffineTransform transform];
        [labelTransform translateXBy:_ruleLength yBy:0.0];
        [labelTransform rotateByDegrees:90]; // according to the docs, this should be anticlockwise. In practice, it’s clockwise!
        [labelTransform set];

        labelFrame.origin.y = baselineLocation - _labelPosition;
    }

    [NSColor.blackColor set];
    NSBezierPath *path = [NSBezierPath bezierPath];
    path.lineWidth = _hashMarkWidth;

    // FIXME: constrain drawing to rect (the parameter)

    for (NSInteger hashMarkIndex = firstVisibleHashMarkIndex; hashMarkIndex <= lastVisibleHashMarkIndex; ++hashMarkIndex) {
        const bool emphasisMark = (hashMarkIndex % _emphasisSpacing) == 0;

        const CGFloat hashMarkLength = (emphasisMark ? _bigHashMarkLength : _smallHashMarkLength);
        NSPoint from, to;

        if (horizontal) {
            from = (NSPoint){hashPosition, reflectedBaselineLocation};
            to = (NSPoint){hashPosition, reflectedBaselineLocation - hashMarkLength};
        }
        else {
            from = (NSPoint){hashPosition, baselineLocation};
            to = (NSPoint){hashPosition, hashMarkLength};
        }

        [path moveToPoint:from];
        [path lineToPoint:to];

        if (true) { // FIXME: we’ll want to draw labels selectively
            NSString *label = [NSString stringWithFormat:@"%ld", (long)hashMarkIndex];
            [label drawInRect:labelFrame withAttributes:_labelAttrs];
        }

        hashPosition += unitStepInSelf.width;
        labelFrame.origin.x = hashPosition + _hashMarkHalfWidth;
    }

    [path stroke];
    [NSGraphicsContext restoreGraphicsState];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (context == _needsRedrawContext) {
        [self setNeedsDisplay:YES];
    }
    else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

+ (NSSet *)keyPathsForValuesAffectingNeedsRedraw {
    return [NSSet setWithObjects:@"unitToPointsConversionFactor", @"emphasisSpacing", nil];
}

@end
