//
//  EXTChartViewController.m
//  Ext Chart
//
//  Created by Bavarious on 10/08/2013.
//  Copyright (c) 2013 Harvard University. All rights reserved.
//

#import "EXTChartViewController.h"
#import "EXTChartView.h"
#import "EXTGrid.h"
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

- (void)setSelectedObject:(id)selectedObject {
    if (selectedObject == _selectedObject)
        return;

    EXTChartView *chartView = [self chartView];
    [chartView setNeedsDisplayInRect:[self _extBoundingRectForObject:_selectedObject]]; // clear the previous selection
    _selectedObject = selectedObject;
    [chartView setNeedsDisplayInRect:[self _extBoundingRectForObject:selectedObject]]; // draw the new selection
    
    return;
}

#pragma mark - EXTChartViewDelegate

- (void)chartView:(EXTChartView *)chartView willDisplayPage:(NSUInteger)pageNumber {
    [_document.sseq computeGroupsForPage:pageNumber];
}

// this performs the culling and delegation calls for drawing a page of the SS
- (void)chartView:(EXTChartView *)chartView drawPageNumber:(const NSUInteger)pageNumber inGridRect:(const EXTIntRect)gridRect {
    // start by initializing the array of counts
    NSMutableArray *counts = [NSMutableArray arrayWithCapacity:gridRect.size.width];
    for (int i = 0; i < gridRect.size.width; i++) {
        NSMutableArray *row = [NSMutableArray arrayWithCapacity:gridRect.size.height];
        for (int j = 0; j < gridRect.size.height; j++)
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
        EXTIntPoint point = [[term location] gridPoint];

        if (EXTIntPointInRect(point, gridRect)) {
            NSMutableArray *column = (NSMutableArray*)counts[(int)(point.x-gridRect.origin.x)];
            NSMutableArray *tuple = column[(int)(point.y-gridRect.origin.y)];
            int offset = [tuple[0] intValue];
            tuple[0] = @(offset + [term dimension:pageNumber]);
        }
    }

    // Draw grid square selection background if needed
    if (_selectedObject) {
        if ([_selectedObject isKindOfClass:[EXTTerm class]]) {
            [self _extDrawGridSelectionBackgroundForTerm:_selectedObject inGridRect:gridRect];
        }
        else if ([_selectedObject isKindOfClass:[EXTDifferential class]]) {
            EXTDifferential *selectedDifferential = _selectedObject;
            [self _extDrawGridSelectionBackgroundForTerm:[selectedDifferential start] inGridRect:gridRect];
            [self _extDrawGridSelectionBackgroundForTerm:[selectedDifferential end] inGridRect:gridRect];
        }
    }

    // actually loop through the available positions and perform the draw.
    const CGFloat gridSpacing = [[[self chartView] grid] gridSpacing];
    const EXTIntPoint upperRight = EXTIntUpperRightPointOfRect(gridRect);
    CGContextRef currentCGContext = [[NSGraphicsContext currentContext] graphicsPort];
    CGRect layerFrame = {.size = {gridSpacing, gridSpacing}};
    
    for (NSInteger i = gridRect.origin.x; i < upperRight.x; i++) {
        NSArray *column = (NSArray *)counts[i - gridRect.origin.x];
        for (NSInteger j = gridRect.origin.y; j < upperRight.y; j++) {
            NSArray *tuple = column[j - gridRect.origin.y];
            int count = [tuple[0] intValue];

            if (count == 0)
                continue;

            CGLayerRef dotLayer = [self newDotLayerForCount:count];
            layerFrame.origin = (CGPoint){i * gridSpacing, j * gridSpacing};
            CGContextDrawLayerInRect(currentCGContext, layerFrame, dotLayer);
            CGLayerRelease(dotLayer);
        }
    }

    // iterate also through the available differentials
    if (pageNumber >= _document.sseq.differentials.count)
        return;

    for (EXTDifferential *differential in ((NSDictionary*)_document.sseq.differentials[pageNumber]).allValues) {
        // some sanity checks to make sure this differential is worth drawing
        if ([differential page] != pageNumber)
            continue;

        const EXTIntPoint startPoint = differential.start.location.gridPoint;
        const EXTIntPoint endPoint = differential.end.location.gridPoint;
        const bool startPointInGridRect = EXTIntPointInRect(startPoint, gridRect);
        const bool endPointInGridRect = EXTIntPointInRect(endPoint, gridRect);
        if (!startPointInGridRect && !endPointInGridRect)
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

        if (EXTIntPointInRect(startPoint, gridRect)) {
            NSMutableArray *column = (NSMutableArray*)counts[startPoint.x - gridRect.origin.x];
            const NSInteger startPointYOffset = startPoint.y - gridRect.origin.y;
            NSAssert(startPointYOffset < gridRect.size.height, @"start point is not in grid rect; potential index out of bounds doom");
            startPosition = column[startPointYOffset];
        }

        if (EXTIntPointInRect(endPoint, gridRect)) {
            NSMutableArray *column = (NSMutableArray*)counts[endPoint.x - gridRect.origin.x];
            const NSInteger endPointYOffset = endPoint.y - gridRect.origin.y;
            NSAssert(endPointYOffset < gridRect.size.height, @"end point is not in grid rect; potential index out of bounds doom");
            endPosition = column[endPointYOffset];
        }

        NSArray *startRects = [self dotPositionsForCount:[startPosition[0] intValue] atGridPoint:startPoint];
        NSArray *endRects = [self dotPositionsForCount:[endPosition[0] intValue] atGridPoint:endPoint];

        const bool differentialSelected = (differential == _selectedObject);
        
        if (differentialSelected)
            [[[self chartView] highlightColor] set];
        else
            [[NSColor blackColor] set];

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
            // TODO: this next line draws OK, but it's not morally upright.
            [line lineToPoint:
             NSMakePoint(endRect.origin.x + endRect.size.width - 0.1*gridSpacing,
                         endRect.origin.y + endRect.size.height/2)];
            [line setLineWidth:(differentialSelected ? 1.0 : 0.25)];
            [line setLineCapStyle:NSRoundLineCapStyle];
            [line stroke];
        }
    }
    
    // TODO: draw certain multiplicative structures?
    
    // TODO: draw highlighted object.
}

- (void)chartView:(EXTChartView *)chartView mouseDownAtGridLocation:(EXTIntPoint)gridLocation {
    // TODO: lots!
    switch (chartView.selectedToolTag) {
        case _EXTDifferentialToolTag: {
            NSArray *terms = [_document.sseq findTermsUnderPoint:gridLocation];
            NSUInteger oldIndex = NSNotFound;
            NSUInteger page = self.chartView.selectedPageIndex;
            
            // if there's nothing under this click, just quit now.
            if (terms.count == 0) {
                self.selectedObject = nil;
                return;
            }
            
            // if we used to have something selected, and it was a differential
            // on this page, then we should find its position in our list.
            if ([[self.selectedObject class] isSubclassOfClass:[EXTDifferential class]] &&
                (((EXTDifferential*)self.selectedObject).page == page))
                oldIndex = [terms indexOfObject:((EXTDifferential*)self.selectedObject).start];
            
            // the new index is one past the old index, unless we have to wrap.
            int newIndex = oldIndex;
            EXTTerm *source = nil, *end = nil;
            EXTDifferential *diff = nil;
            if (oldIndex == NSNotFound) {
                oldIndex = 0;
                newIndex = 0;
            }
            do {
                if (newIndex == (terms.count - 1))
                    newIndex = 0;
                else
                    newIndex = newIndex + 1;
                source = terms[newIndex];
                diff = [_document.sseq findDifflWithSource:source.location onPage:page];
                
                // if we've found it, good!  quit!
                if (diff) {
                    self.selectedObject = diff;
                    break;
                }
                
                // if there's no differential, then let's try to build it.
                EXTLocation *endLoc = [[source.location class] followDiffl:source.location page:page];
                end = [_document.sseq findTerm:endLoc];
                
                if (end) {
                    // but if there is, let's build it and set it up.
                    diff = [EXTDifferential newDifferential:source end:end page:page];
                    [_document.sseq addDifferential:diff];
                    self.selectedObject = diff;
                    break;
                }
                
                // if there's no target term, then this won't work, and we
                // should cycle.
            } while (newIndex != oldIndex);
            
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

/* Returns an array of NSValue-boxed rectangles. The number of elements in the array
 represents the number of dots should be drawn for a given (term) count at the grid
 square with origin at `point`. Each rectangle describes the position and size of the
 dot in user coordinate space. */
- (NSArray *)dotPositionsForCount:(int)count atGridPoint:(EXTIntPoint)point {
    const CGFloat gridSpacing = [[[self chartView] grid] gridSpacing];
    
    switch (count) {
        case 1:
            return @[[NSValue valueWithRect:
                      NSMakeRect(point.x*gridSpacing + 2.0/6.0*gridSpacing,
                                 point.y*gridSpacing + 2.0/6.0*gridSpacing,
                                 2.0*gridSpacing/6.0,
                                 2.0*gridSpacing/6.0)]];

        case 2:
            return @[[NSValue valueWithRect:
                      NSMakeRect(point.x*gridSpacing + 1.0/6.0*gridSpacing,
                                 point.y*gridSpacing + 1.0/6.0*gridSpacing,
                                 2.0*gridSpacing/6.0,
                                 2.0*gridSpacing/6.0)],
                     [NSValue valueWithRect:
                      NSMakeRect(point.x*gridSpacing + 3.0/6.0*gridSpacing,
                                 point.y*gridSpacing + 3.0/6.0*gridSpacing,
                                 2.0*gridSpacing/6.0,
                                 2.0*gridSpacing/6.0)]];

        case 3:
            return @[[NSValue valueWithRect:
                      NSMakeRect(point.x*gridSpacing + 0.66/6.0*gridSpacing,
                                 point.y*gridSpacing + 1.0/6.0*gridSpacing,
                                 2.0*gridSpacing/6.0,
                                 2.0*gridSpacing/6.0)],
                     [NSValue valueWithRect:
                      NSMakeRect(point.x*gridSpacing + 2.0/6.0*gridSpacing,
                                 point.y*gridSpacing + 3.0/6.0*gridSpacing,
                                 2.0*gridSpacing/6.0,
                                 2.0*gridSpacing/6.0)],
                     [NSValue valueWithRect:
                      NSMakeRect(point.x*gridSpacing + 3.33/6.0*gridSpacing,
                                 point.y*gridSpacing + 1.0/6.0*gridSpacing,
                                 2.0*gridSpacing/6.0,
                                 2.0*gridSpacing/6.0)]];

        default:
            return @[[NSValue valueWithRect:
                      NSMakeRect(point.x*gridSpacing+0.15*gridSpacing,
                                 point.y*gridSpacing+0.15*gridSpacing,
                                 0.7*gridSpacing,
                                 0.7*gridSpacing)]];
    }
}

- (CGLayerRef)newDotLayerForCount:(int)count {
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
        NSArray *dotPositions = [self dotPositionsForCount:count atGridPoint:(EXTIntPoint){0}];

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

- (void)_extDrawGridSelectionBackgroundForTerm:(EXTTerm *)term inGridRect:(EXTIntRect)gridRect {
    const CGFloat selectionInset = 0.25;

    if (EXTIntPointInRect(term.location.gridPoint, gridRect)) {
        NSColor *bgcolor = [[[self chartView] highlightColor] blendedColorWithFraction:0.8 ofColor:[NSColor whiteColor]];
        [bgcolor setFill];
        const NSRect squareSelection = NSInsetRect([self _extBoundingRectForTerm:term], selectionInset, selectionInset);
        NSRectFill(squareSelection);
    }
}

/* Returns the bounding rect of a given object in user coordinate space */
- (NSRect)_extBoundingRectForObject:(id)object {
    if ([object isKindOfClass:[EXTTerm class]]) {
        return [self _extBoundingRectForTerm:object];
    }
    else if ([object isKindOfClass:[EXTDifferential class]]) {
        EXTDifferential *differential = object;
        return NSUnionRect([self _extBoundingRectForTerm:[differential start]],
                           [self _extBoundingRectForTerm:[differential end]]);
    }

    return NSZeroRect;
}

- (NSRect)_extBoundingRectForTerm:(EXTTerm *)term {
    EXTChartView *chartView = [self chartView];
    const CGFloat spacing = [[chartView grid] gridSpacing];
    const EXTIntPoint gridLocation = term.location.gridPoint;
    const NSRect boundingRect = {
        .origin.x = gridLocation.x * spacing,
        .origin.y = gridLocation.y * spacing,
        .size.width = spacing,
        .size.height = spacing
    };

    return boundingRect;
}

@end
