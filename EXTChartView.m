//
//  EXTChartView.m
//  Ext Chart
//
//  Created by Michael Hopkins on 7/20/11.
//  Copyright 2011 Harvard University. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

#import "EXTChartView.h"
#import "EXTScrollView.h"
#import "EXTGrid.h"
#import "EXTArtBoard.h"
#import "EXTChartViewModel.h"
#import "EXTTermLayer.h"
#import "EXTDifferentialLayer.h"
#import "EXTChartViewInteraction.h"
#import "NSUserDefaults+EXTAdditions.h"


#pragma mark - Exported variables

NSString * const EXTChartViewHighlightColorPreferenceKey = @"EXTChartViewHighlightColor";


#pragma mark - Private variables

static void *_EXTChartViewArtBoardDrawingRectContext = &_EXTChartViewArtBoardDrawingRectContext;
static void *_EXTChartViewGridAnyKeyContext = &_EXTChartViewGridAnyKeyContext;
static void *_EXTChartViewGridSpacingContext = &_EXTChartViewGridSpacingContext;
static void *_interactionTypeContext = &_interactionTypeContext;
static void *_showsGridContext = &_showsGridContext;

static const CGFloat _kBelowGridLevel = -3.0;
static const CGFloat _kGridLevel = -2.0;
static const CGFloat _kAboveGridLevel = -1.0;

static const CGFloat _kBaseGridLevel = 0.0;
static const CGFloat _kEmphasisGridLevel = 1.0;
static const CGFloat _kAxesGridLevel = 2.0;

static const CGFloat _kBaseGridLineWidth = 0.2;
static const CGFloat _kEmphasisGridLineWidth = 0.2;
static const CGFloat _kAxesGridLineWidth = 0.4;

static const CGFloat _kArtBoardBorderWidth = 0.75;
static const CGSize _kArtBoardShadowOffset = {-1.0, -2.0};
static const CGFloat _kArtBoardShadowRadius = 2.0;
static const CGFloat _kArtBoardShadowOpacity = 1.0;
static const CFTimeInterval _kArtBoardTransitionDuration = 0.125;

static CGColorRef _viewBackgroundColor;
static CGColorRef _baseGridStrokeColor;
static CGColorRef _emphasisGridStrokeColor;
static CGColorRef _axesGridStrokeColor;
static CGColorRef _artBoardBackgroundColor;
static CGColorRef _artBoardBorderColor;
static CGColorRef _artBoardShadowColor;

static const CFTimeInterval _kTermHighlightAddAnimationDuration = 0.09 * 1.8;
static const CFTimeInterval _kTermHighlightRemoveAnimationDuration = 0.07 * 1.8;
static const CFTimeInterval _kDifferentialHighlightAddAnimationDuration = 0.09;
static const CFTimeInterval _kDifferentialHighlightRemoveAnimationDuration = 0.07;


@implementation EXTChartView
{
	NSTrackingArea *_trackingArea;

    CALayer *_gridLayer;
    CAShapeLayer *_baseGridLayer;
    CAShapeLayer *_emphasisGridLayer;
    CAShapeLayer *_axesGridLayer;

    CALayer *_artBoardBackgroundLayer;
    CALayer *_artBoardBorderLayer;

    NSArray *_termLayers;
    NSArray *_differentialLayers;

    NSArray *_highlightedLayers; // an array of CALayer<EXTChartViewInteraction> objects, or nil
    CALayer<EXTChartViewInteraction> *_selectedLayer;
}


#pragma mark - Life cycle

+ (void)load {
    [self exposeBinding:@"grid"];
    [self exposeBinding:@"highlightColor"];

    NSColor *highlightColor = [NSColor colorWithCalibratedRed:0.0 green:1.0 blue:1.0 alpha:1.0];
    NSDictionary *defaults = @{EXTChartViewHighlightColorPreferenceKey : [NSArchiver archivedDataWithRootObject:highlightColor]};
    [[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
}

+ (void)initialize
{
    if (self == [EXTChartView class]) {
        _viewBackgroundColor = CGColorCreateCopy([[NSColor windowBackgroundColor] CGColor]);
        _baseGridStrokeColor = CGColorCreateCopy([[NSColor lightGrayColor] CGColor]);
        _emphasisGridStrokeColor = CGColorCreateCopy([[NSColor darkGrayColor] CGColor]);
        _axesGridStrokeColor = CGColorCreateCopy([[NSColor blueColor] CGColor]);
        _artBoardBackgroundColor = CGColorCreateCopy([[NSColor whiteColor] CGColor]);
        _artBoardBorderColor = CGColorCreateCopy([[NSColor blackColor] CGColor]);
        _artBoardShadowColor = CGColorCreateCopy([[NSColor blackColor] CGColor]);
    }
}

- (instancetype)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
		[self translateOriginToPoint:NSMakePoint(NSMidX(frame), NSMidY(frame))];

        // Highlighting
		{
            _highlightColor = [[NSUserDefaults standardUserDefaults] extColorForKey:EXTChartViewHighlightColorPreferenceKey];
        }

        // Selection
        {
            _selectionColor = [NSColor orangeColor];
        }

        CALayer *rootLayer = [CALayer layer];
        rootLayer.frame = self.bounds;
        rootLayer.backgroundColor = _viewBackgroundColor;
        rootLayer.opaque = YES;
        rootLayer.drawsAsynchronously = YES;
        rootLayer.delegate = self;

        rootLayer.transform = CATransform3DMakeTranslation(NSMidX(frame), NSMidY(frame), 0);

        // Grid
        {
            _showsGrid = true;
            _grid = [EXTGrid new];
            
            _gridLayer = [CAShapeLayer layer];
            _gridLayer.frame = (CGRect){CGPointZero, frame.size};
            _gridLayer.zPosition = _kGridLevel;
            [rootLayer addSublayer:_gridLayer];
            
            CAShapeLayer *(^gridSublayer)(CGRect, CGFloat, CGColorRef, CGFloat) = ^(CGRect frame, CGFloat zPosition, CGColorRef strokeColor, CGFloat lineWidth){
                CAShapeLayer *layer = [CAShapeLayer layer];
                layer.frame = frame;
                layer.zPosition = zPosition;
                layer.strokeColor = strokeColor;
                layer.lineWidth = lineWidth;
                return layer;
            };
            
            _baseGridLayer = gridSublayer(_gridLayer.frame, _kBaseGridLevel, _baseGridStrokeColor, _kBaseGridLineWidth);
            _emphasisGridLayer = gridSublayer(_gridLayer.frame, _kEmphasisGridLevel, _emphasisGridStrokeColor, _kEmphasisGridLineWidth);
            _axesGridLayer = gridSublayer(_gridLayer.frame, _kAxesGridLevel, _axesGridStrokeColor, _kAxesGridLineWidth);
            
            [_gridLayer addSublayer:_baseGridLayer];
            [_gridLayer addSublayer:_emphasisGridLayer];
            [_gridLayer addSublayer:_axesGridLayer];

            [self addObserver:self forKeyPath:@"showsGrid" options:NSKeyValueObservingOptionNew context:_showsGridContext];
        }

        // Art board
        {
            _artBoard = [EXTArtBoard new];

            _artBoardBackgroundLayer = [CALayer layer];
            _artBoardBorderLayer = [CALayer layer];

            _artBoardBackgroundLayer.backgroundColor = _artBoardBackgroundColor;
            _artBoardBackgroundLayer.zPosition = _kBelowGridLevel;

            _artBoardBorderLayer.zPosition = _kAboveGridLevel;
            _artBoardBorderLayer.borderWidth = _kArtBoardBorderWidth;
            _artBoardBorderLayer.borderColor = _artBoardBorderColor;

            _artBoardBorderLayer.shadowOffset = _kArtBoardShadowOffset;
            _artBoardBorderLayer.shadowColor = _artBoardShadowColor;
            _artBoardBorderLayer.shadowRadius = _kArtBoardShadowRadius;
            _artBoardBorderLayer.shadowOpacity = _kArtBoardShadowOpacity;

            [self _extAlignArtBoardToGrid];
            [self _extUpdateArtBoardMinimumSize];

            // Since the frame extends past the bounds rectangle, we need observe the drawingRect in order to know what to refresh when the artBoard changes
            [_artBoard addObserver:self forKeyPath:@"drawingRect" options:NSKeyValueObservingOptionOld context:_EXTChartViewArtBoardDrawingRectContext];

            [rootLayer addSublayer:_artBoardBackgroundLayer];
            [rootLayer addSublayer:_artBoardBorderLayer];
        }

        // See http://www.cocoabuilder.com/archive/cocoa/324875-calayer-renderincontext-changes-zposition-of-some-child-layers.html
        // See http://www.cocoabuilder.com/archive/cocoa/193266-reordering-calayer-sublayers-without-raping-my-performance.html
        NSSortDescriptor *zPosition = [NSSortDescriptor sortDescriptorWithKey:@"zPosition" ascending:YES];
        rootLayer.sublayers = [rootLayer.sublayers sortedArrayUsingDescriptors:@[zPosition]];

        self.layerContentsRedrawPolicy = NSViewLayerContentsRedrawNever;
        self.layerContentsPlacement = NSViewLayerContentsPlacementBottomLeft;
        self.layer = rootLayer;
        self.wantsLayer = YES;

        [self addObserver:self forKeyPath:@"interactionType" options:NSKeyValueObservingOptionNew context:_interactionTypeContext];

        // ----- Obsolete Begin
        /*
        // Grid
        {

            _grid = [EXTGrid new];
            [_grid setBoundsRect:[self bounds]];
            [_grid addObserver:self forKeyPath:EXTGridAnyKey options:0 context:_EXTChartViewGridAnyKeyContext];
            [_grid addObserver:self forKeyPath:@"gridSpacing" options:0 context:_EXTChartViewGridSpacingContext];
        }

         */
        // ----- Obsolete End
    }

	return self;
}

- (void)dealloc {
    // ----- Obsolete Begin
    /*
    [_grid removeObserver:self forKeyPath:EXTGridAnyKey context:_EXTChartViewGridAnyKeyContext];
    [_grid removeObserver:self forKeyPath:@"gridSpacing" context:_EXTChartViewGridSpacingContext];
     */
    // ----- Obsolete End

    [self removeObserver:self forKeyPath:@"showsGrid" context:_showsGridContext];
    [self removeObserver:self forKeyPath:@"interactionType" context:_interactionTypeContext];
    
    [_artBoard removeObserver:self forKeyPath:@"drawingRect" context:_EXTChartViewArtBoardDrawingRectContext];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)adjustContentForRect:(NSRect)rect
{
//    NSLog(@"Will prepare content for rect %@", NSStringFromRect(rect));

    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    {
        _gridLayer.frame = rect;
    }
    [CATransaction commit];

    const CGFloat spacing = _grid.gridSpacing;

    const NSInteger firstVerticalLine = (NSInteger)floor(rect.origin.x / spacing);
    const NSInteger firstHorizontalLine = (NSInteger)floor(rect.origin.y / spacing);
    const NSInteger numberOfHorizontalLines = (NSInteger)ceil(rect.size.height / spacing) + 1;
    const NSInteger numberOfVerticalLines = (NSInteger)ceil(rect.size.width / spacing) + 1;

//    NSLog(@"Number of horizontal lines is %ld, vertical is %ld", (long)numberOfHorizontalLines, (long)numberOfVerticalLines);
    const CGPoint origin = {
        .x = floor(rect.origin.x / spacing) * spacing,
        .y = floor(rect.origin.y / spacing) * spacing,
    };
    const CGPoint originInSublayer = [_baseGridLayer convertPoint:origin fromLayer:self.layer];
//    NSLog(@"Initial point is %@ in view, %@ in grid sublayer", NSStringFromPoint(origin), NSStringFromPoint(originInSublayer));
    CGPoint point = originInSublayer;

    CGMutablePathRef basePath = CGPathCreateMutable();
    CGMutablePathRef emphasisPath = CGPathCreateMutable();

    for (NSInteger i = 0; i < numberOfHorizontalLines; ++i) {
        CGMutablePathRef path = ((firstHorizontalLine + i) % 8) == 0 ? emphasisPath : basePath;
        CGPathMoveToPoint(path, NULL, point.x, point.y);
        CGPathAddLineToPoint(path, NULL, point.x + rect.size.width + spacing, point.y);

        point.y += spacing;
    }

    point = originInSublayer;
    for (NSInteger i = 0; i < numberOfVerticalLines; ++i) {
        CGMutablePathRef path = ((firstVerticalLine + i) % 8) == 0 ? emphasisPath : basePath;
        CGPathMoveToPoint(path, NULL, point.x, point.y);
        CGPathAddLineToPoint(path, NULL, point.x, point.y + rect.size.height + spacing);

        point.x += spacing;
    }

    const bool crossesYAxis = NSMinX(rect) <= 0.0 && NSMaxX(rect) >= 0.0;
    const bool crossesXAxis = NSMinY(rect) <= 0.0 && NSMaxY(rect) >= 0.0;

//    NSLog(@"crosses Y? %d X? %d, rect is %@", crossesYAxis, crossesXAxis, NSStringFromRect(rect));

    CGMutablePathRef axesPath = NULL;
    if (crossesXAxis || crossesYAxis) {
        axesPath = CGPathCreateMutable();

        if (crossesXAxis) {
            const CGPoint p1 = [_axesGridLayer convertPoint:(CGPoint){0.0, NSMinY(rect)} fromLayer:self.layer];
            const CGPoint p2 = [_axesGridLayer convertPoint:(CGPoint){0.0, NSMaxY(rect)} fromLayer:self.layer];

            CGPathMoveToPoint(axesPath, NULL, p1.x, p1.y);
            CGPathAddLineToPoint(axesPath, NULL, p2.x, p2.y);
        }

        if (crossesYAxis) {
            const CGPoint p1 = [_axesGridLayer convertPoint:(CGPoint){NSMinX(rect), 0.0} fromLayer:self.layer];
            const CGPoint p2 = [_axesGridLayer convertPoint:(CGPoint){NSMaxX(rect), 0.0} fromLayer:self.layer];

            CGPathMoveToPoint(axesPath, NULL, p1.x, p1.y);
            CGPathAddLineToPoint(axesPath, NULL, p2.x, p2.y);
        }
    }

    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    {
        _baseGridLayer.path = basePath;
        _emphasisGridLayer.path = emphasisPath;
        _axesGridLayer.path = axesPath;
    }
    [CATransaction commit];

    CGPathRelease(basePath);
    CGPathRelease(emphasisPath);
    CGPathRelease(axesPath);
}

- (void)reloadCurrentPage
{
    const NSRect reloadRect = {{NSMinX(self.frame), NSMinY(self.frame)}, self.frame.size};
    const EXTIntRect reloadGridRect = {
        {(NSInteger)(reloadRect.origin.x / _grid.gridSpacing), (NSInteger)(reloadRect.origin.y / _grid.gridSpacing)},
        {(NSInteger)(reloadRect.size.width / _grid.gridSpacing), (NSInteger)(reloadRect.size.height / _grid.gridSpacing)}};

    // Terms
    {
        [_termLayers makeObjectsPerformSelector:@selector(removeFromSuperlayer)];
        
        NSMutableArray *newTermLayers = [NSMutableArray new];
        
        NSArray *termCells = [self.dataSource chartView:self termCellsInGridRect:reloadGridRect];
        for (EXTChartViewModelTermCell *termCell in termCells) {
            EXTTermLayer *newTermLayer = [EXTTermLayer termLayerWithTotalRank:termCell.totalRank length:_grid.gridSpacing];
            newTermLayer.frame = (CGRect){{termCell.gridLocation.x * _grid.gridSpacing, termCell.gridLocation.y * _grid.gridSpacing}, {_grid.gridSpacing, _grid.gridSpacing}};
            newTermLayer.termCell = termCell;
            newTermLayer.highlightColor = [_highlightColor CGColor];
            newTermLayer.selectionColor = [_selectionColor CGColor];
            [newTermLayers addObject:newTermLayer];
            [self.layer addSublayer:newTermLayer];
        }
        
        _termLayers = [newTermLayers copy];
    }


    // Differentials
    {
        [_differentialLayers makeObjectsPerformSelector:@selector(removeFromSuperlayer)];

        NSMutableArray *newDifferentialLayers = [NSMutableArray new];

        NSArray *differentials = [self.dataSource chartView:self differentialsInGridRect:reloadGridRect];
        for (EXTChartViewModelDifferential *diff in differentials) {
            EXTDifferentialLayer *newDifferentialLayer = [EXTDifferentialLayer layer];
            const CGPoint start = [_grid convertPointToView:diff.startTerm.gridLocation];
            const CGPoint end = [_grid convertPointToView:diff.endTerm.gridLocation];
            const CGPoint origin = {MIN(start.x, end.x), MIN(start.y, end.y)};
            const CGSize size = {ABS(start.x - end.x), ABS(start.y - end.y)};
            newDifferentialLayer.frame = (CGRect){origin, size};
            newDifferentialLayer.differential = diff;
            newDifferentialLayer.highlightColor = [_highlightColor CGColor];
            newDifferentialLayer.selectionColor = [_selectionColor CGColor];
            [newDifferentialLayers addObject:newDifferentialLayer];
            [self.layer addSublayer:newDifferentialLayer];

            // FIXME: This is ugly, oh so ugly
            NSInteger startTotalRank = 0;
            for (EXTTermLayer *layer in _termLayers) {
                if ([layer.termCell.terms containsObject:diff.startTerm]) {
                    startTotalRank = layer.termCell.totalRank;
                    break;
                }
            }

            NSInteger endTotalRank = 0;
            for (EXTTermLayer *layer in _termLayers) {
                if ([layer.termCell.terms containsObject:diff.endTerm]) {
                    endTotalRank = layer.termCell.totalRank;
                    break;
                }
            }


            const NSRect startDotRect = [EXTChartView dotBoundingBoxForTermCount:startTotalRank
                                                                       termIndex:diff.startIndex
                                                                    gridLocation:diff.startTerm.gridLocation
                                                                     gridSpacing:_grid.gridSpacing];
            const NSRect endDotRect = [EXTChartView dotBoundingBoxForTermCount:endTotalRank
                                                                     termIndex:diff.endIndex
                                                                  gridLocation:diff.endTerm.gridLocation
                                                                   gridSpacing:_grid.gridSpacing];

            const CGPoint startDotConnectionPoint = (startTotalRank <= 3 ?
                                                     (CGPoint){NSMidX(startDotRect), NSMidY(startDotRect)} :
                                                     (CGPoint){NSMinX(startDotRect), NSMidY(startDotRect)});
            const CGPoint endDotConnectionPoint = (endTotalRank <= 3 ?
                                                   (CGPoint){NSMidX(endDotRect), NSMidY(endDotRect)} :
                                                   (CGPoint){NSMaxX(endDotRect), NSMidY(endDotRect)});
            const CGPoint startInLayer = [newDifferentialLayer convertPoint:startDotConnectionPoint fromLayer:self.layer];
            const CGPoint endInLayer = [newDifferentialLayer convertPoint:endDotConnectionPoint fromLayer:self.layer];

            CGMutablePathRef path = CGPathCreateMutable();
            CGPathMoveToPoint(path, NULL, startInLayer.x, startInLayer.y);
            CGPathAddLineToPoint(path, NULL, endInLayer.x, endInLayer.y);
            newDifferentialLayer.path = path;
            CGPathRelease(path);
        }

        _differentialLayers = [newDifferentialLayers copy];
    }
}


- (void)resetCursorRects
{
	if (self.interactionType == EXTChartViewInteractionTypeArtBoard) [_artBoard buildCursorRectsInView:self];
}

- (void)updateHighlight
{
    switch (self.interactionType) {
        case EXTChartViewInteractionTypeTerm:
            [self updateTermHighlight];
            break;

        case EXTChartViewInteractionTypeDifferential:
            [self updateDifferentialHighlight];
            break;

        case EXTChartViewInteractionTypeMultiplicativeStructure:
        case EXTChartViewInteractionTypeArtBoard:
        case EXTChartViewInteractionTypeNone:
        default:
            break;
    }
}

- (void)updateTermHighlight
{
    EXTTermLayer *layerToHighlight = nil;

    const NSRect dataRect = [_trackingArea rect];
    const NSPoint currentMouseLocation = [self convertPoint:[[self window] mouseLocationOutsideOfEventStream] fromView:nil];
    if (NSPointInRect(currentMouseLocation, dataRect)) {
        const EXTIntPoint mouseLocationInGrid = [_grid convertPointFromView:currentMouseLocation];
        for (EXTTermLayer *layer in _termLayers) {
            if (EXTEqualIntPoints(layer.termCell.gridLocation, mouseLocationInGrid)) {
                layerToHighlight = layer;
                break;
            }
        }
    }

    CALayer<EXTChartViewInteraction> *currentlyHighlightedLayer = [_highlightedLayers firstObject];
    if (currentlyHighlightedLayer != layerToHighlight) {
        [CATransaction begin];
        {
            {
                [CATransaction setAnimationDuration:_kTermHighlightRemoveAnimationDuration];
                [CATransaction setAnimationTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn]];

                currentlyHighlightedLayer.highlighted = false;
            }
            {
                [CATransaction setAnimationDuration:_kTermHighlightAddAnimationDuration];
                [CATransaction setAnimationTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut]];

                layerToHighlight.highlighted = true;
            }
        }
        [CATransaction commit];

        _highlightedLayers = (layerToHighlight ? @[layerToHighlight] : nil);
    }
}

- (void)updateDifferentialHighlight
{
    NSMutableArray *layersToHighlight = [NSMutableArray new];

    const NSRect dataRect = [_trackingArea rect];
    const NSPoint currentMouseLocation = [self convertPoint:[[self window] mouseLocationOutsideOfEventStream] fromView:nil];
    if (NSPointInRect(currentMouseLocation, dataRect)) {
        const EXTIntPoint mouseLocationInGrid = [_grid convertPointFromView:currentMouseLocation];
        for (EXTDifferentialLayer *layer in _differentialLayers) {
            if (EXTEqualIntPoints(layer.differential.startTerm.gridLocation, mouseLocationInGrid)) {
                [layersToHighlight addObject:layer];
            }
        }
    }

    // To avoid flicker, do not remove highlight from a layer if we are going to add highlight to it anyway.
    // This happens when the mouse has moved but it’s still in the same grid cell.
    // TODO: Maybe a better option is to track whether the mouse has moved to a different grid cell, and do not send
    //       -updateHighlight if the grid cell is the same.

    NSMutableSet *layersToRemoveHighlight = [NSMutableSet setWithArray:_highlightedLayers];
    [layersToRemoveHighlight minusSet:[NSSet setWithArray:layersToHighlight]];

    [CATransaction begin];
    {
        [CATransaction setAnimationTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut]];

        {
            [CATransaction setAnimationDuration:_kDifferentialHighlightRemoveAnimationDuration];

            for (CALayer<EXTChartViewInteraction> *layer in layersToRemoveHighlight) layer.highlighted = false;
        }
        {
            [CATransaction setAnimationDuration:_kDifferentialHighlightAddAnimationDuration];

            for (CALayer<EXTChartViewInteraction> *layer in layersToHighlight) layer.highlighted = true;
        }
    }
    [CATransaction commit];

    _highlightedLayers = (layersToHighlight.count == 0 ? nil : [layersToHighlight copy]);
}

#pragma mark - Properties

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
        if (self.interactionType == EXTChartViewInteractionTypeArtBoard)
            [[self window] invalidateCursorRectsForView:self];
	}
	else if (context == _EXTChartViewGridAnyKeyContext) {
		[self setNeedsDisplay:YES];
	}
    else if (context == _EXTChartViewGridSpacingContext) {
        [self _extAlignArtBoardToGrid];
        [self _extUpdateArtBoardMinimumSize];
    }
    else if (context == _interactionTypeContext) {
        for (CALayer<EXTChartViewInteraction> *layer in _highlightedLayers) {
            layer.highlighted = false;
        }

        _highlightedLayers = nil;
        [self updateHighlight];
    }
    else if (context == _showsGridContext) {
        bool showsGrid = [change[NSKeyValueChangeNewKey] boolValue];
        if (showsGrid) {
            [self.layer addSublayer:_gridLayer];
            NSClipView *clipView = [[self enclosingScrollView] contentView];
            const NSRect visibleRect = [self convertRect:clipView.bounds fromView:clipView];
            [self adjustContentForRect:visibleRect];
        }
        else {
            [_gridLayer removeFromSuperlayer];
        }
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

    if (self.interactionType == EXTChartViewInteractionTypeArtBoard) {
        const EXTArtBoardMouseDragOperation artBoardDragOperation = [_artBoard mouseDragOperationAtPoint:location];
        if (artBoardDragOperation != EXTArtBoardMouseDragOperationNone) {
            [self _extDragArtBoardWithEvent:event];
        }
	}
    else {
        [_delegate chartView:self mouseDownAtGridLocation:[_grid convertPointFromView:location]];
	}
}

- (void)mouseMoved:(NSEvent *)event {
    [self updateHighlight];
}

- (void)mouseEntered:(NSEvent *)event {
    [self updateHighlight];
}

- (void)mouseExited:(NSEvent *)event {
    [self updateHighlight];
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
    [self updateHighlight];
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
    [CATransaction begin];
    [CATransaction setAnimationDuration:_kArtBoardTransitionDuration];
    {
        _artBoardBackgroundLayer.frame = artBoardFrame;
        _artBoardBorderLayer.frame = artBoardFrame;
    }
    [CATransaction commit];
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

#pragma mark - Selection

- (void)selectTermAtGridLocation:(EXTIntPoint)gridLocation index:(NSInteger)index
{
    CAShapeLayer<EXTChartViewInteraction> *layerToSelect = nil;
    for (EXTTermLayer *layer in _termLayers) {
        if (EXTEqualIntPoints(layer.termCell.gridLocation, gridLocation)) {
            layerToSelect = layer;
            break;
        }
    }

    if (_selectedLayer != layerToSelect) {
        [CATransaction begin];
        {
            {
                [CATransaction setAnimationDuration:_kTermHighlightRemoveAnimationDuration];
                [CATransaction setAnimationTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn]];

                _selectedLayer.selected = false;
            }
            {
                [CATransaction setAnimationDuration:_kTermHighlightAddAnimationDuration];
                [CATransaction setAnimationTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut]];
                
                layerToSelect.selected = true;
            }
        }
        [CATransaction commit];

        _selectedLayer = layerToSelect;
    }
}

- (void)removeTermSelection
{
    _selectedLayer.selected = false;
}

- (void)selectDifferentialAtStartLocation:(EXTIntPoint)startLocation index:(NSInteger)index
{
    CAShapeLayer<EXTChartViewInteraction> *layerToSelect = nil;
    NSInteger currentIndex = -1;

    for (EXTDifferentialLayer *layer in _differentialLayers) {
        if (EXTEqualIntPoints(layer.differential.startTerm.gridLocation, startLocation)) {
            ++currentIndex;
            if (currentIndex == index) {
                layerToSelect = layer;
                break;
            }
        }
    }

    [CATransaction begin];
    {
        [CATransaction setAnimationTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut]];

        {
            [CATransaction setAnimationDuration:_kDifferentialHighlightRemoveAnimationDuration];

            _selectedLayer.selected = false;
        }
        {
            [CATransaction setAnimationDuration:_kDifferentialHighlightAddAnimationDuration];

            layerToSelect.selected = true;
        }
    }
    [CATransaction commit];

    _selectedLayer = layerToSelect;
}

- (void)removeDifferentialSelection
{
    _selectedLayer.selected = false;
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

#pragma mark - Util

+ (CGRect)dotBoundingBoxForTermCount:(NSInteger)termCount
                           termIndex:(NSInteger)termIndex
                        gridLocation:(EXTIntPoint)gridLocation
                         gridSpacing:(CGFloat)gridSpacing
{
    switch (termCount) {
        case 1:
            return CGRectMake(gridLocation.x*gridSpacing + 2.0/6.0*gridSpacing,
                              gridLocation.y*gridSpacing + 2.0/6.0*gridSpacing,
                              2.0*gridSpacing/6.0,
                              2.0*gridSpacing/6.0);

        case 2:
            switch (termIndex) {
                case 0:
                    return CGRectMake(gridLocation.x*gridSpacing + 1.0/6.0*gridSpacing,
                                      gridLocation.y*gridSpacing + 1.0/6.0*gridSpacing,
                                      2.0*gridSpacing/6.0,
                                      2.0*gridSpacing/6.0);
                case 1:
                    return CGRectMake(gridLocation.x*gridSpacing + 3.0/6.0*gridSpacing,
                                      gridLocation.y*gridSpacing + 3.0/6.0*gridSpacing,
                                      2.0*gridSpacing/6.0,
                                      2.0*gridSpacing/6.0);
            }

        case 3:
            switch (termIndex) {
                case 0:
                    return CGRectMake(gridLocation.x*gridSpacing + 0.66/6.0*gridSpacing,
                                      gridLocation.y*gridSpacing + 1.0/6.0*gridSpacing,
                                      2.0*gridSpacing/6.0,
                                      2.0*gridSpacing/6.0);
                case 1:
                    return CGRectMake(gridLocation.x*gridSpacing + 2.0/6.0*gridSpacing,
                                      gridLocation.y*gridSpacing + 3.0/6.0*gridSpacing,
                                      2.0*gridSpacing/6.0,
                                      2.0*gridSpacing/6.0);
                case 2:
                    return CGRectMake(gridLocation.x*gridSpacing + 3.33/6.0*gridSpacing,
                                      gridLocation.y*gridSpacing + 1.0/6.0*gridSpacing,
                                      2.0*gridSpacing/6.0,
                                      2.0*gridSpacing/6.0);

            }

        default:
            return CGRectMake(gridLocation.x*gridSpacing+0.15*gridSpacing,
                              gridLocation.y*gridSpacing+0.15*gridSpacing,
                              0.7*gridSpacing,
                              0.7*gridSpacing);
    }
    
    return CGRectZero;
}

@end
