//
//  EXTChartViewController.m
//  Ext Chart
//
//  Created by Bavarious on 10/08/2013.
//  Copyright (c) 2013 Harvard University. All rights reserved.
//

#import "EXTChartViewController.h"
#import "EXTChartView.h"
#import "EXTDocument.h"
#import "EXTSpectralSequence.h"
#import "EXTTerm.h"
#import "EXTDifferential.h"


static NSCache *_EXTLayerCache = nil;


@interface EXTChartViewController () <EXTChartViewDelegate>
    @property(nonatomic, weak) id selectedObject;
@end

@implementation EXTChartViewController {
    EXTDocument *_document;
}

#pragma mark - Life cycle

+ (void)initialize {
    if (self == [EXTChartViewController class])
        _EXTLayerCache = [NSCache new];
}

- (id)initWithDocument:(EXTDocument *)document {
    self = [super init];
    if (self)
        _document = document;
    return self;
}

- (void)setView:(NSView *)view {
    NSAssert([view isKindOfClass:[EXTChartView class]], @"EXTChartViewController controls EXTChartViews only");
    NSAssert(_document, @"EXTChartViewController needs a document");

    [super setView:view];

    self.chartView.delegate = self;
    [self.chartView displaySelectedPage];
}

+ (id)new {
    return [super new];
}

- (id)init {
    return [super init];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    return [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
}

#pragma mark - Properties

- (EXTChartView *)chartView {
    return (EXTChartView *)[self view];
}

#pragma mark - EXTChartViewDelegate

- (void)chartView:(EXTChartView *)chartView willDisplayPage:(NSUInteger)pageNumber {
    [_document.sseq computeGroupsForPage:pageNumber];
}

// this performs the culling and delegation calls for drawing a page of the SS
// TODO: does this need spacing to be passed in?  probably a lot of data passing
// needs to be investigated and untangled... :(
- (void)chartView:(EXTChartView *)chartView
   drawPageNumber:(NSUInteger)pageNumber
        lowerLeft:(NSPoint)lowerLeft
       upperRight:(NSPoint)upperRight
      withSpacing:(CGFloat)spacing {

    // start by initializing the array of counts
    int width = (int)(upperRight.x - lowerLeft.x + 1),
    height = (int)(upperRight.y - lowerLeft.y + 1);
    NSMutableArray *counts = [NSMutableArray arrayWithCapacity:width];
    for (int i = 0; i < width; i++) {
        NSMutableArray *row = [NSMutableArray arrayWithCapacity:height];
        for (int j = 0; j < height; j++)
            [row setObject:[NSMutableArray arrayWithArray:@[@0, @0]] atIndexedSubscript:j];
        [counts setObject:row atIndexedSubscript:i];
    }

    // iterate through the available EXTTerms and count up how many project onto
    // a given grid location.  (this is a necessary step for, e.g., EXTTriple-
    // graded spectral sequences, where many EXTLocations might end up in the
    // same place.)
    //
    // TODO: the way this is set up does not allow EXTTerms to determine how
    // they get drawn.  this will probably need to be changed when we move to
    // Z-mods, since those have lots of interesting quotients which need to
    // represented visually.
    for (EXTTerm *term in _document.sseq.terms.allValues) {
        NSPoint point = [[term location] makePoint];

        if (point.x >= lowerLeft.x && point.x <= upperRight.x &&
            point.y >= lowerLeft.y && point.y <= upperRight.y) {
            NSMutableArray *column = (NSMutableArray*)counts[(int)(point.x-lowerLeft.x)];
            NSMutableArray *tuple = column[(int)(point.y-lowerLeft.y)];
            int offset = [tuple[0] intValue];
            tuple[0] = @(offset + [term dimension:pageNumber]);
        }
    }

    // actually loop through the available positions and perform the draw.
    CGContextRef currentCGContext = [[NSGraphicsContext currentContext] graphicsPort];
    CGRect layerFrame = {.size = {spacing, spacing}};
    
    for (int i = (int)lowerLeft.x; i <= upperRight.x; i++) {
        NSArray *column = (NSArray*)counts[i - (int)lowerLeft.x];
        for (int j = (int)lowerLeft.y; j <= upperRight.y; j++) {
            NSArray *tuple = column[j - (int)lowerLeft.y];
            int count = [tuple[0] intValue];

            if (count == 0)
                continue;

            CGLayerRef dotLayer = [[self class] newDotLayerForCount:count];
            layerFrame.origin = (CGPoint){i * spacing, j * spacing};
            CGContextDrawLayerInRect(currentCGContext, layerFrame, dotLayer);
            CGLayerRelease(dotLayer);
        }
    }

    // iterate also through the available differentials
    if (pageNumber >= _document.sseq.differentials.count)
        return;

    [[NSColor blackColor] set];
    for (EXTDifferential *differential in ((NSDictionary*)_document.sseq.differentials[pageNumber]).allValues) {
        // some sanity checks to make sure this differential is worth drawing
        if ([differential page] != pageNumber)
            continue;

        NSPoint start = [differential.start.location makePoint],
        end = [differential.end.location makePoint];
        if (((start.x < lowerLeft.x || start.x > upperRight.x) ||
             (start.y < lowerLeft.y || start.y > upperRight.y)) &&
            ((end.x < lowerLeft.x || end.x > upperRight.x) ||
             (end.y < lowerLeft.y || end.y > upperRight.y)))
            continue;

        int imageSize = [differential.presentation image].count;
        if ((imageSize == 0) ||
            ([differential.start dimension:differential.page] == 0) ||
            ([differential.end dimension:differential.page] == 0))
            continue;

        // figure out the various parameters needed to build the draw commands:
        // where the dots are, how many there are, and so on.
        NSMutableArray
        *startPosition = [NSMutableArray arrayWithArray:@[@0, @0]],
        *endPosition = [NSMutableArray arrayWithArray:@[@0, @0]];

        if (start.x >= lowerLeft.x && start.x <= upperRight.x &&
            start.y >= lowerLeft.y && start.y <= upperRight.y) {
            NSMutableArray *column = (NSMutableArray*)counts[(int)(start.x-lowerLeft.x)];
            if ((int)(start.y-lowerLeft.y) < height)
                startPosition = column[(int)(start.y-lowerLeft.y)];
        }

        if (end.x >= lowerLeft.x && end.x <= upperRight.x &&
            end.y >= lowerLeft.y && end.y <= upperRight.y) {
            NSMutableArray *column = (NSMutableArray*)counts[(int)(end.x-lowerLeft.x)];
            if ((int)(end.y-lowerLeft.y) < height)
                endPosition = column[(int)(end.y-lowerLeft.y)];
        }

        NSPoint pointStart = [differential.start.location makePoint],
        pointEnd = [differential.end.location makePoint];

        NSArray *startRects = [[self class] dotPositionsForCount:[startPosition[0] intValue]
                                                               x:pointStart.x
                                                               y:pointStart.y
                                                         spacing:spacing],
        *endRects = [[self class] dotPositionsForCount:[endPosition[0] intValue]
                                                     x:pointEnd.x
                                                     y:pointEnd.y
                                               spacing:spacing];

        for (int i = 0; i < imageSize; i++) {
            // get and update the offsets
            int startOffset = [startPosition[1] intValue],
            endOffset = [endPosition[1] intValue];
            startPosition[1] = @(startOffset+1);
            endPosition[1] = @(endOffset+1);

            // if they're out of bounds, which will happen in the >= 4 case,
            // just use the bottom one.
            if (startOffset >= startRects.count)
                startOffset = 0;
            if (endOffset >= endRects.count)
                endOffset = 0;

            NSRect startRect = [startRects[startOffset] rectValue],
            endRect = [endRects[endOffset] rectValue];

            NSBezierPath *line = [NSBezierPath bezierPath];
            [line moveToPoint:
             NSMakePoint(startRect.origin.x,
                         startRect.origin.y + startRect.size.height/2)];
            [line lineToPoint:
             NSMakePoint(endRect.origin.x + endRect.size.width,
                         endRect.origin.y + endRect.size.height/2)];
            [line setLineWidth:0.25];
            [line stroke];
        }
    }
    
    // TODO: draw certain multiplicative structures?
}

- (void)chartView:(EXTChartView *)chartView mouseDownAtGridLocation:(NSPoint)gridLocation {
    // TODO: lots!
    switch (chartView.selectedToolTag) {
        case _EXTDifferentialToolTag: {
            NSArray *diffls = [_document.sseq findDifflsSourcedUnderPoint:gridLocation onPage:chartView.selectedPageIndex];
            if (diffls.count == 1)
                self.selectedObject = diffls[0];
            else
                self.selectedObject = nil;
            
            break;
        }
            
        default:
            break;
    }
}

- (Class<EXTLocation>)indexClassForChartView:(EXTChartView *)chartView {
    return _document.sseq.indexClass;
}


#pragma mark - Drawing support

// TODO: Talk to Eric about creating an NS_INLINE NSValue *_EXTDotRect() function
+ (NSArray *)dotPositionsForCount:(int)count
                                x:(CGFloat)x
                                y:(CGFloat)y
                          spacing:(CGFloat)spacing {

    switch (count) {
        case 1:
            return @[[NSValue valueWithRect:
                      NSMakeRect(x*spacing + 2.0/6.0*spacing,
                                 y*spacing + 2.0/6.0*spacing,
                                 2.0*spacing/6.0,
                                 2.0*spacing/6.0)]];

        case 2:
            return @[[NSValue valueWithRect:
                      NSMakeRect(x*spacing + 1.0/6.0*spacing,
                                 y*spacing + 1.0/6.0*spacing,
                                 2.0*spacing/6.0,
                                 2.0*spacing/6.0)],
                     [NSValue valueWithRect:
                      NSMakeRect(x*spacing + 3.0/6.0*spacing,
                                 y*spacing + 3.0/6.0*spacing,
                                 2.0*spacing/6.0,
                                 2.0*spacing/6.0)]];

        case 3:
            return @[[NSValue valueWithRect:
                      NSMakeRect(x*spacing + 0.66/6.0*spacing,
                                 y*spacing + 1.0/6.0*spacing,
                                 2.0*spacing/6.0,
                                 2.0*spacing/6.0)],
                     [NSValue valueWithRect:
                      NSMakeRect(x*spacing + 2.0/6.0*spacing,
                                 y*spacing + 3.0/6.0*spacing,
                                 2.0*spacing/6.0,
                                 2.0*spacing/6.0)],
                     [NSValue valueWithRect:
                      NSMakeRect(x*spacing + 3.33/6.0*spacing,
                                 y*spacing + 1.0/6.0*spacing,
                                 2.0*spacing/6.0,
                                 2.0*spacing/6.0)]];

        default:
            return @[[NSValue valueWithRect:
                      NSMakeRect(x*spacing+0.15*spacing,
                                 y*spacing+0.15*spacing,
                                 0.7*spacing,
                                 0.7*spacing)]];
    }
}

+ (CGLayerRef)newDotLayerForCount:(int)count {
    CGLayerRef layer = (__bridge CGLayerRef)[_EXTLayerCache objectForKey:@(count)];
    if (layer)
        return CGLayerRetain(layer);

    // Since dot layers contain vectors only, we can draw them with fixed size and let Quartz
    // scale layers when needed
    const CGFloat spacing = 9.0;
    const CGSize size = {spacing, spacing};
    const CGRect frame = {.size = size};

    NSMutableData *PDFData = [NSMutableData data];
    CGDataConsumerRef dataConsumer = CGDataConsumerCreateWithCFData((__bridge CFMutableDataRef)PDFData);
    CGContextRef PDFContext = CGPDFContextCreate(dataConsumer, &frame, NULL);

    layer = CGLayerCreateWithContext(PDFContext, size, NULL);
    CGContextRef layerContext = CGLayerGetContext(layer);

    NSGraphicsContext *drawingContext = [NSGraphicsContext graphicsContextWithGraphicsPort:layerContext flipped:NO];
    [NSGraphicsContext saveGraphicsState];
    [NSGraphicsContext setCurrentContext:drawingContext];
    CGContextBeginPage(PDFContext, &frame);
    {
        NSArray *dotPositions = [[self class] dotPositionsForCount:count x:0.0 y:0.0 spacing:spacing];

        if (count <= 3) {
            NSBezierPath *path = [NSBezierPath bezierPath];
            for (NSValue *rectObject in dotPositions)
                [path appendBezierPathWithOvalInRect:[rectObject rectValue]];
            [path fill];
        }
        else {
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

            const NSRect drawingFrame = [dotPositions[0] rectValue];
            [[NSBezierPath bezierPathWithOvalInRect:drawingFrame] stroke];

            NSRect textFrame = drawingFrame;
            textFrame.origin.y += 0.05 * spacing;
            NSString *label = [NSString stringWithFormat:@"%d", count];
            [label drawInRect:textFrame withAttributes:(label.length == 1 ? singleDigitAttributes : multiDigitAttributes)];

        }
    }
    CGContextEndPage(PDFContext);
    CGPDFContextClose(PDFContext);
    CGContextRelease(PDFContext);
    CGDataConsumerRelease(dataConsumer);
    [NSGraphicsContext restoreGraphicsState];

    [_EXTLayerCache setObject:(__bridge id)layer forKey:@(count)];

    return layer;
}

@end
