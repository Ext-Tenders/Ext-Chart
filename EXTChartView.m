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
#import "NSUserDefaults+EXTAdditions.h"


#pragma mark - Exported variables

NSString * const EXTChartViewHighlightColorPreferenceKey = @"EXTChartViewHighlightColor";


#pragma mark - Private variables

static void *_EXTChartViewArtBoardDrawingRectContext = &_EXTChartViewArtBoardDrawingRectContext;
static void *_EXTChartViewGridAnyKeyContext = &_EXTChartViewGridAnyKeyContext;
static void *_EXTChartViewGridSpacingContext = &_EXTChartViewGridSpacingContext;

static CGFloat const _EXTHighlightLineWidth = 0.5;



static CFMutableDictionaryRef _glyphPathCache;

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

static const CGFloat _kDifferentialLineWidth = 0.25;

static const CGFloat _kTermCountLineWidth = 1.0;
static const CGFloat _kTermCountSingleDigitFontSizeFactor = 0.7;
static const CGFloat _kTermCountDoubleDigitFontSizeFactor = 0.55;
static NSString * const _kTermCountFontName = @"Palatino-Roman";

static CGColorRef _viewBackgroundColor;
static CGColorRef _baseGridStrokeColor;
static CGColorRef _emphasisGridStrokeColor;
static CGColorRef _axesGridStrokeColor;
static CGColorRef _artBoardBackgroundColor;
static CGColorRef _artBoardBorderColor;
static CGColorRef _artBoardShadowColor;
static CGColorRef _differentialStrokeColor;
static CGColorRef _termCountFillColor;
static CGColorRef _termCountStrokeColor;



static NSArray *dotPositions(NSInteger count, CGPoint gridPoint, CGFloat gridSpacing);



@implementation EXTChartView
{
	NSTrackingArea *_trackingArea;
	NSBezierPath *_highlightPath;

    CALayer *_gridLayer;
    CAShapeLayer *_baseGridLayer;
    CAShapeLayer *_emphasisGridLayer;
    CAShapeLayer *_axesGridLayer;

    CALayer *_artBoardBackgroundLayer;
    CALayer *_artBoardBorderLayer;

    NSArray *_termLayers;
    NSArray *_differentialLayers;
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
        _glyphPathCache = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, NULL, &kCFTypeDictionaryValueCallBacks);

        _viewBackgroundColor = CGColorCreateCopy([[NSColor windowBackgroundColor] CGColor]);
        _baseGridStrokeColor = CGColorCreateCopy([[NSColor lightGrayColor] CGColor]);
        _emphasisGridStrokeColor = CGColorCreateCopy([[NSColor darkGrayColor] CGColor]);
        _axesGridStrokeColor = CGColorCreateCopy([[NSColor blueColor] CGColor]);
        _artBoardBackgroundColor = CGColorCreateCopy([[NSColor whiteColor] CGColor]);
        _artBoardBorderColor = CGColorCreateCopy([[NSColor blackColor] CGColor]);
        _artBoardShadowColor = CGColorCreateCopy([[NSColor blackColor] CGColor]);
        _differentialStrokeColor = CGColorCreateCopy([[NSColor blackColor] CGColor]);
        _termCountFillColor = CGColorCreateCopy([[NSColor blackColor] CGColor]);
        _termCountStrokeColor = CGColorCreateCopy([[NSColor blackColor] CGColor]);
    }
}

- (instancetype)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
		[self translateOriginToPoint:NSMakePoint(NSMidX(frame), NSMidY(frame))];

        CALayer *rootLayer = [CALayer layer];
        rootLayer.frame = self.bounds;
        rootLayer.backgroundColor = _viewBackgroundColor;
        rootLayer.opaque = YES;
        rootLayer.drawsAsynchronously = YES;
        rootLayer.delegate = self;

        rootLayer.transform = CATransform3DMakeTranslation(NSMidX(frame), NSMidY(frame), 0);

        // Grid
        {
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

        // ----- Obsolete Begin
        /*
        // Grid
        {
            _showsGrid = true;

            _grid = [EXTGrid new];
            [_grid setBoundsRect:[self bounds]];
            [_grid addObserver:self forKeyPath:EXTGridAnyKey options:0 context:_EXTChartViewGridAnyKeyContext];
            [_grid addObserver:self forKeyPath:@"gridSpacing" options:0 context:_EXTChartViewGridSpacingContext];
        }

        // Highlighting
		{
            _highlightsGridPositionUnderCursor = true;
            _highlightColor = [[NSUserDefaults standardUserDefaults] extColorForKey:EXTChartViewHighlightColorPreferenceKey];
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
        
        NSArray *counts = [self.dataSource chartView:self termCountsInGridRect:reloadGridRect];
        for (EXTChartViewTermCountData *countData in counts) {
            CALayer *newTermLayer = [self layerForTermCount:countData.count];
            newTermLayer.frame = (CGRect){{countData.point.x * _grid.gridSpacing, countData.point.y * _grid.gridSpacing}, {_grid.gridSpacing, _grid.gridSpacing}};
//            newTermLayer.shouldRasterize = true;
            [newTermLayers addObject:newTermLayer];
            [self.layer addSublayer:newTermLayer];
        }
        
        _termLayers = [newTermLayers copy];
    }


    // Differentials
    {
        [_differentialLayers makeObjectsPerformSelector:@selector(removeFromSuperlayer)];

        NSMutableArray *newDifferentialLayers = [NSMutableArray new];

        NSArray *differentials = [self.dataSource chartView:self differentialsInRect:reloadRect];
        for (EXTChartViewDifferentialData *diffData in differentials) {
            CAShapeLayer *newDifferentialLayer = [CAShapeLayer layer];
            const CGPoint origin = {MIN(diffData.start.x, diffData.end.x), MIN(diffData.start.y, diffData.end.y)};
            const CGSize size = {ABS(diffData.start.x - diffData.end.x), ABS(diffData.start.y - diffData.end.y)};
            newDifferentialLayer.frame = (CGRect){origin, size};
            newDifferentialLayer.lineWidth = _kDifferentialLineWidth;
            newDifferentialLayer.strokeColor = _differentialStrokeColor;
            newDifferentialLayer.lineCap = kCALineCapRound;
            [newDifferentialLayers addObject:newDifferentialLayer];
            [self.layer addSublayer:newDifferentialLayer];

            const CGPoint start = [newDifferentialLayer convertPoint:diffData.start fromLayer:self.layer];
            const CGPoint end = [newDifferentialLayer convertPoint:diffData.end fromLayer:self.layer];
            CGMutablePathRef path = CGPathCreateMutable();
            CGPathMoveToPoint(path, NULL, start.x, start.y);
            CGPathAddLineToPoint(path, NULL, end.x, end.y);
            newDifferentialLayer.path = path;
        }

        _differentialLayers = [newDifferentialLayers copy];
    }
}

- (CAShapeLayer *)layerForTermCount:(NSInteger)count
{
    CAShapeLayer *layer = CAShapeLayer.layer;
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathMoveToPoint(path, NULL, 0.0, 0.0);

    const CGFloat _gridSpacing = _grid.gridSpacing;

    for (NSValue *rectObject in dotPositions(count, (CGPoint){0}, _gridSpacing)) {
        CGPathAddEllipseInRect(path, NULL, rectObject.rectValue);
    }

    if (count <= 3) {
        layer.fillColor = _termCountFillColor;
        layer.lineWidth = 0.0;
    }
    else {
        layer.fillColor = [[NSColor clearColor] CGColor];
        layer.strokeColor = _termCountStrokeColor;
        layer.lineWidth = _kTermCountLineWidth;

        NSString *label = [NSString stringWithFormat:@"%ld", (long)count];
        CGFloat fontSize = round((count < 10 ?
                                  _gridSpacing * _kTermCountSingleDigitFontSizeFactor :
                                  _gridSpacing * _kTermCountDoubleDigitFontSizeFactor));
        CGSize textSize;
        NSArray *glyphLayers = [self layersForString:label atSize:fontSize totalSize:&textSize];
        // Centre the layers horizontally
        const CGSize offset = {(_gridSpacing - textSize.width) / 2.0, (_gridSpacing - textSize.height) / 2.0};

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

- (NSArray *)layersForString:(NSString *)string atSize:(CGFloat)fontSize totalSize:(CGSize *)outSize
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
        //        CFDictionaryRef attributes = CTRunGetAttributes(run);
        //        CTFontRef runFont = CFDictionaryGetValue(attributes, kCTFontAttributeName);
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

    return layers;
}

- (CGPathRef)pathForGlyph:(CGGlyph)glyph atSize:(CGFloat)fontSize
{
    CTFontRef font = CTFontCreateWithName(CFSTR("Palatino-Roman"), fontSize, NULL);
    CGPathRef path = [self pathForGlyph:glyph fromFont:font];
    CFRelease(font);
    return path;
}

// From Apple’s CoreAnimationText sample code
// _glyphPathCache is a two-level dictionary where the first key is the font, the second key is the glyph and the value is the corresponding path
- (CGPathRef)pathForGlyph:(CGGlyph)glyph fromFont:(CTFontRef)font
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

- (void)resetCursorRects {
	if (self.editingArtBoard)
		[_artBoard buildCursorRectsInView:self];
}

#pragma mark - Drawing

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
    _artBoardBackgroundLayer.frame = artBoardFrame;
    _artBoardBorderLayer.frame = artBoardFrame;
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

#pragma mark - Obsolete
- (void)drawRect:(NSRect)dirtyRect {
    return;

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






NSArray *dotPositions(NSInteger count, CGPoint gridPoint, CGFloat gridSpacing)
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