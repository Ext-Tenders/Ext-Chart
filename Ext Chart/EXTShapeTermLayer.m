//
//  EXTShapeTermLayer.m
//  Ext Chart
//
//  Created by Bavarious on 23/07/2014.
//  Copyright (c) 2014 Harvard University. All rights reserved.
//

#import "EXTShapeTermLayer.h"
#import "EXTChartViewModel.h"
#import "EXTChartView.h"

#pragma mark - Private variables

static CFMutableDictionaryRef _glyphPathCache;
static CGColorRef _fillColor;
static CGColorRef _strokeColor;
static const CGFloat _kLineWidth = 1.0;
static const CGFloat _kSingleDigitFontSizeFactor = 0.7;
static const CGFloat _kDoubleDigitFontSizeFactor = 0.4;

#pragma mark - Private classes

@interface EXTTermLayerGlyphCacheKey : NSObject <NSCopying>
@property (nonatomic, assign) CGFloat fontSize;
@property (nonatomic, assign) CGGlyph glyph;
+ (instancetype)glyphCacheKeyWithFontSize:(CGFloat)fontSize glyph:(CGGlyph)glyph;
@end

@implementation EXTShapeTermLayer

@synthesize termCell = _termCell;

+ (void)initialize
{
    if (self == [EXTShapeTermLayer class]) {
        _glyphPathCache = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);

        _fillColor = CGColorCreateCopy([[NSColor blackColor] CGColor]);
        _strokeColor = CGColorCreateCopy([[NSColor blackColor] CGColor]);
    }
}

- (instancetype)initWithLayer:(id)layer
{
    self = [super initWithLayer:layer];
    if (self && [layer isKindOfClass:[EXTShapeTermLayer class]]) {
        EXTShapeTermLayer *otherLayer = layer;
        _termCell = otherLayer.termCell;
    }
    return self;
}

+ (instancetype)termLayerWithTermCell:(EXTChartViewModelTermCell *)termCell length:(NSInteger)length
{
    EXTShapeTermLayer *layer = [EXTShapeTermLayer layer];
    layer->_termCell = termCell;

    EXTTermCellLayout layout;
    EXTTermLayerMakeCellLayout(&layout, termCell);

    if (layout.rank <= EXTTermLayerMaxGlyphs) {
        for (NSInteger glyphIndex = 0; glyphIndex < layout.rank; ++glyphIndex) {
            const CGRect rect = [EXTChartView dotBoundingBoxForCellRank:layout.rank
                                                              termIndex:glyphIndex
                                                           gridLocation:(EXTIntPoint){0}
                                                            gridSpacing:length];

            switch (layout.glyphs[glyphIndex]) {
                case EXTTermCellGlyphFilledDot: {
                    CAShapeLayer *glyphLayer = [CAShapeLayer layer];

                    glyphLayer.fillColor = _fillColor;
                    glyphLayer.lineWidth = 0.0;
                    glyphLayer.frame = rect;

                    CGMutablePathRef path = CGPathCreateMutable();
                    CGPathAddEllipseInRect(path, NULL, (CGRect){CGPointZero, rect.size});
                    glyphLayer.path = path;
                    CGPathRelease(path);

                    [layer addSublayer:glyphLayer];
                    break;
                }

                case EXTTermCellGlyphUnfilledSquare: {
                    CALayer *glyphLayer = [CALayer layer];

                    glyphLayer.borderColor = _strokeColor;
                    glyphLayer.borderWidth = _kLineWidth;

                    const CGFloat inset = rect.size.width * EXTTermLayerSquareInsetFactor;
                    const CGRect squareRect = CGRectInset(rect, inset, inset);
                    glyphLayer.frame = squareRect;

                    [layer addSublayer:glyphLayer];
                    break;
                }

                default:
                    break;
            }
        }
    }
    else {
        CGMutablePathRef path = CGPathCreateMutable();
        CGPathAddEllipseInRect(path, NULL, [EXTChartView dotBoundingBoxForCellRank:layout.rank termIndex:0 gridLocation:(EXTIntPoint){0} gridSpacing:length]);
        layer.path = path;
        CGPathRelease(path);

        layer.fillColor = [[NSColor clearColor] CGColor];
        layer.strokeColor = _strokeColor;
        layer.lineWidth = _kLineWidth;

        NSString *label = [NSString stringWithFormat:@"%ld", (long)layout.rank];
        CGFloat fontSize = round((layout.rank < 10 ?
                                  length * _kSingleDigitFontSizeFactor :
                                  length * _kDoubleDigitFontSizeFactor));
        CGSize textSize;
        NSArray *glyphLayers = [self layersForString:label atSize:fontSize totalSize:&textSize];
        // Centre the layers horizontally
        const CGSize offset = {(length - textSize.width) / 2.0, (length - textSize.height) / 2.0};

        for (CAShapeLayer *glyphLayer in glyphLayers) {
            CGPoint position = glyphLayer.position;
            position.x += offset.width;
            position.y = offset.height;
            glyphLayer.position = position;

            [layer addSublayer:glyphLayer];
        }
    }

    return layer;
}

+ (NSArray *)layersForString:(NSString *)string atSize:(CGFloat)fontSize totalSize:(CGSize *)outSize
{
    NSParameterAssert(outSize);

    NSMutableArray *layers = [NSMutableArray new];
    outSize->width = outSize->height = 0.0;
    NSFont *font = [NSFont fontWithName:EXTTermLayerFontName size:fontSize];
    NSDictionary *attrs = @{NSFontAttributeName: font};

    NSAttributedString *attrString = [[NSAttributedString alloc] initWithString:string attributes:attrs];
    CTLineRef line = CTLineCreateWithAttributedString((__bridge CFAttributedStringRef)attrString);
    CFArrayRef glyphRuns = CTLineGetGlyphRuns(line);
    CFIndex glyphRunsCount = CFArrayGetCount(glyphRuns);
    for (CFIndex glyphRunIndex = 0; glyphRunIndex < glyphRunsCount; ++glyphRunIndex) {
        CTRunRef run = CFArrayGetValueAtIndex(glyphRuns, glyphRunIndex);
        CFIndex runGlyphCount = CTRunGetGlyphCount(run);
        CGPoint positions[runGlyphCount];
        CGGlyph glyphs[runGlyphCount];

        CTRunGetPositions(run, (CFRange){0}, positions);
        CTRunGetGlyphs(run, (CFRange){0}, glyphs);
        for (CFIndex glyphIndex = 0; glyphIndex < runGlyphCount; ++glyphIndex) {
            CAShapeLayer *layer = CAShapeLayer.layer;
            layer.position = positions[glyphIndex];
            layer.path = [self pathForGlyph:glyphs[glyphIndex] atSize:fontSize];
            [layers addObject:layer];

            NSRect glyphBoundingRect = [font boundingRectForGlyph:glyphs[glyphIndex]];
            outSize->height = MAX(outSize->height, glyphBoundingRect.size.height);
        }
    }

    outSize->width = CTLineGetTypographicBounds(line, NULL, NULL, NULL);

    CFRelease(line);

    return layers;
}

+ (CGPathRef)pathForGlyph:(CGGlyph)glyph atSize:(CGFloat)fontSize
{
    CTFontRef font = CTFontCreateWithName(CFSTR("Palatino-Roman"), fontSize, NULL);
    CGPathRef path = [self pathForGlyph:glyph fromFont:font];
    CFRelease(font);
    return path;
}

// From Apple’s CoreAnimationText sample code
+ (CGPathRef)pathForGlyph:(CGGlyph)glyph fromFont:(CTFontRef)font
{
    const CGFloat fontSize = CTFontGetSize(font);
    EXTTermLayerGlyphCacheKey *cacheKey = [EXTTermLayerGlyphCacheKey glyphCacheKeyWithFontSize:fontSize glyph:glyph];
    CGPathRef path = (CGPathRef)CFDictionaryGetValue(_glyphPathCache, (const void *)cacheKey);
    if (path == NULL) {
        path = CTFontCreatePathForGlyph(font, glyph, NULL);
        if (path == NULL) {
            path = (CGPathRef)kCFNull;
        }

        CFDictionarySetValue(_glyphPathCache, (const void *)cacheKey, path);
        CFRelease(path);
    }

    if (path == (CGPathRef)kCFNull) {
        // If we got the placeholder, then set the path to NULL
        // (this will happen either after discovering the glyph path is NULL,
        // or after looking that up in the dictionary).
        path = NULL;
    }

    return path;
}

@end


@implementation EXTTermLayerGlyphCacheKey
+ (instancetype)glyphCacheKeyWithFontSize:(CGFloat)fontSize glyph:(CGGlyph)glyph
{
    EXTTermLayerGlyphCacheKey *key = [EXTTermLayerGlyphCacheKey new];
    if (key) {
        key->_fontSize = fontSize;
        key->_glyph = glyph;
    }
    return key;
}

- (instancetype)copyWithZone:(NSZone *)zone
{
    EXTTermLayerGlyphCacheKey *copy = [EXTTermLayerGlyphCacheKey new];
    if (copy) {
        copy->_fontSize = self->_fontSize;
        copy->_glyph = self->_glyph;
    }
    return copy;
}

- (NSUInteger)hash
{
    return NSUINTROTATE(((NSUInteger)_fontSize), NSUINT_BIT / 2) ^ (NSUInteger)_glyph;
}

- (BOOL)isEqual:(id)object
{
    EXTTermLayerGlyphCacheKey *otherKey = object;
    return ([otherKey isKindOfClass:[EXTTermLayerGlyphCacheKey class]] &&
            otherKey->_fontSize == self->_fontSize &&
            otherKey->_glyph == self->_glyph);
}
@end
