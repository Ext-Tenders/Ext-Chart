//
//  EXTTermLayer.m
//  Ext Chart
//
//  Created by Bavarious on 04/07/2014.
//  Copyright (c) 2014 Harvard University. All rights reserved.
//

#import "EXTTermLayer.h"
#import "EXTChartViewModel.h"
#import "EXTChartView.h"

#pragma mark - Private variables

static CFMutableDictionaryRef _glyphPathCache;
static CGColorRef _termCountFillColor;
static CGColorRef _termCountStrokeColor;
static const CGFloat _kTermCountLineWidth = 1.0;
static const CGFloat _kTermCountSingleDigitFontSizeFactor = 0.7;
static const CGFloat _kTermCountDoubleDigitFontSizeFactor = 0.55;
static NSString * const _kTermCountFontName = @"Palatino-Roman";


@implementation EXTTermLayer

@synthesize highlighted = _highlighted;
@synthesize highlightColor = _highlightColor;
@synthesize selected = _selected;
@synthesize selectionColor = _selectionColor;

+ (void)initialize
{
    if (self == [EXTTermLayer class]) {
        _glyphPathCache = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, NULL, &kCFTypeDictionaryValueCallBacks);

        _termCountFillColor = CGColorCreateCopy([[NSColor blackColor] CGColor]);
        _termCountStrokeColor = CGColorCreateCopy([[NSColor blackColor] CGColor]);
    }
}

- (instancetype)initWithLayer:(id)layer
{
    self = [super initWithLayer:layer];
    if (self && [layer isKindOfClass:[EXTTermLayer class]]) {
        EXTTermLayer *otherLayer = layer;
        _termCell = otherLayer.termCell;
    }
    return self;
}

- (void)dealloc
{
    CGColorRelease(_highlightColor);
    CGColorRelease(_selectionColor);
}

+ (instancetype)termLayerWithTotalRank:(NSInteger)totalRank length:(CGFloat)length
{
    EXTTermLayer *layer = [EXTTermLayer layer];
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathMoveToPoint(path, NULL, 0.0, 0.0);

    for (NSInteger i = 0; i < totalRank; ++i) {
        const CGRect box = [EXTChartView dotBoundingBoxForTermCount:totalRank termIndex:i gridLocation:(EXTIntPoint){0} gridSpacing:length];
        CGPathAddEllipseInRect(path, NULL, box);
    }

    if (totalRank <= 3) {
        layer.fillColor = _termCountFillColor;
        layer.lineWidth = 0.0;
    }
    else {
        layer.fillColor = [[NSColor clearColor] CGColor];
        layer.strokeColor = _termCountStrokeColor;
        layer.lineWidth = _kTermCountLineWidth;

        NSString *label = [NSString stringWithFormat:@"%ld", (long)totalRank];
        CGFloat fontSize = round((totalRank < 10 ?
                                  length * _kTermCountSingleDigitFontSizeFactor :
                                  length * _kTermCountDoubleDigitFontSizeFactor));
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
    NSFont *font = [NSFont fontWithName:_kTermCountFontName size:fontSize];
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
// _glyphPathCache is a two-level dictionary where the first key is the font, the second key is the glyph and the value is the corresponding path
+ (CGPathRef)pathForGlyph:(CGGlyph)glyph fromFont:(CTFontRef)font
{
    // First we lookup the font to get to its glyph dictionary
    CFMutableDictionaryRef glyphDict = (CFMutableDictionaryRef)CFDictionaryGetValue(_glyphPathCache, font);
    if(glyphDict == NULL)
    {
        // And if this font hasn't been seen before, we'll create and set the dictionary for it
        glyphDict = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, NULL, &kCFTypeDictionaryValueCallBacks);
        CFDictionarySetValue(_glyphPathCache, font, glyphDict);
        CFRelease(glyphDict);
    }
    // Next we try to get a path for the given glyph from the glyph dictionary
    CGPathRef path = (CGPathRef)CFDictionaryGetValue(glyphDict, (const void *)(uintptr_t)glyph);
    if(path == NULL)
    {
        // If the path hasn't been seen before, then we'll create the path from the font & glyph and cache it.
        path = CTFontCreatePathForGlyph(font, glyph, NULL);
        if(path == NULL)
        {
            // If a glyph does not have a path, then we need a placeholder to set in the dictionary
            path = (CGPathRef)kCFNull;
        }
        CFDictionarySetValue(glyphDict, (const void *)(uintptr_t)glyph, path);
        CFRelease(path);
    }
    if(path == (CGPathRef)kCFNull)
    {
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
    }
}

- (void)setSelectionColor:(CGColorRef)selectionColor
{
    if (_selectionColor != selectionColor) {
        CGColorRelease(_selectionColor);
        _selectionColor = CGColorCreateCopy(selectionColor);
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
        fillColor = _termCountFillColor;
        strokeColor = _termCountStrokeColor;
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
