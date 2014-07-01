//
//  EXTChartView.m
//  Ext Chart
//
//  Created by Michael Hopkins on 7/20/11.
//  Copyright 2011 Harvard University. All rights reserved.
//

#import "EXTChartView.h"
#import "EXTScrollView.h"
#import "EXTGrid.h"
#import "EXTArtBoard.h"
#import "NSUserDefaults+EXTAdditions.h"


#pragma mark - Exported variables

NSString * const EXTChartViewHighlightColorPreferenceKey = @"EXTChartViewHighlightColor";


#pragma mark - Private variables

static void *_EXTChartViewArtBoardDrawingRectContext = &_EXTChartViewArtBoardDrawingRectContext;
static void *_EXTChartViewGridAnyKeyContext = &_EXTChartViewGridAnyKeyContext;
static void *_EXTChartViewGridSpacingContext = &_EXTChartViewGridSpacingContext;

static CGFloat const _EXTHighlightLineWidth = 0.5;


@interface EXTChartView () {
	NSTrackingArea *_trackingArea;
	NSBezierPath *_highlightPath;
}
@end


@implementation EXTChartView

#pragma mark - Life cycle

+ (void)load {
    [self exposeBinding:@"grid"];
    [self exposeBinding:@"highlightColor"];

    NSColor *highlightColor = [NSColor colorWithCalibratedRed:0.0 green:1.0 blue:1.0 alpha:1.0];
    NSDictionary *defaults = @{EXTChartViewHighlightColorPreferenceKey : [NSArchiver archivedDataWithRootObject:highlightColor]};
    [[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
}

- (instancetype)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
		[self translateOriginToPoint:NSMakePoint(NSMidX(frame), NSMidY(frame))];

        // Grid
        {
            _showsGrid = true;

            _grid = [EXTGrid new];
            [_grid setBoundsRect:[self bounds]];
            [_grid addObserver:self forKeyPath:EXTGridAnyKey options:0 context:_EXTChartViewGridAnyKeyContext];
            [_grid addObserver:self forKeyPath:@"gridSpacing" options:0 context:_EXTChartViewGridSpacingContext];
        }

        // Art board
        {
            _artBoard = [EXTArtBoard new];
            [self _extAlignArtBoardToGrid];
            [self _extUpdateArtBoardMinimumSize];

            // Since the frame extends past the bounds rectangle, we need observe the drawingRect in order to know what to refresh when the artBoard changes
            [_artBoard addObserver:self forKeyPath:@"drawingRect" options:NSKeyValueObservingOptionOld context:_EXTChartViewArtBoardDrawingRectContext];
        }

        // Highlighting
		{
            _highlightsGridPositionUnderCursor = true;
            _highlightColor = [[NSUserDefaults standardUserDefaults] extColorForKey:EXTChartViewHighlightColorPreferenceKey];
        }
    }

	return self;
}

- (void)dealloc {
    [_artBoard removeObserver:self forKeyPath:@"drawingRect" context:_EXTChartViewArtBoardDrawingRectContext];
    [_grid removeObserver:self forKeyPath:EXTGridAnyKey context:_EXTChartViewGridAnyKeyContext];
    [_grid removeObserver:self forKeyPath:@"gridSpacing" context:_EXTChartViewGridSpacingContext];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Drawing

- (void)drawRect:(NSRect)dirtyRect {
    // View background
    NSDrawWindowBackground(dirtyRect);

    // Art board background
	[_artBoard fillRect]; // TODO: draw only the intersection of rect and the art board

    // Grid
	if (_showsGrid)
		[_grid drawGridInRect:dirtyRect];

    // Art board borders
    // If we aren’t drawing to the screen (e.g., when exporting the art board as PDF), the
    // art board looks nicer without a shadow
    [_artBoard setHasShadow:[[NSGraphicsContext currentContext] isDrawingToScreen]];
	[_artBoard strokeRect];   // we're drawing the entire artboard frame.   probably OK.

	// Axes
	[_grid drawAxes];

	// Highlight rectangle. The highlightPath is stored, so we can correctly determine dirty rectangles.
    // It is generated by a class method in the EXTTerm and EXTDifferential classes.
	if (self.highlightsGridPositionUnderCursor && _highlightPath && [self needsToDrawRect:[self _extHighlightDrawingRect]]) {
		[_highlightColor setStroke];
		[_highlightPath stroke];
	}

	//	At this point I'd like to switch to a coordinate system with a user specified origin, and scaled so that the grid is 1 by 1.

	//	NSGraphicsContext* theContext = [NSGraphicsContext currentContext];
	//	[theContext saveGraphicsState];
	//
	//	//introduce a transformation matrix here
	//	NSAffineTransform* xform = [NSAffineTransform transform];
	//	[xform translateXBy:72.0 yBy:72.0];
	//	[xform concat];

    if (!self.dataSource) return;

    // Tint the grid square(s) where the selected object lie(s)
    NSArray *backgroundRects = [self.dataSource chartViewBackgroundRectsForSelectedObject:self];
    for (NSValue *rectValue in backgroundRects) {
        const NSRect rect = rectValue.rectValue;
        const CGFloat selectionInset = 0.25;

        if ([self needsToDrawRect:rect]) {
            NSColor *colour = [self.highlightColor blendedColorWithFraction:0.8 ofColor:NSColor.whiteColor];
            [colour setFill];
            const NSRect insetRect = NSInsetRect(rect, selectionInset, selectionInset);
            NSRectFill(insetRect);
        }
    }

    // actually loop through the available positions and perform the draw.
    const EXTIntRect gridRect = [self.grid convertRectFromView:dirtyRect];
    CGContextRef currentCGContext = [[NSGraphicsContext currentContext] graphicsPort];
    CGRect layerFrame = {.size = {self.grid.gridSpacing, self.grid.gridSpacing}};

    NSArray *counts = [self.dataSource chartView:self termCountsInGridRect:gridRect];
    for (EXTChartViewTermCountData *countData in counts) {
        CGLayerRef dotLayer = [self.dataSource chartView:self layerForTermCount:countData.count];
        layerFrame.origin = (CGPoint){countData.point.x * self.grid.gridSpacing, countData.point.y * self.grid.gridSpacing};
        CGContextDrawLayerInRect(currentCGContext, layerFrame, dotLayer);
    }

    // iterate also through the available differentials
    NSArray *differentials = [self.dataSource chartView:self differentialsInRect:dirtyRect];

    //    const bool differentialSelected = (differential == _selectedObject);
    //    if (differentialSelected)
    //        [[[self chartView] highlightColor] set];
    //    else
    //        [[NSColor blackColor] set];

    [[NSColor blackColor] set];
    NSBezierPath *line = [NSBezierPath bezierPath];
    [line setLineWidth:0.25];
    [line setLineCapStyle:NSRoundLineCapStyle];
    for (EXTChartViewDifferentialData *diffData in differentials) {
        [line moveToPoint:diffData.start];
        [line lineToPoint:diffData.end];
    }
    [line stroke];

    // TODO: draw certain multiplicative structures?
    
    // this is an array of dictionaries: {"style", array of
    NSArray *multAnnotationsData = [self.dataSource chartView:self multAnnotationsInRect:dirtyRect];
    for (NSDictionary *annotationGroup in multAnnotationsData) {
        NSArray *multAnnotations = annotationGroup[@"annotations"];
        
        // TODO: eventually we will want to read the style we're supposed to
        // draw these multiplications in from the "style" key of the dicationary
        
        [[NSColor blackColor] set];
        NSBezierPath *line = [NSBezierPath bezierPath];
        [line setLineWidth:0.25];
        [line setLineCapStyle:NSRoundLineCapStyle];
        
        for (EXTChartViewMultAnnotationData *annoData in multAnnotations) {
            [line moveToPoint:annoData.start];
            [line lineToPoint:annoData.end];
        }
    }

    // TODO: draw highlighted object.

    // Draw marquees
//    const NSRect dirtyRect = [self.chartView.grid convertRectToView:gridRect];
//    for (EXTMarquee *marquee in _document.marquees) {
//        if (!NSIntersectsRect(dirtyRect, marquee.frame))
//            continue;
//
//        // Images take precedence over text
//        if (marquee.image)
//            [marquee.image drawInRect:marquee.frame fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
//        else
//            [marquee.string drawInRect:marquee.frame withAttributes:nil];
//    }
//
//    if ([self.selectedObject isKindOfClass:[EXTMarquee class]]) {
//        EXTMarquee *selectedMarquee = self.selectedObject;
//        [self.chartView.highlightColor setFill];
//        NSFrameRect(selectedMarquee.frame);
//    }

    //  // restore the graphics context
    //	[theContext restoreGraphicsState];
}

- (void)resetHighlightPath {
    if (_highlightPath)
        [self setNeedsDisplayInRect:[self _extHighlightDrawingRect]];

    const NSRect dataRect = [_trackingArea rect];
    const NSPoint currentMouseLocation = [self convertPoint:[[self window] mouseLocationOutsideOfEventStream] fromView:nil];
    if (NSPointInRect(currentMouseLocation, dataRect)) {
        const EXTIntPoint mouseLocationInGrid = [_grid convertPointFromView:currentMouseLocation];
        _highlightPath = [self.dataSource chartView:self highlightPathForToolAtGridLocation:mouseLocationInGrid];
        [_highlightPath setLineWidth:_EXTHighlightLineWidth];
        [self setNeedsDisplayInRect:[self _extHighlightDrawingRect]];
    }
    else {
        _highlightPath = nil;
    }
}

- (NSRect)_extHighlightDrawingRect {
    const CGFloat halfLineWidth = _EXTHighlightLineWidth / 2;
    return NSInsetRect([_highlightPath bounds], -halfLineWidth, -halfLineWidth);
}

#pragma mark - Properties

- (void)setShowsGrid:(bool)showsGrid {
    if (showsGrid != _showsGrid) {
        _showsGrid = showsGrid;
        [self setNeedsDisplay:YES];
    }
}

- (void)setHighlightsGridPositionUnderCursor:(bool)highlightsGridPositionUnderCursor {
    if (highlightsGridPositionUnderCursor != _highlightsGridPositionUnderCursor) {
        _highlightsGridPositionUnderCursor = highlightsGridPositionUnderCursor;
        [self setNeedsDisplayInRect:[self _extHighlightDrawingRect]];
    }
}

- (void)setArtBoardGridFrame:(EXTIntRect)artBoardGridFrame {
    _artBoardGridFrame = artBoardGridFrame;
    [self _extAlignArtBoardToGrid];
}

- (BOOL)isOpaque {
    return YES;
}

- (BOOL)wantsDefaultClipping {
    return NO;
}

- (BOOL)acceptsFirstResponder {
    return YES;
}

- (BOOL)acceptsTouchEvents {
    return YES;
}

#pragma mark - Paging

// This is odd: we do not receive -swipeWithEvent: until the user scrolls the
// view using a two-finger scroll gesture. This same behaviour happens if the
// scroll view implements -swipeWithEvent:.
// See http://stackoverflow.com/questions/15854301
- (void)swipeWithEvent:(NSEvent *)event {
	CGFloat x = [event deltaX];
    if (x > 0.0)
        [NSApp sendAction:@selector(nextPage:) to:nil from:self];
    else if (x < 0.0)
        [NSApp sendAction:@selector(previousPage:) to:nil from:self];
}

#pragma mark - Key-value observing

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	if (context == _EXTChartViewArtBoardDrawingRectContext) {
        [self setNeedsDisplayInRect:NSUnionRect([change[NSKeyValueChangeOldKey] rectValue], [_artBoard drawingRect])];
        if (self.editingArtBoard)
            [[self window] invalidateCursorRectsForView:self];
	}
	else if (context == _EXTChartViewGridAnyKeyContext) {
		[self setNeedsDisplay:YES];
	}
    else if (context == _EXTChartViewGridSpacingContext) {
        [self _extAlignArtBoardToGrid];
        [self _extUpdateArtBoardMinimumSize];
    }
	else {
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}

#pragma mark - Zooming and scrolling

- (IBAction)zoomToFit:(id)sender {
    const NSRect artBoardRect = [_artBoard frame];
    [[self enclosingScrollView] magnifyToFitRect:artBoardRect];
    [self scrollPoint:artBoardRect.origin];
}

- (NSRect)rectForSmartMagnificationAtPoint:(NSPoint)location inRect:(NSRect)visibleRect {
    return [_artBoard frame];
}

#pragma mark - Mouse tracking and cursor

- (void)resetCursorRects {
	if (self.editingArtBoard)
		[_artBoard buildCursorRectsInView:self];
}

- (void)_extDragArtBoardWithEvent:(NSEvent *)event {
	// ripped off from sketch.   according to apple's document, it is better not to override the event loop like this.  Also, see the DragItemAround code for what I think is a better way to organize this.

    const NSRect originalVisibleRect = [[self enclosingScrollView] documentVisibleRect];
    NSPoint lastPoint = [_grid convertPointToView:[_grid nearestGridPoint:[self convertPoint:[event locationInWindow] fromView:nil]]];

    [_artBoard startDragOperationAtPoint:lastPoint];

    bool (^isEscapeKeyEvent)(NSEvent *) = ^bool (NSEvent *event) {
        return [event type] == NSKeyDown && [event keyCode] == 53;
    };

    // Since we are sequestering event loop processing, check for the Escape key here to cancel the drag operation
	while ([event type] != NSLeftMouseUp && !isEscapeKeyEvent(event)) {
		event = [[self window] nextEventMatchingMask:(NSLeftMouseDraggedMask | NSLeftMouseUpMask | NSKeyDownMask)];
        const NSPoint currentPoint = [_grid convertPointToView:[_grid nearestGridPoint:[self convertPoint:[event locationInWindow] fromView:nil]]];

        if ([event type] == NSLeftMouseDragged) {
            if (! NSEqualPoints(lastPoint, currentPoint)) {
                [_artBoard performDragOperationWithPoint:currentPoint];
                lastPoint = currentPoint;
            }
            [self autoscroll:event];
        }
	}

    if (isEscapeKeyEvent(event)) {
        [_artBoard cancelDragOperation];
        [self scrollRectToVisible:originalVisibleRect];
    }

    [_artBoard finishDragOperation];
}

- (void)mouseDown:(NSEvent *)event {
	const NSPoint location = [self convertPoint:[event locationInWindow] fromView:nil];

    if (self.editingArtBoard) {
        const EXTArtBoardMouseDragOperation artBoardDragOperation = [_artBoard mouseDragOperationAtPoint:location];
        if (artBoardDragOperation != EXTArtBoardMouseDragOperationNone) {
            [self _extDragArtBoardWithEvent:event];
        }
	}
    else {
        [_delegate chartView:self mouseDownAtGridLocation:[_grid convertPointFromView:location]];
        [self setNeedsDisplayInRect:[self _extHighlightDrawingRect]]; // TODO: is this necessary?
	}
}

- (void)mouseMoved:(NSEvent *)event {
    [self resetHighlightPath];
}

- (void)mouseEntered:(NSEvent *)event {
    [self resetHighlightPath];
}

- (void)mouseExited:(NSEvent *)event {
    [self resetHighlightPath];
}

- (void)updateTrackingAreas {
    [super updateTrackingAreas];

    if (_trackingArea)
        [self removeTrackingArea:_trackingArea];

    _trackingArea = [[NSTrackingArea alloc] initWithRect:[self visibleRect]
                                                 options:(NSTrackingMouseEnteredAndExited | NSTrackingMouseMoved | NSTrackingActiveInKeyWindow)
                                                   owner:self
                                                userInfo:nil];
    [self addTrackingArea:_trackingArea];
    [self resetHighlightPath];
}

#pragma mark - Art board

// Given _artBoardGridFrame in grid coordinate space, set EXTArtBoard.frame to the
// corresponding frame in view coordinate space
- (void)_extAlignArtBoardToGrid {
    // Make sure the art board grid frame has positive width and height
    _artBoardGridFrame.size.width = MAX(1, _artBoardGridFrame.size.width);
    _artBoardGridFrame.size.height = MAX(1, _artBoardGridFrame.size.height);

    const EXTIntPoint upperRightInGrid = EXTIntUpperRightPointOfRect(_artBoardGridFrame);
    const NSPoint lowerLeftInView = [_grid convertPointToView:_artBoardGridFrame.origin];
    const NSPoint upperRightInView = [_grid convertPointToView:upperRightInGrid];
    const NSRect artBoardFrame = {
        .origin = lowerLeftInView,
        .size.width = upperRightInView.x - lowerLeftInView.x,
        .size.height = upperRightInView.y - lowerLeftInView.y
    };

    [_artBoard setFrame:artBoardFrame];
}

- (void)_extUpdateArtBoardMinimumSize {
    // If grid spacing is big enough, the art board’s minimum size is a 1x1 grid square.
    // Otherwise, we set an NxN grid square that can still be handled gracefully when
    // resizing or moving the art board.
    static const CGFloat _EXTMinimumLength = 5.0;
    
    const CGFloat gridSpacing = [_grid gridSpacing];
    NSSize minimumSize = {gridSpacing, gridSpacing};

    if (gridSpacing < _EXTMinimumLength) {
        const CGFloat newMinimumLength = ceil(_EXTMinimumLength / gridSpacing) * gridSpacing;
        minimumSize.width = minimumSize.height = newMinimumLength;
    }

    [_artBoard setMinimumSize:minimumSize];
}

#pragma mark - Resizing

// Chart views shouldn’t be resized. However, it seems that Restoration changes the chart view frame as part of
// the enclosing scrollview subview autoresizing process. We simply ignore this when it happens.
- (void)resizeWithOldSuperviewSize:(NSSize)oldSize {
    // Do nothing
}

#pragma mark - NSUserInterfaceValidations

- (BOOL)validateUserInterfaceItem:(id<NSValidatedUserInterfaceItem>)item {
    
    return [self respondsToSelector:[item action]];
}

@end


@implementation EXTChartViewTermCountData
+ (instancetype)chartViewTermCountDataWithCount:(NSInteger)count atGridPoint:(EXTIntPoint)gridPoint
{
    EXTChartViewTermCountData *result = [self new];
    result.count = count;
    result.point = gridPoint;
    return result;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"Term count %ld at (%ld, %ld)", self.count, self.point.x, self.point.y];
}

- (BOOL)isEqual:(id)object
{
    EXTChartViewTermCountData *other = object;
    return ([other isKindOfClass:[EXTChartViewTermCountData class]] &&
            other.count == _count &&
            other.point.x == _point.x &&
            other.point.y == _point.y);

}

- (NSUInteger)hash
{
    return NSUINTROTATE(((NSUInteger)_point.x), NSUINT_BIT / 2) ^ _point.y ^ _count;
}
@end


@implementation EXTChartViewDifferentialData
+ (instancetype)chartViewDifferentialDataWithStart:(NSPoint)start end:(NSPoint)end
{
    EXTChartViewDifferentialData *result = [self new];
    result.start = start;
    result.end = end;
    return result;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"Differential from %@ to %@", NSStringFromPoint(self.start), NSStringFromPoint(self.end)];
}

- (BOOL)isEqual:(id)object
{
    EXTChartViewDifferentialData *other = object;
    return ([other isKindOfClass:[EXTChartViewDifferentialData class]] &&
            NSEqualPoints(other.start, _start) &&
            NSEqualPoints(other.end, _end));
}

- (NSUInteger)hash
{
    return (NSUINTROTATE(((NSUInteger)_start.x), NSUINT_BIT / 2) ^ (NSUInteger)_start.y ^
            NSUINTROTATE(((NSUInteger)_end.y), NSUINT_BIT / 2) ^ (NSUInteger)_end.x);
}
@end

@implementation EXTChartViewMultAnnotationData
+ (instancetype)chartViewMultAnnotationDataWithStart:(NSPoint)start end:(NSPoint)end
{
    EXTChartViewMultAnnotationData *result = [self new];
    result.start = start;
    result.end = end;
    return result;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"Annotation from %@ to %@", NSStringFromPoint(self.start), NSStringFromPoint(self.end)];
}

- (BOOL)isEqual:(id)object
{
    EXTChartViewMultAnnotationData *other = object;
    return ([other isKindOfClass:[EXTChartViewMultAnnotationData class]] &&
            NSEqualPoints(other.start, _start) &&
            NSEqualPoints(other.end, _end));
}

- (NSUInteger)hash
{
    return (NSUINTROTATE(((NSUInteger)_start.x), NSUINT_BIT / 2) ^ (NSUInteger)_start.y ^
            NSUINTROTATE(((NSUInteger)_end.y), NSUINT_BIT / 2) ^ (NSUInteger)_end.x);
}
@end
