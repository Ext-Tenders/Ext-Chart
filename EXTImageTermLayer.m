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

static NSCache *_dotImageCache;

static NSColor *_color;
static const CGFloat _kLineWidth = 1.0 / 26.0;
static const CGFloat _kSingleDigitFontSizeFactor = 0.5;
static const CGFloat _kDoubleDigitFontSizeFactor = 0.4;

#pragma mark - Private functions

static NSSize boundingSizeForAttributedString(NSAttributedString *s);

#pragma mark - Private classes

@interface EXTDotImageCacheKey : NSObject
@property (nonatomic, readonly) NSInteger rank;
@property (nonatomic, readonly) CGFloat length;
@property (nonatomic, readonly) NSColor *color;
+ (instancetype)dotImageCacheKeyWithRank:(NSInteger)rank length:(CGFloat)length color:(NSColor *)color;
@end

#pragma mark - Class extensions

@interface EXTImageTermLayer ()

@property (nonatomic, strong) EXTTermLayerSurrogate *surrogate;
@property (nonatomic, readonly) CGFloat scaledLength;
@property (nonatomic, readonly) NSColor *termColor;
@end

@implementation EXTImageTermLayer

@dynamic highlighted;
@dynamic selectedObject;
@dynamic highlightColor;
@dynamic selectionColor;

@dynamic termCell;


+ (void)initialize
{
    if (self == [EXTImageTermLayer class]) {
        _dotImageCache = [NSCache new];
        _color = [NSColor blackColor];
    }
}

- (instancetype)init {
    self = [super init];
    if (!self) return nil;

    _surrogate = [EXTTermLayerSurrogate new];
    __weak typeof(self) weakSelf = self;
    _surrogate.interactionChangedContinuation = ^{
        typeof(self) strongSelf = weakSelf;
        [strongSelf updateInteractionStatus];
    };

    _surrogate.selectionAnimationContinuation = ^(CAAnimation *animation){
        typeof(self) strongSelf = weakSelf;
        [strongSelf addAnimation:animation forKey:@"selection"];
    };

    return self;
}

+ (bool)isSelectorHandledBySurrogate:(SEL)selector {
    return [[EXTTermLayerSurrogate surrogateSelectors] containsObject:NSStringFromSelector(selector)];
}

+ (BOOL)resolveInstanceMethod:(SEL)selector {
    return [self isSelectorHandledBySurrogate:selector] || [super resolveInstanceMethod:selector];
}

- (id)forwardingTargetForSelector:(SEL)selector {
    return [[self class] isSelectorHandledBySurrogate:selector] ? self.surrogate : [super forwardingTargetForSelector:selector];
}

- (instancetype)initWithLayer:(id)layer
{
    self = [super initWithLayer:layer];
    if (self && [layer isKindOfClass:[EXTImageTermLayer class]]) {
        EXTImageTermLayer *otherLayer = layer;
        _surrogate = [otherLayer.surrogate copy];
    }
    return self;
}

+ (instancetype)termLayerWithTotalRank:(NSInteger)totalRank length:(NSInteger)length
{
    EXTImageTermLayer *layer = [EXTImageTermLayer layer];
    layer.contents = [self dotImageForRank:totalRank length:length color:_color];
    layer.drawsAsynchronously = YES;
    return layer;
}

- (void)resetContents {
    self.contents = [EXTImageTermLayer dotImageForRank:self.termCell.totalRank
                                                length:self.scaledLength
                                                 color:self.termColor];
}

+ (NSImage *)dotImageForRank:(NSInteger)rank length:(CGFloat)length color:(NSColor *)color {
    NSParameterAssert(color);

    EXTDotImageCacheKey *cacheKey = [EXTDotImageCacheKey dotImageCacheKeyWithRank:rank length:round(length) color:color];
    NSImage *image = [_dotImageCache objectForKey:cacheKey];

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

    if (rank <= 3) {
        NSBezierPath *path = [NSBezierPath bezierPath];
        for (NSInteger i = 0; i < rank; ++i) {
            const CGRect rect = [EXTChartView dotBoundingBoxForCellRank:rank
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
        NSString *label = [NSString stringWithFormat:@"%ld", rank];
        const CGFloat fontSize = length * ([label length] == 1 ? _kSingleDigitFontSizeFactor : _kDoubleDigitFontSizeFactor);
        NSFont *font = [NSFont fontWithName:EXTTermLayerFontName size:fontSize];
        NSDictionary *attrs = @{
                                NSFontAttributeName: font,
                                NSForegroundColorAttributeName: color
                                };
        NSAttributedString *attrLabel = [[NSAttributedString alloc] initWithString:label attributes:attrs];

        const CGRect drawingFrame = [EXTChartView dotBoundingBoxForCellRank:rank
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
    [_dotImageCache setObject:image forKey:cacheKey];
    return image;
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
    self.contents = [EXTImageTermLayer dotImageForRank:self.termCell.totalRank
                                                length:self.scaledLength
                                                 color:self.termColor];
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


@implementation EXTDotImageCacheKey
+ (instancetype)dotImageCacheKeyWithRank:(NSInteger)rank length:(CGFloat)length color:(NSColor *)color {
    NSParameterAssert(color);

    EXTDotImageCacheKey *newKey = [[self class] new];
    if (newKey) {
        newKey->_rank = rank;
        newKey->_length = length;
        newKey->_color = color;
    }
    return newKey;
}

- (BOOL)isEqual:(id)object {
    EXTDotImageCacheKey *other = object;
    return (other != nil &&
            [other isKindOfClass:[EXTDotImageCacheKey class]] &&
            other->_rank == _rank &&
            other->_length == _length &&
            [other->_color isEqualTo:_color]);
}


- (NSUInteger)hash {
    return (NSUINTROTATE((NSUInteger)_rank, NSUINT_BIT / 2) ^
            (NSUInteger)_length ^
            [_color hash]);
}
@end
