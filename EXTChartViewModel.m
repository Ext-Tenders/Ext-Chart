//
//  EXTChartViewModel.m
//  Ext Chart
//
//  Created by Bavarious on 10/06/2014.
//  Copyright (c) 2014 Harvard University. All rights reserved.
//

#import "EXTChartViewModel.h"
#import "EXTSpectralSequence.h"
#import "EXTGrid.h"
#import "EXTTerm.h"
#import "EXTDifferential.h"
#import "EXTPolynomialSSeq.h"


@interface EXTChartViewModel ()
@property (nonatomic, strong) NSMutableDictionary *termCounts; // indexed by @(page). Each element is a dictionary mapping an EXTViewModelPoint to a term count
@property (nonatomic, strong) NSMutableDictionary *differentials; // indexed by @(page). Each element is an array (edge quadtree?) of EXTViewModelDifferential objects
@property (nonatomic, strong) NSMutableDictionary *multAnnotations; // indexed by @(page). Each element is a mutable dictionary of a style, keyed on @"style", and an array, keyed on @"annotations", of EXTViewModelMultAnnotation objects
@end


static NSArray *dotPositions(NSInteger count, EXTIntPoint gridPoint, CGFloat gridSpacing);
static bool lineSegmentOverRect(NSPoint p1, NSPoint p2, NSRect rect);
static bool lineSegmentIntersectsLineSegment(NSPoint l1p1, NSPoint l1p2, NSPoint l2p1, NSPoint l2p2);

@implementation EXTChartViewModel

static NSMutableDictionary *_dotLayers;
static dispatch_queue_t _dotLayersQueue;

+ (void)initialize
{
    if (self != [EXTChartViewModel class]) return;

    _dotLayers = [NSMutableDictionary new];
    _dotLayersQueue = dispatch_queue_create("edu.harvard.math.Ext-Chart.EXTChartViewState.dotLayersQueue", DISPATCH_QUEUE_SERIAL);
}

// Whenever we reload a page/gridSpacing, we register all term counts that appear during reloading.
// This makes sure that, by the time the view needs to draw dots, all dot layers have already been created.
+ (void)registerLayerForTermCount:(NSInteger)count
{
    static dispatch_once_t labelAttributesOnceToken;
    static NSDictionary *singleDigitAttributes, *multiDigitAttributes;
    dispatch_once(&labelAttributesOnceToken, ^{
        NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
        [paragraphStyle setAlignment:NSCenterTextAlignment];

        NSFont *singleDigitFont = [NSFont fontWithName:@"Palatino-Roman" size:5.0];
        NSFont *multiDigitFont = [NSFont fontWithName:@"Palatino-Roman" size:4.5];

        singleDigitAttributes = @{NSFontAttributeName : singleDigitFont,
                                  NSParagraphStyleAttributeName : paragraphStyle};
        multiDigitAttributes = @{NSFontAttributeName : multiDigitFont,
                                 NSParagraphStyleAttributeName : paragraphStyle};
    });

    dispatch_sync(_dotLayersQueue, ^{
        if (_dotLayers[@(count)]) return;

        // Since dot layers contain vectors only, we can draw them with fixed size and let Quartz
        // scale layers when needed
        const CGFloat spacing = 9.0;
        const CGSize size = {spacing, spacing};
        const CGRect frame = {.size = size};

        NSMutableData *PDFData = [NSMutableData data];
        CGDataConsumerRef dataConsumer = CGDataConsumerCreateWithCFData((__bridge CFMutableDataRef)PDFData);
        CGContextRef PDFContext = CGPDFContextCreate(dataConsumer, &frame, NULL);

        CGLayerRef layer = CGLayerCreateWithContext(PDFContext, size, NULL);
        CGContextRef layerContext = CGLayerGetContext(layer);

        NSGraphicsContext *drawingContext = [NSGraphicsContext graphicsContextWithGraphicsPort:layerContext flipped:NO];
        [NSGraphicsContext saveGraphicsState];
        [NSGraphicsContext setCurrentContext:drawingContext];
        CGContextBeginPage(PDFContext, &frame);
        {
            NSArray *dots = dotPositions(count, (EXTIntPoint){0}, spacing);

            if (count <= 3) {
                NSBezierPath *path = [NSBezierPath bezierPath];
                for (NSValue *rectObject in dots)
                    [path appendBezierPathWithOvalInRect:[rectObject rectValue]];
                [path fill];
            }
            else {
                const NSRect drawingFrame = [dots[0] rectValue];
                [[NSBezierPath bezierPathWithOvalInRect:drawingFrame] stroke];

                NSRect textFrame = drawingFrame;
                textFrame.origin.y += 0.05 * spacing;
                NSString *label = [NSString stringWithFormat:@"%ld", count];
                [label drawInRect:textFrame withAttributes:(label.length == 1 ? singleDigitAttributes : multiDigitAttributes)];
            }
        }
        CGContextEndPage(PDFContext);
        CGPDFContextClose(PDFContext);
        CGContextRelease(PDFContext);
        CGDataConsumerRelease(dataConsumer);
        [NSGraphicsContext restoreGraphicsState];
        
        _dotLayers[@(count)] = (__bridge id)layer;
        CGLayerRelease(layer);
    });
}

- (CGLayerRef)chartView:(EXTChartView *)chartView layerForTermCount:(NSInteger)count
{
    NSAssert(_dotLayers[@(count)], @"Dot layers should have been created for all used term counts");
    
    return (__bridge CGLayerRef)_dotLayers[@(count)];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _termCounts = [NSMutableDictionary new];
        _differentials = [NSMutableDictionary new];
    }
    return self;
}

- (void)reloadCurrentPage
{
    [self.sequence computeGroupsForPage:self.currentPage];

    // --- Term Counts
    // start by initializing the array of counts
    NSMutableDictionary *counts = [NSMutableDictionary new];

    // iterate through the available EXTTerms and count up how many project onto
    // a given grid location.  (this is a necessary step for, e.g., EXTTriple-
    // graded spectral sequences, where many EXTLocations might end up in the
    // same place.)
    //
    // TODO: the way this is set up does not allow EXTTerms to determine how
    // they get drawn.  this will probably need to be changed when we move to
    // Z-mods, since those have lots of interesting quotients which need to
    // represented visually.
    for (EXTTerm *term in self.sequence.terms.allValues) {
        EXTIntPoint point = [self.sequence.locConvertor gridPoint:term.location];
        EXTViewModelPoint *viewPoint = [EXTViewModelPoint newViewModelPointWithX:point.x y:point.y];
        NSInteger termCount = ((NSNumber *)counts[viewPoint]).integerValue;
        termCount += [term dimension:self.currentPage];
        if (termCount > 0) {
            counts[viewPoint] = @(termCount);
            [[self class] registerLayerForTermCount:termCount];
        }
    }

    // --- Differentials
    NSMutableArray *differentials = [NSMutableArray new];
    NSMutableDictionary *termCountOffsets = [NSMutableDictionary new];

    if (self.currentPage < self.sequence.differentials.count) {
        for (EXTDifferential *differential in ((NSDictionary*)self.sequence.differentials[self.currentPage]).allValues) {
            // some sanity checks to make sure this differential is worth drawing
            if ([differential page] != self.currentPage)
                continue;
            
            NSMutableArray *boundaryList = differential.end.boundaries[self.currentPage];
            EXTMatrix *boundaryMatrix = [EXTMatrix matrixWidth:boundaryList.count height:differential.end.size];
            boundaryMatrix.presentation = boundaryList;
            boundaryMatrix.characteristic = differential.presentation.characteristic;
            int imageSize = [EXTMatrix rankOfMap:differential.presentation intoQuotientByTheInclusion:boundaryMatrix];
            
            if ((imageSize <= 0) ||
                ([differential.start dimension:differential.page] == 0) ||
                ([differential.end dimension:differential.page] == 0))
                continue;

            const EXTIntPoint startPoint = [self.sequence.locConvertor gridPoint:differential.start.location];
            const EXTIntPoint endPoint = [self.sequence.locConvertor gridPoint:differential.end.location];
            EXTViewModelPoint *modelStartPoint = [EXTViewModelPoint newViewModelPointWithX:startPoint.x y:startPoint.y];
            EXTViewModelPoint *modelEndPoint = [EXTViewModelPoint newViewModelPointWithX:endPoint.x y:endPoint.y];
            const NSInteger startCount = [counts[modelStartPoint] integerValue];
            const NSInteger endCount = [counts[modelEndPoint] integerValue];
            NSArray *startRects = dotPositions(startCount, startPoint, self.grid.gridSpacing);
            NSArray *endRects = dotPositions(endCount, endPoint, self.grid.gridSpacing);

            for (NSInteger i = 0; i < imageSize; ++i) {
                NSInteger startOffset = [termCountOffsets[modelStartPoint] integerValue];
                NSInteger endOffset = [termCountOffsets[modelEndPoint] integerValue];
                termCountOffsets[modelStartPoint] = @(startOffset + 1);
                termCountOffsets[modelEndPoint] = @(endOffset + 1);

                // if they're out of bounds, which will happen in the >=4 case,
                // just use the bottom one.
                if (startOffset >= startRects.count)
                    startOffset = 0;
                if (endOffset >= endRects.count)
                    endOffset = 0;

                NSRect startRect = [startRects[startOffset] rectValue];
                NSRect endRect = [endRects[endOffset] rectValue];
                NSPoint viewStartPoint = (NSPoint){startRect.origin.x, startRect.origin.y + startRect.size.height / 2};
                NSPoint viewEndPoint = (NSPoint){
                    endRect.origin.x + endRect.size.width - 0.1 * self.grid.gridSpacing,
                    endRect.origin.y + endRect.size.height / 2
                };
                EXTViewModelDifferential *diff = [EXTViewModelDifferential newViewModelDifferentialWithStart:viewStartPoint end:viewEndPoint];
                [differentials addObject:diff];
            }
        }
    }
    
    // --- Multiplicative annotations
    NSMutableArray *annotationPairs = [NSMutableArray new];
    for (NSMutableDictionary *rule in self.multiplicationAnnotationRules) {
        // each of these dictionaries has:
        //   @"enabled": bool toggling whether we should bother to draw these
        //   @"style": unimplemented, reserved for a class describing line style
        //   @"location": location of the term we're going to multiply through
        //   @"vector": vector in the term at @"location" we're ^^^
        if (![rule[@"enabled"] boolValue])
            continue;
        
        NSMutableArray *annotationArray = [NSMutableArray new];
        
        for (EXTTerm *term in self.sequence.terms.allValues) {
            int rank = [self.sequence rankOfVector:rule[@"vector"]
                                        inLocation:rule[@"location"]
                                          actingAt:term.location
                                            onPage:self.currentPage];
            if (rank == 0)
                continue;
            
            // otherwise, draw something.
            const EXTIntPoint startPoint = [self.sequence.locConvertor gridPoint:term.location];
            const EXTIntPoint endPoint = [self.sequence.locConvertor gridPoint:[self.sequence.indexClass addLocation:term.location to:rule[@"location"]]];
            EXTViewModelPoint *modelStartPoint = [EXTViewModelPoint newViewModelPointWithX:startPoint.x y:startPoint.y];
            EXTViewModelPoint *modelEndPoint = [EXTViewModelPoint newViewModelPointWithX:endPoint.x y:endPoint.y];
            const NSInteger startCount = [counts[modelStartPoint] integerValue];
            const NSInteger endCount = [counts[modelEndPoint] integerValue];
            NSArray *startRects = dotPositions(startCount, startPoint, self.grid.gridSpacing);
            NSArray *endRects = dotPositions(endCount, endPoint, self.grid.gridSpacing);
                
            NSRect startRect = [startRects[0] rectValue];
            NSRect endRect = [endRects[0] rectValue];
            NSPoint viewStartPoint = (NSPoint){startRect.origin.x, startRect.origin.y + startRect.size.height / 2};
            NSPoint viewEndPoint = (NSPoint){
                endRect.origin.x + endRect.size.width - 0.1 * self.grid.gridSpacing,
                endRect.origin.y + endRect.size.height / 2
            };
            EXTViewModelMultAnnotation *anno = [EXTViewModelMultAnnotation newViewModelMultAnnotationWithStart:viewStartPoint end:viewEndPoint];
            [annotationArray addObject:anno];
        }
        
        // add the array of annotations we've constructed as an entry
        NSMutableDictionary *entry = [NSMutableDictionary new];
        entry[@"annotations"] = annotationArray;
        if (rule[@"style"])
            entry[@"style"] = rule[@"style"];
        [annotationPairs addObject:entry];
    }

    self.termCounts[@(self.currentPage)] = counts;
    self.differentials[@(self.currentPage)] = differentials;
    self.multAnnotations[@(self.currentPage)] = annotationPairs;
}

- (NSArray *)chartView:(EXTChartView *)chartView termCountsInGridRect:(EXTIntRect)gridRect
{
    NSMutableArray *result = [NSMutableArray array];
    [self.termCounts[@(self.currentPage)] enumerateKeysAndObjectsUsingBlock:^(EXTViewModelPoint *point, NSNumber *count, BOOL *stop) {
        EXTIntPoint gridPoint = (EXTIntPoint){.x = point.x, .y = point.y};
        if (EXTIntPointInRect(gridPoint, gridRect)) {
            EXTChartViewTermCountData *data = [EXTChartViewTermCountData new];
            data.point = (EXTIntPoint){.x = point.x, .y = point.y};
            data.count = count.integerValue;
            [result addObject:data];
        }
    }];

    return result.copy;
}

- (NSArray *)chartView:(EXTChartView *)chartView differentialsInRect:(NSRect)rect
{
    NSMutableArray *result = [NSMutableArray array];
    for (EXTViewModelDifferential *diff in self.differentials[@(self.currentPage)]) {
        if (lineSegmentOverRect(diff.start, diff.end, rect)) {
            EXTChartViewDifferentialData *data = [EXTChartViewDifferentialData new];
            data.start = diff.start;
            data.end = diff.end;
            [result addObject:data];
        }
    }
    return result.copy;
}

- (NSArray *)chartView:(EXTChartView *)chartView multAnnotationsInRect:(NSRect)gridRect {
    
    return [NSArray new];
}

- (NSArray *)chartViewBackgroundRectsForSelectedObject:(EXTChartView *)chartView
{
    NSRect (^rectForTerm)(EXTTerm *) = ^(EXTTerm *term) {
        return [self.grid viewBoundingRectForGridPoint:[self.sequence.locConvertor gridPoint:term.location]];
    };

    NSArray *rects = nil;
    id selectedObject = self.selectedObject;

    if ([selectedObject isKindOfClass:[EXTTerm class]]) {
        rects = @[[NSValue valueWithRect:rectForTerm(selectedObject)]];
    }
    else if ([self.selectedObject isKindOfClass:[EXTDifferential class]]) {
        EXTDifferential *diff = selectedObject;
        rects = @[[NSValue valueWithRect:rectForTerm(diff.start)],
                  [NSValue valueWithRect:rectForTerm(diff.end)]];
    }

    return rects;
}

- (NSBezierPath *)chartView:(EXTChartView *)chartView highlightPathForToolAtGridLocation:(EXTIntPoint)gridLocation
{
    NSBezierPath *highlightPath;

    switch (self.selectedToolTag) {
        case EXTToolTagGenerator: {
            const NSRect gridSquareInView = [[chartView grid] viewBoundingRectForGridPoint:gridLocation];
            highlightPath = [NSBezierPath bezierPathWithRect:gridSquareInView];
            break;
        }

        case EXTToolTagDifferential: {
            EXTGrid *grid = chartView.grid;
            const EXTIntPoint targetGridPoint = [self.sequence.locConvertor followDifflAtGridLocation:gridLocation page:self.currentPage];
            const NSRect sourceRect = [grid viewBoundingRectForGridPoint:gridLocation];
            const NSRect targetRect = [grid viewBoundingRectForGridPoint:targetGridPoint];

            highlightPath = [NSBezierPath bezierPathWithRect:sourceRect];
            [highlightPath appendBezierPathWithRect:targetRect];
            break;
        }

        default:
            highlightPath = nil;
    }
    
    return highlightPath;
}

@end


#pragma mark -- helper classes --


@implementation EXTViewModelPoint
+ (instancetype)newViewModelPointWithX:(NSInteger)x y:(NSInteger)y
{
    EXTViewModelPoint *newPoint = [[self class] new];
    newPoint->_x = x;
    newPoint->_y = y;
    return newPoint;
}

- (instancetype)copyWithZone:(NSZone *)zone
{
    return [[self class] newViewModelPointWithX:_x y:_y];
}

- (NSUInteger)hash {
    return NSUINTROTATE(((NSUInteger)_x), NSUINT_BIT / 2) ^ _y;
}

- (BOOL)isEqual:(id)object
{
    EXTViewModelPoint *point = object;
    return ([point isKindOfClass:[EXTViewModelPoint class]] &&
            point.x == _x &&
            point.y == _y);
}
@end


@implementation EXTViewModelDifferential
+ (instancetype)newViewModelDifferentialWithStart:(NSPoint)start end:(NSPoint)end
{
    EXTViewModelDifferential *newDiff = [[self class] new];
    newDiff->_start = start;
    newDiff->_end = end;
    return newDiff;
}
@end

@implementation EXTViewModelMultAnnotation
+ (instancetype)newViewModelMultAnnotationWithStart:(NSPoint)start
                                                end:(NSPoint)end
{
    EXTViewModelMultAnnotation *newAnno = [[self class] new];
    newAnno->_start = start;
    newAnno->_end = end;
    return newAnno;
}
@end


NSArray *dotPositions(NSInteger count,
                      EXTIntPoint gridPoint,
                      CGFloat gridSpacing)
{

    switch (count) {
        case 1:
            return @[[NSValue valueWithRect:
                      NSMakeRect(gridPoint.x*gridSpacing + 2.0/6.0*gridSpacing,
                                 gridPoint.y*gridSpacing + 2.0/6.0*gridSpacing,
                                 2.0*gridSpacing/6.0,
                                 2.0*gridSpacing/6.0)]];

        case 2:
            return @[[NSValue valueWithRect:
                      NSMakeRect(gridPoint.x*gridSpacing + 1.0/6.0*gridSpacing,
                                 gridPoint.y*gridSpacing + 1.0/6.0*gridSpacing,
                                 2.0*gridSpacing/6.0,
                                 2.0*gridSpacing/6.0)],
                     [NSValue valueWithRect:
                      NSMakeRect(gridPoint.x*gridSpacing + 3.0/6.0*gridSpacing,
                                 gridPoint.y*gridSpacing + 3.0/6.0*gridSpacing,
                                 2.0*gridSpacing/6.0,
                                 2.0*gridSpacing/6.0)]];

        case 3:
            return @[[NSValue valueWithRect:
                      NSMakeRect(gridPoint.x*gridSpacing + 0.66/6.0*gridSpacing,
                                 gridPoint.y*gridSpacing + 1.0/6.0*gridSpacing,
                                 2.0*gridSpacing/6.0,
                                 2.0*gridSpacing/6.0)],
                     [NSValue valueWithRect:
                      NSMakeRect(gridPoint.x*gridSpacing + 2.0/6.0*gridSpacing,
                                 gridPoint.y*gridSpacing + 3.0/6.0*gridSpacing,
                                 2.0*gridSpacing/6.0,
                                 2.0*gridSpacing/6.0)],
                     [NSValue valueWithRect:
                      NSMakeRect(gridPoint.x*gridSpacing + 3.33/6.0*gridSpacing,
                                 gridPoint.y*gridSpacing + 1.0/6.0*gridSpacing,
                                 2.0*gridSpacing/6.0,
                                 2.0*gridSpacing/6.0)]];

        default:
            return @[[NSValue valueWithRect:
                      NSMakeRect(gridPoint.x*gridSpacing+0.15*gridSpacing,
                                 gridPoint.y*gridSpacing+0.15*gridSpacing,
                                 0.7*gridSpacing,
                                 0.7*gridSpacing)]];
    }

    return nil;
}

static bool lineSegmentOverRect(NSPoint p1, NSPoint p2, NSRect rect)
{
#define LEFT (NSPoint){(rect.origin.x), (rect.origin.y)}, (NSPoint){(rect.origin.x), (rect.origin.y + rect.size.height)}
#define RIGHT (NSPoint){(rect.origin.x + rect.size.width), (rect.origin.y)}, (NSPoint){(rect.origin.x + rect.size.width), (rect.origin.y + rect.size.height)}
#define TOP (NSPoint){(rect.origin.x), (rect.origin.y + rect.size.height)}, (NSPoint){(rect.origin.x + rect.size.width), (rect.origin.y + rect.size.height)}
#define BOTTOM (NSPoint){(rect.origin.x), (rect.origin.y)}, (NSPoint){(rect.origin.x + rect.size.width), (rect.origin.y)}
    return (lineSegmentIntersectsLineSegment(p1, p2, LEFT) ||
            lineSegmentIntersectsLineSegment(p1, p2, RIGHT) ||
            lineSegmentIntersectsLineSegment(p1, p2, TOP) ||
            lineSegmentIntersectsLineSegment(p1, p2, BOTTOM) ||
            NSPointInRect(p1, rect) ||
            NSPointInRect(p2, rect));
#undef LEFT
#undef RIGHT
#undef TOP
#undef BOTTOM
}

static bool lineSegmentIntersectsLineSegment(NSPoint l1p1, NSPoint l1p2, NSPoint l2p1, NSPoint l2p2)
{
    CGFloat q = (l1p1.y - l2p1.y) * (l2p2.x - l2p1.x) - (l1p1.x - l2p1.x) * (l2p2.y - l2p1.y);
    CGFloat d = (l1p2.x - l1p1.x) * (l2p2.y - l2p1.y) - (l1p2.y - l1p1.y) * (l2p2.x - l2p1.x);

    if (d == 0.0) return false;

    CGFloat r = q / d;

    q = (l1p1.y - l2p1.y) * (l1p2.x - l1p1.x) - (l1p1.x - l2p1.x) * (l1p2.y - l1p1.y);
    CGFloat s = q / d;

    return !(r < 0 || r > 1 || s < 0 || s > 1);
}
