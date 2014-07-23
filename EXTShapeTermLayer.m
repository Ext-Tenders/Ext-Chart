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
static const CGFloat _kLineWidth = 2.0;
static const CGFloat _kSingleDigitFontSizeFactor = 0.7;
static const CGFloat _kDoubleDigitFontSizeFactor = 0.4;
static NSString * const _fontName = @"Palatino-Roman";

#pragma mark - Private classes

@interface EXTTermLayerGlyphCacheKey : NSObject <NSCopying>
@property (nonatomic, assign) CGFloat fontSize;
@property (nonatomic, assign) CGGlyph glyph;
+ (instancetype)glyphCacheKeyWithFontSize:(CGFloat)fontSize glyph:(CGGlyph)glyph;
@end


@implementation EXTShapeTermLayer

@synthesize highlighted = _highlighted;
@synthesize highlightColor = _highlightColor;
@synthesize selected = _selected;
@synthesize selectionColor = _selectionColor;
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

- (void)dealloc
{
    CGColorRelease(_highlightColor);
    CGColorRelease(_selectionColor);
}

+ (instancetype)termLayerWithTotalRank:(NSInteger)totalRank length:(NSInteger)length
{
    EXTShapeTermLayer *layer = [EXTShapeTermLayer layer];
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathMoveToPoint(path, NULL, 0.0, 0.0);

    for (NSInteger i = 0; i < totalRank; ++i) {
        const CGRect box = [EXTChartView dotBoundingBoxForCellRank:totalRank termIndex:i gridLocation:(EXTIntPoint){0} gridSpacing:length];
        CGPathAddEllipseInRect(path, NULL, box);
    }

    if (totalRank <= 3) {
        layer.fillColor = _fillColor;
        layer.lineWidth = 0.0;
    }
    else {
        layer.fillColor = [[NSColor clearColor] CGColor];
        layer.strokeColor = _strokeColor;
        layer.lineWidth = _kLineWidth;

        NSString *label = [NSString stringWithFormat:@"%ld", (long)totalRank];
        CGFloat fontSize = round((totalRank < 10 ?
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

    layer.path = path;
    CGPathRelease(path);

    return layer;
}

+ (NSArray *)layersForString:(NSString *)string atSize:(CGFloat)fontSize totalSize:(CGSize *)outSize
{
    NSParameterAssert(outSize);

    NSMutableArray *layers = [NSMutableArray new];
    outSize->width = outSize->height = 0.0;
    NSFont *font = [NSFont fontWithName:_fontName size:fontSize];
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

- (void)setSelected:(bool)selected
{
    if (selected != _selected) {
        _selected = selected;
        [self updateInteractionStatus];
    }

    if (selected) {
        CAKeyframeAnimation *animation = CAKeyframeAnimation.animation;
        animation.keyPath = @"transform";
        animation.values = @[[NSValue valueWithCATransform3D:CATransform3DIdentity],
                             [NSValue valueWithCATransform3D:CATransform3DMakeScale(0.75, 0.75, 1.0)],
                             [NSValue valueWithCATransform3D:CATransform3DMakeScale(1.5, 1.5, 1.0)],
                             [NSValue valueWithCATransform3D:CATransform3DIdentity]];
        animation.keyTimes = @[@0.0, @0.3, @0.8, @1.0];
        animation.duration = 0.2;
        animation.removedOnCompletion = YES;

        [self addAnimation:animation forKey:@"setSelectedTrue"];
    }
}

- (void)updateInteractionStatus
{
    CGColorRef fillColor, strokeColor;

    if (self.selected) {
        fillColor = strokeColor = self.selectionColor;
    }
    else if (self.highlighted) {
        fillColor = strokeColor = self.highlightColor;
    }
    else {
        fillColor = _fillColor;
        strokeColor = _strokeColor;
    }

    if (self.termCell.totalRank <= 3) {
        self.fillColor = fillColor;
    }
    else {
        self.strokeColor = strokeColor;
        for (CAShapeLayer *sublayer in self.sublayers) {
            sublayer.fillColor = strokeColor;
        }
    }
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
