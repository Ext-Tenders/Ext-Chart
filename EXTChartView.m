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
#import "EXTToolPaletteController.h"
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


@implementation EXTChartView
{
    NSMutableDictionary *_bindings;
}

@synthesize gridSpacing;
@synthesize showGrid, editMode, showPages;
@synthesize highlighting;
@synthesize highlightPath;

#pragma mark - Life cycle

+ (void)initialize
{
    if (self == [EXTChartView class])
        [self exposeBinding:EXTChartViewSseqBindingName];
}

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
		[self translateOriginToPoint:NSMakePoint(NSMidX(frame), NSMidY(frame))];
		showGrid = TRUE;
		showPages = YES;
		editMode = NO;
		gridSpacing = 9.0;

		_editingArtBoards = NO;
        _artBoard = [EXTArtBoard new];
        [_artBoard addObserver:self forKeyPath:@"drawingRect" options:NSKeyValueObservingOptionOld context:_EXTChartViewArtBoardDrawingRectContext];

        _bindings = [NSMutableDictionary dictionary];

        // since the frame extends past the bounds rectangle, we need observe the drawingRect in order to know what to refresh when the artBoard changes

		_grid = [EXTGrid new];
        [_grid setBoundsRect:[self bounds]];
        [_grid addObserver:self forKeyPath:EXTGridAnyKey options:0 context:NULL];
		
		// the tracking area should be set to the dataRect, which is still not implemented.
		
		NSRect dataRect = NSMakeRect(0, 0, 432, 432);
		
		trackingArea = [[NSTrackingArea alloc] initWithRect:dataRect
													options: (NSTrackingMouseEnteredAndExited | NSTrackingMouseMoved | NSTrackingActiveInKeyWindow )
													  owner:self userInfo:nil];
        [self addTrackingArea:trackingArea];
		
		// we initialize the highlight rect to something stupid.   It will change before it is drawn.
		
		highlighting = YES;
		
		highlightRect = NSZeroRect;
		[self setHighlightPath:[NSBezierPath bezierPathWithRect:NSZeroRect]];
		
// we will make highlightRectColor a user preference.  It should not be document specific.

//		highlightRectColor = [NSColor colorWithCalibratedRed:102.0/255 green:255.0/255 blue:204.0/255 alpha:1];
		highlightRectColor = [NSColor colorWithCalibratedRed:0 green:1.0 blue:1.0 alpha:1];
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(toolSelectionDidChange) name:@"EXTtoolSelectionChanged" object:EXTToolPaletteController.sharedToolPaletteController];

// a new document can get initialized when any tool is selected
		
		currentTool = EXTToolPaletteController.sharedToolPaletteController.currentToolClass;
		 
    }

	return self;
}

-(void)awakeFromNib	{
	[self scrollRectToVisible:[_artBoard frame]];
	NSScrollView *scroller = [self enclosingScrollView];
	
	[scroller setHasHorizontalRuler:YES];
	[scroller setHasVerticalRuler:YES];
	
	NSRulerView *horizRuler = [scroller horizontalRulerView];
    NSRulerView *vertRuler = [scroller verticalRulerView];
	
    [horizRuler setOriginOffset: - [self bounds].origin.x];
	
    [vertRuler setOriginOffset: - [self bounds].origin.y];
	
	[scroller setRulersVisible:YES];	
}

- (void)dealloc {
    [_artBoard removeObserver:self forKeyPath:@"drawingRect"];
    [_grid removeObserver:self forKeyPath:EXTGridAnyKey];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


#pragma mark *** utility methods ***
// convert pixel coordinates to (p, q) coordinates
-(NSPoint) convertToGridCoordinates:(NSPoint)pixelLoc {
	return NSMakePoint(floor(pixelLoc.x/gridSpacing), floor(pixelLoc.y/gridSpacing));
}

// convert (p, q) coordinates to pixel coordinates
- (NSPoint) convertToPixelCoordinates:(NSPoint) gridLoc{
	return NSMakePoint(gridLoc.x*gridSpacing, gridLoc.y*gridSpacing);
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
	
	if (showGrid) {
		[_grid drawGridInRect:rect];
	}
	
	// draw the artboard(s), shaded, around the document background.
	
	[_artBoard strokeRect];   // we're drawing the entire artboard frame.   probably OK.
	
	//draw the axes
	
	[_grid drawAxes];
	
	// draw the highlight rectangle if we're highlighting.  The highlightPath is stored, so we can correctly determine dirty rectangles.   It is generated by a class method in the EXTTerm and EXTDifferential classes.
	
	if (highlighting) {
		[highlightPath setLineWidth:.5];
		[highlightRectColor setStroke];
		[highlightPath stroke];
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
	if (showPages) {		
		NSPoint lowerLeftPoint = rect.origin;
		NSPoint upperRightPoint = rect.origin;
		upperRightPoint.x += rect.size.width;
		upperRightPoint.y += rect.size.height;
		
        // XXX: this may be drawing too narrow a window, resulting in blank Ext
        // charts if the scroll is dragged too slowly.
        [_delegate drawPageNumber:_selectedPageIndex
                              ll:[self convertToGridCoordinates:lowerLeftPoint]
                              ur:[self convertToGridCoordinates:upperRightPoint]
                     withSpacing:gridSpacing];
		
		//  // restore the graphics context
		//	[theContext restoreGraphicsState];
	}
	
}


- (void)resetHighlightRectAtLocation:(NSPoint)location{
	
// we're rebuilding the (small) highlightPath every time the mouse moves.   Is it better to just translate it, if needed?   We could eliminate the currentTool's need to know about the grid by taking one path, and translating and scaling it.   That path could be a constant, so wouldn't need to be rebuilt.

	NSBezierPath *newHighlightPath = [currentTool makeHighlightPathAtPoint:location onGrid: _grid onPage:pageInView];
	
	NSRect oldRect = [highlightPath bounds];
	NSRect newRect = [newHighlightPath bounds];
	
	BOOL sameRectQ = newRect.origin.x == oldRect.origin.x  && newRect.origin.y == oldRect.origin.y && newRect.size.width == oldRect.size.width && newRect.size.height == oldRect.size.height;
	
	
	if (!sameRectQ) {
		[self setHighlightPath:newHighlightPath];
		[self setNeedsDisplayInRect:NSInsetRect(oldRect, -1.0, -1.0)];
		[self setNeedsDisplayInRect:NSInsetRect(newRect, -1.0, -1.0)];
	}
}

-(IBAction)setGridToDefaults:(id)sender{
	[_grid resetToDefaults];	
}

- (void)displaySelectedPage
{
    if (highlighting) {
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

-(void)setShowGrid:(BOOL)showing{
	showGrid = showing;
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

- (void)setEditingArtBoards:(BOOL)editingArtBoards {
    if (editingArtBoards != _editingArtBoards) {
        _editingArtBoards = editingArtBoards;
        [[self window] invalidateCursorRectsForView:self];
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

//-(IBAction) scrollToCenter:(id)sender{
//	NSRect clipViewBounds = [[[self enclosingScrollView] contentView] bounds];
//	NSPoint newOrigin;
//	newOrigin.x = NSMidX(theDocumentRectangle) - clipViewBounds.size.width/2;
//	newOrigin.y = NSMidY(theDocumentRectangle) - clipViewBounds.size.height/2;
//	
//	[self scrollPoint:newOrigin];	
//}




#pragma mark - Bindings & KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
	if (context == _EXTChartViewArtBoardDrawingRectContext) {
        [self setNeedsDisplayInRect:NSUnionRect([change[NSKeyValueChangeOldKey] rectValue], [_artBoard drawingRect])];
        if (_editingArtBoards)
            [[self window] invalidateCursorRectsForView:self];
	}
	else if ([keyPath isEqualToString:EXTGridAnyKey]){
		// control never reaches this point.  both strings are substitutes for "ANY".  But nevertheless the grid spacing is getting reset.   Ugh.
		// the next line is a hack, and results in a few  redundant settings of gridSpacing.   It should be do-able with a simple binding, binding the value of gridSpacing to the one in the grid object.   But furthermore, there shouldn't be a gridSpacing variable in the EXTChartView class.
		
		[self setGridSpacing:_grid.gridSpacing]; 
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

- (void)bind:(NSString *)binding toObject:(id)observable withKeyPath:(NSString *)keyPath options:(NSDictionary *)options
{
    if ([binding isEqualToString:EXTChartViewSseqBindingName] || [binding isEqualToString:EXTChartViewSelectedPageIndexBindingName]) {
        if (_bindings[binding])
            [self unbind:binding];

        void *context = [binding isEqualToString:EXTChartViewSseqBindingName] ? _EXTChartViewSseqContext : _EXTChartViewSelectedPageIndexContext;
        [observable addObserver:self forKeyPath:keyPath options:0 context:context];
        _bindings[binding] = @{
                               NSObservedObjectKey : observable,
                               NSObservedKeyPathKey : [keyPath copy],
                               NSOptionsKey : (options ? [options copy] : @{}),
                               };
    }
    else
        [super bind:binding toObject:observable withKeyPath:keyPath options:options];
}

- (void)unbind:(NSString *)binding
{
    NSDictionary *bindingInfo = _bindings[binding];

    if (bindingInfo) {
        [bindingInfo[NSObservedObjectKey] removeObserver:self forKeyPath:bindingInfo[NSObservedKeyPathKey]];
        [_bindings removeObjectForKey:binding];
    }
    else
        [super unbind:binding];
}

- (NSDictionary *)infoForBinding:(NSString *)binding
{
    NSDictionary *bindingInfo = _bindings[binding];
    return bindingInfo ? bindingInfo : [super infoForBinding:binding];
}


#pragma mark *** zooming and scrolling ***

-(IBAction)fitWidth:(id)sender{
	
}

-(IBAction)fitHeight:(id)sender{
	
}

#pragma mark *** mouse tracking and cursor changing (tests)  ***

// from the documentation: "Before resetCursorRects is invoked, the owning view is automatically sent a disableCursorRects message to remove existing cursor rectangles."


-(void)resetCursorRects
{
	[self discardCursorRects];
	//	need to clip the artBoards cursor rects to the visible portion.   I haven't implemented this yet. The "visibleRect" command is supposed to make this easier.   I just checked with some log statements, and it indeed does report, in the bounds coordinates, the clipView's rectangle.    Sweet.
	
	if (_editingArtBoards)
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
    NSPoint lastPoint = [self convertPoint:[event locationInWindow] fromView:nil];

    [_artBoard startDragOperationAtPoint:lastPoint];

	while ([event type] != NSLeftMouseUp) {
		event = [[self window] nextEventMatchingMask:(NSLeftMouseDraggedMask | NSLeftMouseUpMask | NSKeyDownMask)];
        const NSPoint currentPoint = [_grid nearestGridPoint:[self convertPoint:[event locationInWindow] fromView:nil]];

        switch ([event type]) {
            case NSLeftMouseDragged: {
                if (! NSEqualPoints(lastPoint, currentPoint))
                    [_artBoard performDragOperationWithPoint:currentPoint];
                [self autoscroll:event];
                break;
            }

            case NSKeyDown:
                // Since we are sequestering event loop processing, check for the Escape key here to cancel the drag operation
                if ([event keyCode] == 53) {
                    [_artBoard cancelDragOperation];
                    [self scrollRectToVisible:originalVisibleRect];
                    return;
                }
                break;
        }

        lastPoint = currentPoint;
	}

    [_artBoard finishDragOperation];
}


- (void)mouseDown:(NSEvent *)event {
	const NSPoint locationPoint = [self convertPoint:[event locationInWindow] fromView:nil];
    const EXTArtBoardMouseDragOperation artBoardDragOperation = [_artBoard mouseDragOperationAtPoint:locationPoint];

    if (_editingArtBoards && artBoardDragOperation != EXTArtBoardMouseDragOperationNone) {
		[self _extDragArtBoardWithEvent:event];
	}
    else if (currentTool) {
        // TODO: reenable clicks.  the idea is that both terms and differentials
        // present the same 'insertable' interface, which is called here.
        
//        NSPoint point = [_grid convertToGridCoordinates:locationPoint];

        // TODO: review why the tool needs the document
//        [currentTool dealWithClick:point document:_delegate];

		[self setNeedsDisplayInRect:NSInsetRect([highlightPath bounds],-1,-1)];
	}
}
		

- (void)mouseMoved:(NSEvent *)theEvent {

    NSPoint mousePoint = [self convertPoint:[theEvent locationInWindow] fromView:nil];
	[self resetHighlightRectAtLocation:mousePoint];

	//    [self displayIfNeeded];
}

- (void)mouseExited:(NSEvent *)theEvent{
	NSRect lastRect = NSInsetRect([highlightPath bounds], -1.0, -1.0);
	[self setHighlightPath:[NSBezierPath bezierPathWithRect:NSZeroRect]];
	[self setNeedsDisplayInRect:lastRect];	
}
											
#pragma mark *** tool selection ***

- (void)toolSelectionDidChange{
	// just set the tool class to what it is

	currentTool = EXTToolPaletteController.sharedToolPaletteController.currentToolClass;
}

@end
