//
//  EXTChartView.m
//  Ext Chart
//
//  Created by Michael Hopkins on 7/20/11.
//  Copyright 2011 Harvard University. All rights reserved.
//

#import "EXTChartView.h"
#import "EXTDocument.h"
#import "EXTScrollView.h"
#import "EXTGrid.h"
#import "EXTArtBoard.h"
#import "EXTTerm.h"
#import "EXTDifferential.h"
#import "EXTSpectralSequence.h"
#import "NSUserDefaults+EXTAdditions.h"


#pragma mark - Exported variables

NSString * const EXTChartViewSelectedPageIndexBindingName = @"selectedPageIndex";
NSString * const EXTChartViewHighlightColorPreferenceKey = @"EXTChartViewHighlightColor";


#pragma mark - Private variables

static void *_EXTChartViewSelectedPageIndexContext = &_EXTChartViewSelectedPageIndexContext;
static void *_EXTChartViewArtBoardDrawingRectContext = &_EXTChartViewArtBoardDrawingRectContext;
static void *_EXTChartViewGridAnyKeyContext = &_EXTChartViewGridAnyKeyContext;

static CGFloat const _EXTHighlightLineWidth = 0.5;


#pragma mark - Private functions

NS_INLINE Class _EXTClassFromToolTag(EXTToolboxTag tag) {
    switch (tag) {
        case _EXTSelectionToolTag:
            // TODO: this can’t be right
            return [EXTDifferential class];
        case _EXTGeneratorToolTag:
            return [EXTTerm class];
        case _EXTDifferentialToolTag:
            return [EXTDifferential class];
        default:
            return Nil;
    }
}


@interface EXTChartView () {
    NSRect _highlightRect;
	NSTrackingArea *_trackingArea;
	NSBezierPath *_hightlightPath;
}

@property(nonatomic, assign) bool highlighting;
@property(nonatomic, strong) NSBezierPath *highlightPath;
@end


@implementation EXTChartView

#pragma mark - Life cycle

+ (void)load {
    [self exposeBinding:EXTChartViewSelectedPageIndexBindingName];
    [self exposeBinding:@"grid"];
    [self exposeBinding:@"highlightColor"];

    NSColor *highlightColor = [NSColor colorWithCalibratedRed:0.0 green:1.0 blue:1.0 alpha:1.0];
    NSDictionary *defaults = @{EXTChartViewHighlightColorPreferenceKey : [NSArchiver archivedDataWithRootObject:highlightColor]};
    [[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
}

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
		[self translateOriginToPoint:NSMakePoint(NSMidX(frame), NSMidY(frame))];

        // Grid
        {
            _showsGrid = true;

            _grid = [EXTGrid new];
            [_grid setBoundsRect:[self bounds]];
            [_grid addObserver:self forKeyPath:EXTGridAnyKey options:0 context:_EXTChartViewGridAnyKeyContext];
        }

        // Art board
        {
            _artBoard = [EXTArtBoard new];

            // Since the frame extends past the bounds rectangle, we need observe the drawingRect in order to know what to refresh when the artBoard changes
            [_artBoard addObserver:self forKeyPath:@"drawingRect" options:NSKeyValueObservingOptionOld context:_EXTChartViewArtBoardDrawingRectContext];

            // Align the art board to the grid
            NSRect artBoardFrame = [_artBoard frame];
            artBoardFrame.origin = [_grid nearestGridPoint:artBoardFrame.origin];
            const NSPoint originOppositePoint = [_grid nearestGridPoint:(NSPoint){NSMaxX(artBoardFrame), NSMaxY(artBoardFrame)}];
            artBoardFrame.size.width = originOppositePoint.x - NSMinX(artBoardFrame);
            artBoardFrame.size.height = originOppositePoint.y - NSMinY(artBoardFrame);
            [_artBoard setFrame:artBoardFrame];
        }


        // Mouse tracking
		{
            // The tracking area should be set to the dataRect, which is still not implemented.
            NSRect dataRect = NSMakeRect(0, 0, 432, 432);

            _trackingArea = [[NSTrackingArea alloc] initWithRect:dataRect
                                                         options: (NSTrackingMouseEnteredAndExited | NSTrackingMouseMoved | NSTrackingActiveInKeyWindow )
                                                           owner:self
                                                        userInfo:nil];
            [self addTrackingArea:_trackingArea];
        }

        // Highlighting
		{
            _highlighting = true;
            _highlightColor = [[NSUserDefaults standardUserDefaults] extColorForKey:EXTChartViewHighlightColorPreferenceKey];
            _highlightRect = NSZeroRect; // we initialize the highlight rect to something stupid.   It will change before it is drawn.
            [self setHighlightPath:[NSBezierPath bezierPathWithRect:_highlightRect]];
        }
    }

	return self;
}

- (void)dealloc {
    [_artBoard removeObserver:self forKeyPath:@"drawingRect" context:_EXTChartViewArtBoardDrawingRectContext];
    [_grid removeObserver:self forKeyPath:EXTGridAnyKey context:_EXTChartViewGridAnyKeyContext];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Grid point conversion

// Converts user space coordinates to (p, q) coordinates
- (NSPoint)convertPointToGrid:(NSPoint)point {
    const CGFloat gridSpacing = [_grid gridSpacing];
    return (NSPoint){
        .x = floor(point.x / gridSpacing),
        .y = floor(point.y / gridSpacing)
    };
}

// Convert (p, q) coordinates to user space coordinates
- (NSPoint)convertPointFromGrid:(NSPoint)gridPoint {
    const CGFloat gridSpacing = [_grid gridSpacing];
    return (NSPoint){
        .x = gridPoint.x * gridSpacing,
        .y = gridPoint.y * gridSpacing
    };
}

#pragma mark - Drawing

- (void)drawRect:(NSRect)rect {
    // View background
    NSDrawWindowBackground(rect);

    // Art board background
	[_artBoard fillRect]; // TODO: draw only the intersection of rect and the art board

    // Grid
	if (_showsGrid)
		[_grid drawGridInRect:rect];

    // Art board borders
    // If we aren’t drawing to the screen (e.g., when exporting the art board as PDF), the
    // art board looks nicer without a shadow
    [_artBoard setHasShadow:[[NSGraphicsContext currentContext] isDrawingToScreen]];
	[_artBoard strokeRect];   // we're drawing the entire artboard frame.   probably OK.

	// Axes
	[_grid drawAxes];

	// Highlight rectangle. The highlightPath is stored, so we can correctly determine dirty rectangles.
    // It is generated by a class method in the EXTTerm and EXTDifferential classes.
	if (_highlighting) {
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


	// the code for the objects.
    const NSPoint lowerLeftPoint = rect.origin;
    const NSPoint upperRightPoint = {NSMaxX(rect), NSMaxY(rect)};

    // TODO: this may be drawing too narrow a window, resulting in blank Ext
    // charts if the scroll is dragged too slowly.
    [_delegate chartView:self
          drawPageNumber:_selectedPageIndex
               lowerLeft:[self convertPointToGrid:lowerLeftPoint]
              upperRight:[self convertPointToGrid:upperRightPoint]
             withSpacing:[_grid gridSpacing]];

    //  // restore the graphics context
    //	[theContext restoreGraphicsState];
}

- (NSRect)_extHighlightDrawingRect {
    const CGFloat halfLineWidth = _EXTHighlightLineWidth / 2;
    return NSInsetRect([_highlightPath bounds], -halfLineWidth, -halfLineWidth);
}

- (void)resetHighlightRectAtLocation:(NSPoint)location {
    // We're rebuilding the (small) highlightPath every time the mouse moves. Is it better to just translate it, if needed?
    // We could eliminate the currentTool's need to know about the grid by taking one path, and translating and scaling it.
    // That path could be a constant, so wouldn't need to be rebuilt.

    Class toolClass = _EXTClassFromToolTag(_selectedToolTag);
	NSBezierPath *newHighlightPath = [toolClass makeHighlightPathAtPoint:location
                                                                  onGrid:_grid
                                                                  onPage:_selectedPageIndex
                                                                locClass:[_delegate indexClassForChartView:self]];

    // We may be resetting the highlight because the mouse has moved, the page has changed, or the highlighting {true, false}
    // status has changed, so we always flag both the previous location and the new location as dirty.
    [self setNeedsDisplayInRect:[self _extHighlightDrawingRect]]; // old frame
    [self setHighlightPath:newHighlightPath];
    [self setNeedsDisplayInRect:[self _extHighlightDrawingRect]]; // new frame
}

- (void)displaySelectedPage {
    if (_highlighting) {
        NSPoint mousePoint = [[[self enclosingScrollView] window] mouseLocationOutsideOfEventStream];
        mousePoint = [self convertPoint:mousePoint fromView:nil];
        [self resetHighlightRectAtLocation:mousePoint];
    }

    [_delegate chartView:self willDisplayPage:_selectedPageIndex];
    [self setNeedsDisplay:YES];
}

#pragma mark - Properties

- (void)setSelectedPageIndex:(NSUInteger)selectedPageIndex {
    // TODO: should check whether the argument lies in {min, max} page indices
    if (selectedPageIndex != _selectedPageIndex) {
        _selectedPageIndex = selectedPageIndex;
        [self displaySelectedPage];
    }
}

- (void)setShowsGrid:(bool)showsGrid {
    if (showsGrid != _showsGrid) {
        _showsGrid = showsGrid;
        [self setNeedsDisplay:YES];
    }
}

- (void)setSelectedToolTag:(EXTToolboxTag)selectedToolTag {
    if (selectedToolTag != _selectedToolTag) {
        [[self window] invalidateCursorRectsForView:self];
        [self setHighlighting:selectedToolTag != _EXTArtboardToolTag];

        _selectedToolTag = selectedToolTag;
    }
}

- (void)setHighlighting:(bool)highlighting {
    if (highlighting != _highlighting) {
        _highlighting = highlighting;
        [self setNeedsDisplayInRect:[self _extHighlightDrawingRect]];
    }
}

- (void)setHighlightPath:(NSBezierPath *)highlightPath {
    if (highlightPath != _highlightPath) {
        _highlightPath = highlightPath;
        [highlightPath setLineWidth:_EXTHighlightLineWidth];
    }
}

- (BOOL)isOpaque {
    return YES;
}

- (BOOL)acceptsFirstResponder {
    return YES;
}

- (BOOL)acceptsTouchEvents {
    return YES;
}

#pragma mark - Paging

// this get called when we move to the next page in the display. it's
// responsible for checking whether the page is dirty and, if so, calling the
// relevant updating algorithms.
- (IBAction)nextPage:(id)sender {
    //	EXTPage *nextPage;
    //	EXTPage *currentPage = [pages objectAtIndex:pageInView];
    //	if (pageInView == [pages count] - 1) {
    //		nextPage = [currentPage computeHomology];
    //		[currentPage setModified:NO];
    //		[nextPage setWhichPage:pageInView + 1];
    //		[pages addObject:nextPage];
    //	} else {
    //		if ([currentPage modified]) {
    //			nextPage = [currentPage computeHomology];
    //			[nextPage setModified:YES];
    //			[currentPage setModified:NO];
    //			[pages replaceObjectAtIndex:pageInView +1 withObject:nextPage];
    //		}
    //	};
    [self setSelectedPageIndex:_selectedPageIndex + 1];
}

- (IBAction)previousPage:(id)sender {
	if (_selectedPageIndex > 0)
        [self setSelectedPageIndex:_selectedPageIndex - 1];
}

// This is odd: we do not receive -swipeWithEvent: until the user scrolls the
// view using a two-finger scroll gesture. This same behaviour happens if the
// scroll view implements -swipeWithEvent:.
// See http://stackoverflow.com/questions/15854301
- (void)swipeWithEvent:(NSEvent *)event {
	CGFloat x = [event deltaX];
	if (x != 0) {
		(x < 0)  ? [self nextPage:self]: [self previousPage:self];
	};
}

#pragma mark - Key-value observing

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	if (context == _EXTChartViewArtBoardDrawingRectContext) {
        [self setNeedsDisplayInRect:NSUnionRect([change[NSKeyValueChangeOldKey] rectValue], [_artBoard drawingRect])];
        if (_selectedToolTag == _EXTArtboardToolTag)
            [[self window] invalidateCursorRectsForView:self];
	}
	else if (context == _EXTChartViewGridAnyKeyContext) {
		[self setNeedsDisplay:YES];
	}
    else if (context == _EXTChartViewSelectedPageIndexContext) {
        NSNumber *selectedPageNumber = [object valueForKeyPath:keyPath];

        if (selectedPageNumber != NSNotApplicableMarker)
            [self setSelectedPageIndex:[selectedPageNumber unsignedIntegerValue]];
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
	if (_selectedToolTag == _EXTArtboardToolTag)
		[_artBoard buildCursorRectsInView:self];
}

- (void)_extDragArtBoardWithEvent:(NSEvent *)event {
	// ripped off from sketch.   according to apple's document, it is better not to override the event loop like this.  Also, see the DragItemAround code for what I think is a better way to organize this.

    const NSRect originalVisibleRect = [[self enclosingScrollView] documentVisibleRect];
    NSPoint lastPoint = [_grid nearestGridPoint:[self convertPoint:[event locationInWindow] fromView:nil]];

    [_artBoard startDragOperationAtPoint:lastPoint];

    bool (^isEscapeKeyEvent)(NSEvent *) = ^bool (NSEvent *event) {
        return [event type] == NSKeyDown && [event keyCode] == 53;
    };

    // Since we are sequestering event loop processing, check for the Escape key here to cancel the drag operation
	while ([event type] != NSLeftMouseUp && !isEscapeKeyEvent(event)) {
		event = [[self window] nextEventMatchingMask:(NSLeftMouseDraggedMask | NSLeftMouseUpMask | NSKeyDownMask)];
        const NSPoint currentPoint = [_grid nearestGridPoint:[self convertPoint:[event locationInWindow] fromView:nil]];

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

    if (_selectedToolTag == _EXTArtboardToolTag) {
        const EXTArtBoardMouseDragOperation artBoardDragOperation = [_artBoard mouseDragOperationAtPoint:location];
        if (artBoardDragOperation != EXTArtBoardMouseDragOperationNone) {
            [self _extDragArtBoardWithEvent:event];
        }
	}
    else {
        const NSPoint gridLocation = [_grid convertToGridCoordinates:location];
        [_delegate chartView:self mouseDownAtGridLocation:gridLocation];
        [self setNeedsDisplayInRect:[self _extHighlightDrawingRect]]; // TODO: is this necessary?
	}
}


- (void)mouseMoved:(NSEvent *)event {
    const NSPoint mousePoint = [self convertPoint:[event locationInWindow] fromView:nil];
	[self resetHighlightRectAtLocation:mousePoint];
}

- (void)mouseExited:(NSEvent *)event {
    [self setNeedsDisplayInRect:[self _extHighlightDrawingRect]];
	[self setHighlightPath:[NSBezierPath bezierPathWithRect:NSZeroRect]];
}

- (IBAction)changeTool:(id)sender {
    NSAssert([sender respondsToSelector:@selector(tag)], @"This action requires senders that respond to -tag");

    EXTToolboxTag tag = [sender tag];
    if (tag <= 0 || tag >= _EXTToolTagCount)
        return;
    
//    self.delegate.highlightedObject = nil;

    [self setSelectedToolTag:tag];
}

#pragma mark - Resizing

// Chart views shouldn’t be resized. However, it seems that Restoration changes the chart view frame as part of
// the enclosing scrollview subview autoresizing process. We simple ignore this when it happens.
- (void)resizeWithOldSuperviewSize:(NSSize)oldSize {
    // Do nothing
}

#pragma mark - NSUserInterfaceValidations

- (BOOL)validateUserInterfaceItem:(id<NSValidatedUserInterfaceItem>)item {
    if ([item action] == @selector(changeTool:)) {
        if ([(id)item respondsToSelector:@selector(setState:)]) {
            [(id)item setState:([item tag] == _selectedToolTag ? NSOnState : NSOffState)];
        }
    }
    
    return [self respondsToSelector:[item action]];
}

@end
