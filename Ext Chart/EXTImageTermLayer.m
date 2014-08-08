//
//  EXTImageTermLayer.m
//  Ext Chart
//
//  Created by Bavarious on 23/07/2014.
//  Copyright (c) 2014 Harvard University. All rights reserved.
//

#import "EXTImageTermLayer.h"
#import "EXTChartViewModel.h"
#import "EXTChartView.h"

#pragma mark - Private variables

static const int _kMaxGlyphs = 3;
static NSCache *_cellImageCache;

static NSColor *_color;
static const CGFloat _kLineWidth = 1.0 / 26.0;
static const CGFloat _kSingleDigitFontSizeFactor = 0.5;
static const CGFloat _kDoubleDigitFontSizeFactor = 0.4;

#pragma mark - Private classes

typedef NS_ENUM(NSInteger, EXTTermCellGlyph) {
    EXTTermCellGlyphNone,
    EXTTermCellGlyphFilledDot,
    EXTTermCellGlyphUnfilledDotWithLabel,
    EXTTermCellGlyphUnfilledSquare,
};

typedef struct {
    NSInteger rank;
    EXTTermCellGlyph glyphs[_kMaxGlyphs];
} EXTTermCellLayout;

#pragma mark - Private functions

static NSSize boundingSizeForAttributedString(NSAttributedString *s);
static NSString *makeCacheKey(EXTTermCellLayout *layout, CGFloat length, NSColor *color);
static void makeCellLayout(EXTTermCellLayout *outLayout, EXTChartViewModelTermCell *termCell);
static NSImage *makeCellImage(EXTTermCellLayout *layout, CGFloat length, NSColor *color);


#pragma mark - Class extensions

@interface EXTImageTermLayer ()
@property (nonatomic, readonly) CGFloat scaledLength;
@property (nonatomic, readonly) NSColor *termColor;
@end

@implementation EXTImageTermLayer

@synthesize highlighted = _highlighted;
@synthesize selectedObject = _selectedObject;
@synthesize highlightColor = _highlightColor;
@synthesize selectionColor = _selectionColor;

@synthesize termCell = _termCell;


+ (void)initialize
{
    if (self == [EXTImageTermLayer class]) {
        _cellImageCache = [NSCache new];
        _color = [NSColor blackColor];
    }
}

- (instancetype)initWithLayer:(id)layer
{
    self = [super initWithLayer:layer];
    if (self && [layer isKindOfClass:[EXTImageTermLayer class]]) {
        EXTImageTermLayer *otherLayer = layer;
        _termCell = otherLayer.termCell;
    }
    return self;
}

+ (instancetype)termLayerWithTermCell:(EXTChartViewModelTermCell *)termCell length:(NSInteger)length
{
    EXTTermCellLayout cellLayout;
    makeCellLayout(&cellLayout, termCell);

    EXTImageTermLayer *layer = [EXTImageTermLayer layer];
    layer.contents = makeCellImage(&cellLayout, length, _color);
    layer->_termCell = termCell;
    layer.drawsAsynchronously = YES;
    return layer;
}

- (void)dealloc {
    CGColorRelease(_highlightColor);
    CGColorRelease(_selectionColor);
}

- (void)reloadContents {
    if (!self.termCell) return;

    EXTTermCellLayout cellLayout;
    makeCellLayout(&cellLayout, self.termCell);

    self.contents = makeCellImage(&cellLayout, self.scaledLength, self.termColor);
}

- (CGFloat)scaledLength {
    return self.bounds.size.width * self.contentsScale;
}

- (NSColor *)termColor {
    return (self.selectedObject ? [NSColor colorWithCGColor:self.selectionColor] :
            self.highlighted ? [NSColor colorWithCGColor:self.highlightColor] :
            _color);
}

- (void)updateInteractionStatus
{
    if (!self.termCell) return;

    EXTTermCellLayout cellLayout;
    makeCellLayout(&cellLayout, self.termCell);

    self.contents = makeCellImage(&cellLayout, self.scaledLength, self.termColor);
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

- (void)setHighlighted:(bool)highlighted
{
    if (highlighted != _highlighted) {
        _highlighted = highlighted;
        [self updateInteractionStatus];
    }
}

- (void)setSelectedObject:(bool)selectedObject
{
    if (selectedObject != _selectedObject) {
        _selectedObject = selectedObject;
        [self updateInteractionStatus];
    }

    if (selectedObject) {
        CAKeyframeAnimation *animation = CAKeyframeAnimation.animation;
        animation.keyPath = @"transform";
        animation.values = @[[NSValue valueWithCATransform3D:CATransform3DIdentity],
                             [NSValue valueWithCATransform3D:CATransform3DMakeScale(0.75, 0.75, 1.0)],
                             [NSValue valueWithCATransform3D:CATransform3DMakeScale(1.5, 1.5, 1.0)],
                             [NSValue valueWithCATransform3D:CATransform3DIdentity]];
        animation.keyTimes = @[@0.0, @0.3, @0.8, @1.0];
        animation.duration = 0.2;
        animation.removedOnCompletion = YES;

        [self addAnimation:animation forKey:@"selection"];
    }
}

@end

#pragma mark - Private functions

NSSize boundingSizeForAttributedString(NSAttributedString *s) {
    NSCParameterAssert(s);

    CTLineRef line = CTLineCreateWithAttributedString((__bridge CFAttributedStringRef)s);
    NSCAssert(line, @"Line should not be null");

    CGFloat ascent, descent;
    NSSize size;
    size.width = CTLineGetTypographicBounds(line, &ascent, &descent, NULL);
    size.height = ascent + descent;

    CFRelease(line);

    return size;
}

NSString *makeCacheKey(EXTTermCellLayout *layout, CGFloat length, NSColor *color) {
    NSCParameterAssert(layout);
    NSCParameterAssert(color);

    return [NSString stringWithFormat:@"%ld,%d,%d,%d,%f,%lu",
            layout->rank,
            (int)layout->glyphs[0],
            (int)layout->glyphs[1],
            (int)layout->glyphs[2],
            length,
            color.hash];
}

void makeCellLayout(EXTTermCellLayout *outLayout, EXTChartViewModelTermCell *termCell) {
    NSCParameterAssert(outLayout);
    NSCParameterAssert(termCell);

    outLayout->rank = termCell.totalRank;
    if (outLayout->rank <= _kMaxGlyphs) {
        for (int i = 0; i < _kMaxGlyphs; ++i) {
            outLayout->glyphs[i] = (i < outLayout->rank ?
                                    EXTTermCellGlyphFilledDot :
                                    EXTTermCellGlyphNone);
        }
    }
    else {
        outLayout->glyphs[0] = EXTTermCellGlyphUnfilledDotWithLabel;

        for (int i = 1; i < _kMaxGlyphs; ++i) {
            outLayout->glyphs[i] = EXTTermCellGlyphNone;
        }
    }
}

NSImage *makeCellImage(EXTTermCellLayout *layout, CGFloat length, NSColor *color) {
    NSCParameterAssert(layout);
    NSCParameterAssert(color);

    NSString *cacheKey = makeCacheKey(layout, length, color);
    NSImage *image = [_cellImageCache objectForKey:cacheKey];

#ifdef LOG_IMGCACHE_STATS
    static NSInteger cacheHits, cacheMisses;
#endif
    if (image) {
#ifdef LOG_IMGCACHE_STATS
        ++cacheHits;
        DLog(@"Dot iamage cache HIT; hits = %ld, misses = %ld", (long)cacheHits, (long)cacheMisses);
#endif
        return image;
    }

#ifdef LOG_IMGCACHE_STATS
    ++cacheMisses;
    DLog(@"Dot iamage cache MISS; hits = %ld, misses = %ld", (long)cacheHits, (long)cacheMisses);
    DLog(@"Rank is %ld, length is %f, color is %@", (long)rank, round(length), color);
#endif

    BOOL (^drawingHandler)(NSRect) = NULL;

    if (layout->rank <= 3) {
        NSBezierPath *path = [NSBezierPath bezierPath];
        for (NSInteger i = 0; i < layout->rank; ++i) {
            const CGRect rect = [EXTChartView dotBoundingBoxForCellRank:layout->rank
                                                              termIndex:i
                                                           gridLocation:(EXTIntPoint){0}
                                                            gridSpacing:(NSInteger)length];
            [path appendBezierPathWithOvalInRect:rect];
        }

        drawingHandler = ^(NSRect frame) {
            [color setFill];
            [path fill];
            return YES;
        };
    }
    else {
        NSString *label = [NSString stringWithFormat:@"%ld", layout->rank];
        const CGFloat fontSize = length * ([label length] == 1 ? _kSingleDigitFontSizeFactor : _kDoubleDigitFontSizeFactor);
        NSFont *font = [NSFont fontWithName:EXTTermLayerFontName size:fontSize];
        NSDictionary *attrs = @{
                                NSFontAttributeName: font,
                                NSForegroundColorAttributeName: color
                                };
        NSAttributedString *attrLabel = [[NSAttributedString alloc] initWithString:label attributes:attrs];

        const CGRect drawingFrame = [EXTChartView dotBoundingBoxForCellRank:layout->rank
                                                                  termIndex:0
                                                               gridLocation:(EXTIntPoint){0}
                                                                gridSpacing:(NSInteger)length];
        NSBezierPath *path = [NSBezierPath bezierPathWithOvalInRect:drawingFrame];
        path.lineWidth = _kLineWidth * length;
        const NSSize labelSize = boundingSizeForAttributedString(attrLabel);

        drawingHandler = ^(NSRect frame) {
            // We want the label centred horizontally & vertically inside frame
            const NSRect textFrame = {
                .origin.x = (frame.size.width - labelSize.width) / 2,
                .origin.y = /*FIXME: magic*/ 0.35 * frame.size.height,
                .size = labelSize,
            };

            [color setStroke];
            [path stroke];
            [attrLabel drawWithRect:textFrame options:0]; // FIXME: doesn’t match positioning in -drawInRect:. Works with magic above
            return YES;
        };
    }

    image = [NSImage imageWithSize:(CGSize){length, length} flipped:NO drawingHandler:drawingHandler];
    [_cellImageCache setObject:image forKey:cacheKey];
    return image;
}
