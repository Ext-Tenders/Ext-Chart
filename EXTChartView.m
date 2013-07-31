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


// TODO: check whether this variable is necessary
//static NSColor *highlightRectColor = nil;


#pragma mark - Exported variables

NSString * const EXTChartViewSseqBindingName = @"sseq";
NSString * const EXTChartViewSelectedPageIndexBindingName = @"selectedPageIndex";

#pragma mark - Private variables

static void *_EXTChartViewSseqContext = &_EXTChartViewSseqContext;
static void *_EXTChartViewSelectedPageIndexContext = &_EXTChartViewSelectedPageIndexContext;
static void *_EXTChartViewArtBoardDrawingRectContext = &_EXTChartViewArtBoardDrawingRectContext;
static void *_EXTChartViewGridAnyKeyContext = &_EXTChartViewGridAnyKeyContext;

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
	NSColor *_highlightRectColor;  // if this is not customizable, it should be a constant.   I couldn't make it work as a static or extern...
	NSTrackingArea *_trackingArea;
	NSBezierPath *_hightlightPath;
}

@property(nonatomic, assign) bool highlighting;
@property(nonatomic, strong) NSBezierPath *highlightPath;
@end


@implementation EXTChartView

#pragma mark - Life cycle

+ (void)initialize
{
    if (self == [EXTChartView class]) {
        [self exposeBinding:EXTChartViewSseqBindingName];
        [self exposeBinding:EXTChartViewSelectedPageIndexBindingName];
    }
}

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
		[self translateOriginToPoint:NSMakePoint(NSMidX(frame), NSMidY(frame))];
		_showGrid = true;

        _artBoard = [EXTArtBoard new];
        // since the frame extends past the bounds rectangle, we need observe the drawingRect in order to know what to refresh when the artBoard changes
        [_artBoard addObserver:self forKeyPath:@"drawingRect" options:NSKeyValueObservingOptionOld context:_EXTChartViewArtBoardDrawingRectContext];

		_grid = [EXTGrid new];
        [_grid setBoundsRect:[self bounds]];
        [_grid addObserver:self forKeyPath:EXTGridAnyKey options:0 context:_EXTChartViewGridAnyKeyContext];


        // Align the art board to the grid
        NSRect artBoardFrame = [_artBoard frame];
        artBoardFrame.origin = [_grid nearestGridPoint:artBoardFrame.origin];
        const NSPoint originOppositePoint = [_grid nearestGridPoint:(NSPoint){NSMaxX(artBoardFrame), NSMaxY(artBoardFrame)}];
        artBoardFrame.size.width = originOppositePoint.x - NSMinX(artBoardFrame);
        artBoardFrame.size.height = originOppositePoint.y - NSMinY(artBoardFrame);
        [_artBoard setFrame:artBoardFrame];


		// the tracking area should be set to the dataRect, which is still not implemented.
		
		NSRect dataRect = NSMakeRect(0, 0, 432, 432);
		
		_trackingArea = [[NSTrackingArea alloc] initWithRect:dataRect
													options: (NSTrackingMouseEnteredAndExited | NSTrackingMouseMoved | NSTrackingActiveInKeyWindow )
													  owner:self userInfo:nil];
        [self addTrackingArea:_trackingArea];
		
		// we initialize the highlight rect to something stupid.   It will change before it is drawn.
		
		_highlighting = true;
		
		_highlightRect = NSZeroRect;
		[self setHighlightPath:[NSBezierPath bezierPathWithRect:NSZeroRect]];
		
// we will make highlightRectColor a user preference.  It should not be document specific.

//		highlightRectColor = [NSColor colorWithCalibratedRed:102.0/255 green:255.0/255 blue:204.0/255 alpha:1];
		_highlightRectColor = [NSColor colorWithCalibratedRed:0 green:1.0 blue:1.0 alpha:1];
    }

	return self;
}

- (void)dealloc {
    [_artBoard removeObserver:self forKeyPath:@"drawingRect" context:_EXTChartViewArtBoardDrawingRectContext];
    [_grid removeObserver:self forKeyPath:EXTGridAnyKey context:_EXTChartViewGridAnyKeyContext];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


#pragma mark *** utility methods ***
// convert pixel coordinates to (p, q) coordinates
-(NSPoint) convertToGridCoordinates:(NSPoint)pixelLoc {
	return NSMakePoint(floor(pixelLoc.x / [_grid gridSpacing]), floor(pixelLoc.y / [_grid gridSpacing]));
}

// convert (p, q) coordinates to pixel coordinates
- (NSPoint) convertToPixelCoordinates:(NSPoint) gridLoc{
	return NSMakePoint(gridLoc.x*[_grid gridSpacing], gridLoc.y*[_grid gridSpacing]);
}


#pragma mark *** drawing ***
- (void)drawRect:(NSRect)rect {
    // the big background
	
	//	NSBezierPath *documentFrame = [NSBezierPath bezierPathWithRect:[self bounds]];
	[[NSColor windowBackgroundColor] set];
	//	[documentFrame fill];
	[NSBezierPath fillRect:rect];
	
	
	
	// fill the artBoard(s) --- we're ignoring "rect" and filling the entire artboard.   we should intersect it with rect.
	
	[_artBoard fillRect];
	
	// draw the grid.  
	
	if (_showGrid) {
		[_grid drawGridInRect:rect];
	}
	
	// draw the artboard(s), shaded, around the document background.
	
	[_artBoard strokeRect];   // we're drawing the entire artboard frame.   probably OK.
	
	//draw the axes
	
	[_grid drawAxes];
	
	// draw the highlight rectangle if we're highlighting.  The highlightPath is stored, so we can correctly determine dirty rectangles.   It is generated by a class method in the EXTTerm and EXTDifferential classes.
	
	if (_highlighting) {
		[_highlightPath setLineWidth:.5];
		[_highlightRectColor setStroke];
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
    NSPoint lowerLeftPoint = rect.origin;
    NSPoint upperRightPoint = rect.origin;
    upperRightPoint.x += rect.size.width;
    upperRightPoint.y += rect.size.height;

    // XXX: this may be drawing too narrow a window, resulting in blank Ext
    // charts if the scroll is dragged too slowly.
    [_delegate drawPageNumber:_selectedPageIndex
                           ll:[self convertToGridCoordinates:lowerLeftPoint]
                           ur:[self convertToGridCoordinates:upperRightPoint]
                  withSpacing:[_grid gridSpacing]];

    //  // restore the graphics context
    //	[theContext restoreGraphicsState];
}


- (void)resetHighlightRectAtLocation:(NSPoint)location {
	
// we're rebuilding the (small) highlightPath every time the mouse moves.   Is it better to just translate it, if needed?   We could eliminate the currentTool's need to know about the grid by taking one path, and translating and scaling it.   That path could be a constant, so wouldn't need to be rebuilt.

    Class toolClass = _EXTClassFromToolTag(_selectedToolTag);
	NSBezierPath *newHighlightPath = [toolClass makeHighlightPathAtPoint:location onGrid: _grid onPage:_selectedPageIndex];
	
	const NSRect oldRect = [_highlightPath bounds];
	const NSRect newRect = [newHighlightPath bounds];
	
    [self setHighlightPath:newHighlightPath];

    // We may be resetting the highlight because the mouse has moved, the page has changed, or the highlighting {YES,NO} status has changed,
    // so we always flag both the previous location and the new location as dirty.
    [self setNeedsDisplayInRect:NSInsetRect(oldRect, -1.0, -1.0)];
    [self setNeedsDisplayInRect:NSInsetRect(newRect, -1.0, -1.0)];
}

- (void)displaySelectedPage
{
    if (_highlighting) {
        NSPoint mousePoint = [[[self enclosingScrollView] window] mouseLocationOutsideOfEventStream];
        mousePoint = [self convertPoint:mousePoint fromView:nil];
        [self resetHighlightRectAtLocation:mousePoint];
    }

    // compute all the cycles and boundaries for this new page.
    // TODO: computations shouldn’t be done by the view. Move this to the model, mediated by a controller
    [self.sseq computeGroupsForPage:_selectedPageIndex];

    [self setNeedsDisplay:YES];
}

- (void)setSelectedPageIndex:(NSUInteger)selectedPageIndex
{
    // TODO: should check whether the argument lies in {min, max} page indices
    if (selectedPageIndex != _selectedPageIndex) {
        _selectedPageIndex = selectedPageIndex;
        [self displaySelectedPage];
    }
}

- (void)setShowGrid:(bool)showGrid {
	_showGrid = showGrid;
	[self setNeedsDisplay:YES];
}

#pragma mark - Properties

- (void)setSseq:(EXTSpectralSequence *)sseq
{
    if (sseq != _sseq) {
        _sseq = sseq;
        [self displaySelectedPage];
    }
}

- (void)setSelectedToolTag:(EXTToolboxTag)selectedToolTag {
    if (selectedToolTag != _selectedToolTag) {
        [[self window] invalidateCursorRectsForView:self];
        [self setHighlighting:selectedToolTag != _EXTArtboardToolTag];
        [self setNeedsDisplayInRect:NSInsetRect([_highlightPath bounds], -1.0, -1.0)];

        _selectedToolTag = selectedToolTag;
    }
}

#pragma mark *** paging ***

// TODO: this gets called when the Compute Homology button is pressed. this
// should still have an action --- it should recalculate the filtration or sth.
- (IBAction)computeHomology: (id)sender {
//	NSMutableArray *pages = [delegate pages];
//	EXTPage *currentPage = [pages objectAtIndex:pageInView];
//	EXTPage *computedPage = [currentPage computeHomology];
//	if (pageInView == [pages count]-1)
//		[pages addObject:computedPage];
//	else
//		[pages replaceObjectAtIndex:pageInView+1 withObject:computedPage];
}

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

// This is odd: we do not receive -swipeWithEvent: until the user scrolls the view using
// a two-finger scroll gesture. This same behaviour happens if the scroll view implements
// -swipeWithEvent:.
// See http://stackoverflow.com/questions/15854301
- (void)swipeWithEvent:(NSEvent *)event{
	CGFloat x = [event deltaX];
	if (x != 0) {
		(x < 0)  ? [self nextPage:self]: [self previousPage:self];
	};
}

- (BOOL)acceptsFirstResponder
{
    return YES;
}

- (BOOL)acceptsTouchEvents {
    return YES;
}

//-(IBAction) scrollToCenter:(id)sender{
//	NSRect clipViewBounds = [[[self enclosingScrollView] contentView] bounds];
//	NSPoint newOrigin;
//	newOrigin.x = NSMidX(theDocumentRectangle) - clipViewBounds.size.width/2;
//	newOrigin.y = NSMidY(theDocumentRectangle) - clipViewBounds.size.height/2;
//	
//	[self scrollPoint:newOrigin];	
//}




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
    else if (context == _EXTChartViewSseqContext) {
        EXTSpectralSequence *newSseq = [object valueForKeyPath:keyPath];

        if (newSseq != NSNotApplicableMarker)
            [self setSseq:newSseq];
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

#pragma mark *** zooming and scrolling ***

- (IBAction)zoomToFit:(id)sender {
    const NSRect artBoardRect = [_artBoard frame];
    [[self enclosingScrollView] magnifyToFitRect:artBoardRect];
    [self scrollPoint:artBoardRect.origin];
}

- (NSRect)rectForSmartMagnificationAtPoint:(NSPoint)location inRect:(NSRect)visibleRect {
    return [_artBoard frame];
}

#pragma mark *** mouse tracking and cursor changing (tests)  ***

// from the documentation: "Before resetCursorRects is invoked, the owning view is automatically sent a disableCursorRects message to remove existing cursor rectangles."


-(void)resetCursorRects
{
	[self discardCursorRects];
	//	need to clip the artBoards cursor rects to the visible portion.   I haven't implemented this yet. The "visibleRect" command is supposed to make this easier.   I just checked with some log statements, and it indeed does report, in the bounds coordinates, the clipView's rectangle.    Sweet.
	
	if (_selectedToolTag == _EXTArtboardToolTag)
		[_artBoard buildCursorRectsInView:self];
}


// should this be passed as a method to the EXTArtBoard object?   I guess not.   When handling these mouse events, I think the view is acting as a model controller, and from that point of view they belong here.   At any rate, the model shouldn't handle any mouse events.

//- (void)mouseDragged:(NSEvent *)theEvent{
//	return;
//	NSPoint loc = [self	convertPoint:[theEvent locationInWindow] fromView:nil];
//	if (NSPointInRect(loc, [artBoard rectValue])) {		
//		EXTScrollView *scrollView = (EXTScrollView *)[self enclosingScrollView];
//		CGFloat scale = 1/[scrollView scaleFactor];
//		//	CGFloat scale = 1.0;
//		[artBoard setXPosition:[artBoard xPosition] + [theEvent deltaX]*scale];
//		[artBoard setYPosition:[artBoard yPosition] - [theEvent deltaY]*scale];
//		[self autoscroll:theEvent];
//	}
//}

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
	const NSPoint locationPoint = [self convertPoint:[event locationInWindow] fromView:nil];
    const EXTArtBoardMouseDragOperation artBoardDragOperation = [_artBoard mouseDragOperationAtPoint:locationPoint];
    Class toolClass = _EXTClassFromToolTag(_selectedToolTag);

    if (_selectedToolTag == _EXTArtboardToolTag && artBoardDragOperation != EXTArtBoardMouseDragOperationNone) {
		[self _extDragArtBoardWithEvent:event];
	}
    else if (toolClass) {
        // TODO: reenable clicks.  the idea is that both terms and differentials
        // present the same 'insertable' interface, which is called here.
        
//        NSPoint point = [_grid convertToGridCoordinates:locationPoint];

        // TODO: review why the tool needs the document
//        [currentTool dealWithClick:point document:_delegate];

		[self setNeedsDisplayInRect:NSInsetRect([_highlightPath bounds],-1,-1)];
	}
}
		

- (void)mouseMoved:(NSEvent *)theEvent {

    NSPoint mousePoint = [self convertPoint:[theEvent locationInWindow] fromView:nil];
	[self resetHighlightRectAtLocation:mousePoint];

	//    [self displayIfNeeded];
}

- (void)mouseExited:(NSEvent *)theEvent{
	NSRect lastRect = NSInsetRect([_highlightPath bounds], -1.0, -1.0);
	[self setHighlightPath:[NSBezierPath bezierPathWithRect:NSZeroRect]];
	[self setNeedsDisplayInRect:lastRect];	
}

- (IBAction)changeTool:(id)sender {
    if (![sender respondsToSelector:@selector(tag)])
        return;

    EXTToolboxTag tag = [sender tag];
    if (tag <= 0 || tag >= _EXTToolTagCount)
        return;

    [self setSelectedToolTag:tag];
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
