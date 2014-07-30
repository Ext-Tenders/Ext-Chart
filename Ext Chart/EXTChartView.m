//
//  EXTChartView.m
//  Ext Chart
//
//  Created by Michael Hopkins on 7/20/11.
//  Copyright 2011 Harvard University. All rights reserved.
//

@import QuartzCore;

#import "EXTChartView.h"
#import "EXTScrollView.h"
#import "EXTGrid.h"
#import "EXTArtBoard.h"
#import "EXTChartViewModel.h"
#import "EXTTermLayer.h"
#import "EXTImageTermLayer.h"
#import "EXTShapeTermLayer.h"
#import "EXTDifferentialLineLayer.h"
#import "EXTMultAnnotationLayer.h"
#import "EXTChartViewInteraction.h"
#import "NSUserDefaults+EXTAdditions.h"


#pragma mark - Exported variables

NSString * const EXTChartViewHighlightColorPreferenceKey = @"EXTChartViewHighlightColor";
NSString * const EXTChartViewSelectionColorPreferenceKey = @"EXTChartViewSelectionColor";


#pragma mark - Private variables

static void *_EXTChartViewArtBoardDrawingRectContext = &_EXTChartViewArtBoardDrawingRectContext;
static void *_interactionTypeContext = &_interactionTypeContext;
static void *_showsGridContext = &_showsGridContext;
static void *_selectedObjectContext = &_selectedObjectContext;
static void *_highlightColorContext = &_highlightColorContext;
static void *_selectionColorContext = &_selectionColorContext;
static void *_inLiveMagnifyContext = &_inLiveMagnifyContext;

static void *_gridColorContext = &_gridColorContext;
static void *_gridEmphasisColorContext = &_gridEmphasisColorContext;
static void *_gridAxisColorContext = &_gridAxisColorContext;
static void *_gridSpacingContext = &_gridSpacingContext;
static void *_gridEmphasisSpacingContext = &_gridEmphasisSpacingContext;

static const CGFloat _kBelowGridZPosition = -3.0;
static const CGFloat _kGridZPosition = -2.0;
static const CGFloat _kAboveGridZPosition = -1.0;

static const CGFloat _kMultAnnotationZPosition = 1.0;
static const CGFloat _kDifferentialZPosition = 5.0;
static const CGFloat _kSelectedDifferentialZPosition = 6.0;
static const CGFloat _kTermCellZPosition = 10.0;

static const CGFloat _kBaseGridZPosition = 0.0;
static const CGFloat _kEmphasisGridZPosition = 1.0;
static const CGFloat _kAxesGridZPosition = 2.0;

static const CGFloat _kBaseGridLineWidth = 0.25;
static const CGFloat _kEmphasisGridLineWidth = 0.25;
static const CGFloat _kAxesGridLineWidth = 1.0;

static const CGFloat _kArtBoardBorderWidth = 0.75;
static const CGSize _kArtBoardShadowOffset = {-1.0, -2.0};
static const CGFloat _kArtBoardShadowRadius = 2.0;
static const CGFloat _kArtBoardShadowOpacity = 1.0;
static const CFTimeInterval _kArtBoardTransitionDuration = 0.125;

static CGColorRef _viewBackgroundColor;
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

    NSArray *_termLayers; // an array of CALayer<EXTTermLayer> objects
    NSArray *_differentialLineLayers;
    NSArray *_multAnnotationLayers;

    NSArray *_highlightedLayers; // an array of CALayer<EXTChartViewInteraction> objects, or nil
    NSSet *_selectedLayers;

    CGFloat _magnification;

    /// Operations in this queue resize term layers to match a given magnification or grid spacing. Each operation is responsible for changing all term layers in the chart view and there should be only one active operation at any given time since it’s wasteful to scale a term layer if it’s going to be scaled again.
    NSOperationQueue *_resizeTermLayersQueue;
}


#pragma mark - Life cycle

+ (void)load {
    [self exposeBinding:@"grid"];
    [self exposeBinding:@"highlightColor"];

    NSColor *highlightColor = [NSColor colorWithCalibratedRed:0.0 green:1.0 blue:1.0 alpha:1.0];
    NSColor *selectionColor = [NSColor colorWithCalibratedRed:0.0 green:0.5 blue:1.0 alpha:1.0];
    NSDictionary *defaults = @{
                               EXTChartViewHighlightColorPreferenceKey : [NSArchiver archivedDataWithRootObject:highlightColor],
                               EXTChartViewSelectionColorPreferenceKey : [NSArchiver archivedDataWithRootObject:selectionColor],
                               };
    [[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
}

+ (void)initialize
{
    if (self == [EXTChartView class]) {
        _viewBackgroundColor = CGColorCreateCopy([[NSColor windowBackgroundColor] CGColor]);
        _artBoardBackgroundColor = CGColorCreateCopy([[NSColor whiteColor] CGColor]);
        _artBoardBorderColor = CGColorCreateCopy([[NSColor blackColor] CGColor]);
        _artBoardShadowColor = CGColorCreateCopy([[NSColor blackColor] CGColor]);
    }
}

- (instancetype)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
		[self translateOriginToPoint:NSMakePoint(NSMidX(frame), NSMidY(frame))];

// Use 0 for regular, image-based interactive charts and 1 for export-only, vector-based charts
#if 0
        _exportOnly = true;
#endif

        // Interaction colors
        _highlightColor = [[NSUserDefaults standardUserDefaults] extColorForKey:EXTChartViewHighlightColorPreferenceKey];
        _selectionColor = [[NSUserDefaults standardUserDefaults] extColorForKey:EXTChartViewSelectionColorPreferenceKey];

        // Term layer resizing
        _resizeTermLayersQueue = [NSOperationQueue new];
        _resizeTermLayersQueue.maxConcurrentOperationCount = 1;

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
            _gridLayer.zPosition = _kGridZPosition;
            [rootLayer addSublayer:_gridLayer];
            
            CAShapeLayer *(^gridSublayer)(CGRect, CGFloat, CGColorRef, CGFloat) = ^(CGRect frame, CGFloat zPosition, CGColorRef strokeColor, CGFloat lineWidth){
                CAShapeLayer *layer = [CAShapeLayer layer];
                layer.frame = frame;
                layer.zPosition = zPosition;
                layer.strokeColor = strokeColor;
                layer.lineWidth = lineWidth;
                return layer;
            };
            
            _baseGridLayer = gridSublayer(_gridLayer.frame, _kBaseGridZPosition, [_grid.gridColor CGColor], _kBaseGridLineWidth);
            _emphasisGridLayer = gridSublayer(_gridLayer.frame, _kEmphasisGridZPosition, [_grid.emphasisGridColor CGColor], _kEmphasisGridLineWidth);
            _axesGridLayer = gridSublayer(_gridLayer.frame, _kAxesGridZPosition, [_grid.axisColor CGColor], _kAxesGridLineWidth);
            
            [_gridLayer addSublayer:_baseGridLayer];
            [_gridLayer addSublayer:_emphasisGridLayer];
            [_gridLayer addSublayer:_axesGridLayer];

            [self addObserver:self forKeyPath:@"showsGrid" options:NSKeyValueObservingOptionNew context:_showsGridContext];

//            @property (nonatomic, assign, getter=isVisible) bool visible;

            [_grid addObserver:self forKeyPath:@"gridColor" options:0 context:_gridColorContext];
            [_grid addObserver:self forKeyPath:@"emphasisGridColor" options:0 context:_gridEmphasisColorContext];
            [_grid addObserver:self forKeyPath:@"axisColor" options:0 context:_gridAxisColorContext];
            [_grid addObserver:self forKeyPath:@"gridSpacing" options:0 context:_gridSpacingContext];
            [_grid addObserver:self forKeyPath:@"emphasisSpacing" options:0 context:_gridEmphasisSpacingContext];
        }

        // Art board
        {
            _artBoard = [EXTArtBoard new];

            _artBoardBackgroundLayer = [CALayer layer];
            _artBoardBorderLayer = [CALayer layer];

            _artBoardBackgroundLayer.backgroundColor = _artBoardBackgroundColor;
            _artBoardBackgroundLayer.zPosition = _kBelowGridZPosition;

            _artBoardBorderLayer.zPosition = _kAboveGridZPosition;
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

        [self addObserver:self forKeyPath:@"selectedObject" options:NSKeyValueObservingOptionNew context:_selectedObjectContext];
        [self addObserver:self forKeyPath:@"interactionType" options:NSKeyValueObservingOptionNew context:_interactionTypeContext];
        [self addObserver:self forKeyPath:@"highlightColor" options:0 context:_highlightColorContext];
        [self addObserver:self forKeyPath:@"selectionColor" options:0 context:_selectionColorContext];
        [self addObserver:self forKeyPath:@"inLiveMagnify" options:0 context:_inLiveMagnifyContext];
    }

	return self;
}

- (void)dealloc {
    [self removeObserver:self forKeyPath:@"showsGrid" context:_showsGridContext];
    [self removeObserver:self forKeyPath:@"interactionType" context:_interactionTypeContext];
    [self removeObserver:self forKeyPath:@"selectedObject" context:_selectedObjectContext];
    [self removeObserver:self forKeyPath:@"highlightColor" context:_highlightColorContext];
    [self removeObserver:self forKeyPath:@"selectionColor" context:_selectionColorContext];
    [self removeObserver:self forKeyPath:@"inLiveMagnify" context:_inLiveMagnifyContext];

    [_grid removeObserver:self forKeyPath:@"gridColor" context:_gridColorContext];
    [_grid removeObserver:self forKeyPath:@"emphasisGridColor" context:_gridEmphasisColorContext];
    [_grid removeObserver:self forKeyPath:@"axisColor" context:_gridAxisColorContext];
    [_grid removeObserver:self forKeyPath:@"gridSpacing" context:_gridSpacingContext];
    [_grid removeObserver:self forKeyPath:@"emphasisSpacing" context:_gridEmphasisSpacingContext];

    [_artBoard removeObserver:self forKeyPath:@"drawingRect" context:_EXTChartViewArtBoardDrawingRectContext];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)updateVisibleRect
{
    NSClipView *clipView = [[self enclosingScrollView] contentView];
    const NSRect rect = [self convertRect:clipView.bounds fromView:clipView];
    [self updateRect:rect];
}

- (void)updateRect:(NSRect)rect {
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    {
        _gridLayer.frame = rect;
    }
    [CATransaction commit];

    const CGFloat spacing = _grid.gridSpacing;
    const NSInteger emphasisSpacing = _grid.emphasisSpacing;

    const NSInteger firstVerticalLine = (NSInteger)floor(rect.origin.x / spacing);
    const NSInteger firstHorizontalLine = (NSInteger)floor(rect.origin.y / spacing);
    const NSInteger numberOfHorizontalLines = (NSInteger)ceil(rect.size.height / spacing) + 1;
    const NSInteger numberOfVerticalLines = (NSInteger)ceil(rect.size.width / spacing) + 1;

    const CGPoint origin = {
        .x = floor(rect.origin.x / spacing) * spacing,
        .y = floor(rect.origin.y / spacing) * spacing,
    };
    const CGPoint originInSublayer = [_baseGridLayer convertPoint:origin fromLayer:self.layer];
    CGPoint point = originInSublayer;

    CGMutablePathRef basePath = CGPathCreateMutable();
    CGMutablePathRef emphasisPath = CGPathCreateMutable();

    for (NSInteger i = 0; i < numberOfHorizontalLines; ++i) {
        CGMutablePathRef path = ((firstHorizontalLine + i) % emphasisSpacing) == 0 ? emphasisPath : basePath;
        CGPathMoveToPoint(path, NULL, point.x, point.y);
        CGPathAddLineToPoint(path, NULL, point.x + rect.size.width + spacing, point.y);

        point.y += spacing;
    }

    point = originInSublayer;
    for (NSInteger i = 0; i < numberOfVerticalLines; ++i) {
        CGMutablePathRef path = ((firstVerticalLine + i) % emphasisSpacing) == 0 ? emphasisPath : basePath;
        CGPathMoveToPoint(path, NULL, point.x, point.y);
        CGPathAddLineToPoint(path, NULL, point.x, point.y + rect.size.height + spacing);

        point.x += spacing;
    }

    const bool crossesYAxis = NSMinX(rect) <= 0.0 && NSMaxX(rect) >= 0.0;
    const bool crossesXAxis = NSMinY(rect) <= 0.0 && NSMaxY(rect) >= 0.0;

    CGMutablePathRef axesPath = NULL;
    if (crossesXAxis || crossesYAxis) {
        axesPath = CGPathCreateMutable();

        if (crossesYAxis) {
            const CGPoint p1 = [_axesGridLayer convertPoint:(CGPoint){0.0, NSMinY(rect)} fromLayer:self.layer];
            const CGPoint p2 = [_axesGridLayer convertPoint:(CGPoint){0.0, NSMaxY(rect)} fromLayer:self.layer];

            CGPathMoveToPoint(axesPath, NULL, p1.x, p1.y);
            CGPathAddLineToPoint(axesPath, NULL, p2.x, p2.y);
        }

        if (crossesXAxis) {
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

    const CGFloat newMagnification = [[self enclosingScrollView] magnification];
    if (!self.inLiveMagnify && _magnification != newMagnification) {
        [self reloadTermLayerContentsToFitMagnification:newMagnification];
        // TODO: We could prioritise visible layers first, or maybe reset only visible layers. Need to mind
        //       PDF export, though.
    }

    _magnification = newMagnification;

    CGPathRelease(basePath);
    CGPathRelease(emphasisPath);
    CGPathRelease(axesPath);
}

- (void)reloadTermLayerContentsToFitMagnification:(CGFloat)magnification {
    if (self.exportOnly) return;

    [self reloadTermContentsWithBlock:^(EXTImageTermLayer *termLayer) {
        termLayer.contentsScale = magnification;
    } cancellable:true];
}

// FIXME: find a selector name where the block parameter is the last parameter
- (void)reloadTermContentsWithBlock:(void(^)(EXTImageTermLayer *termLayer))block cancellable:(bool)cancellable {
    NSParameterAssert(block);

    if (self.exportOnly) return;

    NSArray *termLayers = [_termLayers copy];
    const size_t termLayersCount = [_termLayers count];
    dispatch_queue_t resizeQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);

    [[_resizeTermLayersQueue operations] makeObjectsPerformSelector:@selector(cancel)];

    NSBlockOperation *resizeTermLayerOperation = [NSBlockOperation new];
    __weak NSBlockOperation *weakResizeTermLayerOperation = resizeTermLayerOperation;

    [resizeTermLayerOperation addExecutionBlock:^{
        dispatch_apply(termLayersCount, resizeQueue, ^(size_t layerIndex) {
            if (!(cancellable && [weakResizeTermLayerOperation isCancelled])) {
                EXTImageTermLayer *termLayer = termLayers[layerIndex];

                [CATransaction begin];
                [CATransaction setDisableActions:YES];
                {
                    block(termLayer);
                    [termLayer reloadContents];
                }
                [CATransaction commit];
            }
        });
    }];

    [_resizeTermLayersQueue addOperation:resizeTermLayerOperation];
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
        Class<EXTTermLayerBase> termLayerClass = (self.exportOnly ? [EXTShapeTermLayer class] : [EXTImageTermLayer class]);
        const bool interactiveTermLayer = (termLayerClass == [EXTImageTermLayer class]);

        for (EXTChartViewModelTermCell *termCell in termCells) {
            CALayer<EXTTermLayerBase> *newTermLayer = [termLayerClass termLayerWithTermCell:termCell length:_grid.gridSpacing];
            newTermLayer.frame = (CGRect){{termCell.gridLocation.x * _grid.gridSpacing, termCell.gridLocation.y * _grid.gridSpacing}, {_grid.gridSpacing, _grid.gridSpacing}};
            newTermLayer.zPosition = _kTermCellZPosition;
            newTermLayer.contentsScale = _magnification;

            if (interactiveTermLayer) {
                id<EXTChartViewInteraction> layer = (id<EXTChartViewInteraction>)newTermLayer;
                layer.highlightColor = [_highlightColor CGColor];
                layer.selectionColor = [_selectionColor CGColor];
            }

            [newTermLayers addObject:newTermLayer];
            [self.layer addSublayer:newTermLayer];
        }

        if (!self.exportOnly) [newTermLayers makeObjectsPerformSelector:@selector(reloadContents)];
        _termLayers = [newTermLayers copy];
    }


    // Differentials
    {
        [_differentialLineLayers makeObjectsPerformSelector:@selector(removeFromSuperlayer)];

        NSMutableArray *newDifferentialLineLayers = [NSMutableArray new];

        NSArray *differentials = [self.dataSource chartView:self differentialsInGridRect:reloadGridRect];
        for (EXTChartViewModelDifferential *diff in differentials) {
            const CGRect layerFrame = [self frameForDifferential:diff];

            for (EXTChartViewModelDifferentialLine *line in diff.lines) {
                EXTDifferentialLineLayer *newDifferentialLineLayer = [EXTDifferentialLineLayer layer];
                newDifferentialLineLayer.frame = layerFrame;
                newDifferentialLineLayer.differential = diff;
                newDifferentialLineLayer.line = line;
                newDifferentialLineLayer.highlightColor = [_highlightColor CGColor];
                newDifferentialLineLayer.selectionColor = [_selectionColor CGColor];
                newDifferentialLineLayer.defaultZPosition = _kDifferentialZPosition;
                newDifferentialLineLayer.selectedZPosition = _kSelectedDifferentialZPosition;
                [newDifferentialLineLayers addObject:newDifferentialLineLayer];
                [self.layer addSublayer:newDifferentialLineLayer];

                CGPoint start, end;
                [self getStart:&start end:&end forDifferential:diff line:line];
                const CGPoint startInLayer = [newDifferentialLineLayer convertPoint:start fromLayer:self.layer];
                const CGPoint endInLayer = [newDifferentialLineLayer convertPoint:end fromLayer:self.layer];

                CGMutablePathRef path = CGPathCreateMutable();
                CGPathMoveToPoint(path, NULL, startInLayer.x, startInLayer.y);
                CGPathAddLineToPoint(path, NULL, endInLayer.x, endInLayer.y);
                newDifferentialLineLayer.path = path;
                CGPathRelease(path);
            }
        }

        _differentialLineLayers = [newDifferentialLineLayers copy];
    }
    
    // multiplicative annotations.
    {
        [_multAnnotationLayers makeObjectsPerformSelector:@selector(removeFromSuperlayer)];
        
        NSMutableArray *newMultAnnotationLayers = [NSMutableArray new];
        
        NSArray *annotations = [self.dataSource chartView:self multAnnotationsInRect:reloadGridRect];
        
        for (NSDictionary *annotationGroup in annotations) {
            NSArray *multAnnotations = annotationGroup[@"annotations"];
            
            // TODO: eventually we will want to read the style we're supposed to
            // draw these multiplications in from the "style" key of the dicationary
            
            //[[NSColor blackColor] set];
            //NSBezierPath *line = [NSBezierPath bezierPath];
            //[line setLineWidth:0.25];
            //[line setLineCapStyle:NSRoundLineCapStyle];
            
            for (EXTChartViewModelMultAnnotation *annoData in multAnnotations) {
                EXTMultAnnotationLineLayer *newAnnotationLayer = [EXTMultAnnotationLineLayer layer];
                
                const CGPoint start = [_grid convertPointToView:annoData.startTerm.termCell.gridLocation];
                const CGPoint end = [_grid convertPointToView:annoData.endTerm.termCell.gridLocation];
                const CGPoint origin = {MIN(start.x, end.x), MIN(start.y, end.y)};
                const CGSize size = {ABS(start.x - end.x), ABS(start.y - end.y)};
                const NSInteger startTotalRank = annoData.startTerm.termCell.totalRank;
                const NSInteger endTotalRank = annoData.endTerm.termCell.totalRank;
                
                newAnnotationLayer.frame = (CGRect){origin, size};
                newAnnotationLayer.annotation = annoData;
                newAnnotationLayer.defaultZPosition = _kMultAnnotationZPosition;
                [newMultAnnotationLayers addObject:newAnnotationLayer];
                [self.layer addSublayer:newAnnotationLayer];
                
                const NSRect startDotRect = [EXTChartView dotBoundingBoxForCellRank:startTotalRank
                                                                          termIndex:0
                                                                       gridLocation:annoData.startTerm.termCell.gridLocation
                                                                        gridSpacing:_grid.gridSpacing];
                const NSRect endDotRect = [EXTChartView dotBoundingBoxForCellRank:endTotalRank
                                                                        termIndex:0
                                                                     gridLocation:annoData.endTerm.termCell.gridLocation
                                                                      gridSpacing:_grid.gridSpacing];
                
                const CGPoint startDotConnectionPoint = (startTotalRank <= 3 ?
                                                         (CGPoint){NSMidX(startDotRect), NSMidY(startDotRect)} :
                                                         (CGPoint){NSMinX(startDotRect), NSMidY(startDotRect)});
                const CGPoint endDotConnectionPoint = (endTotalRank <= 3 ?
                                                       (CGPoint){NSMidX(endDotRect), NSMidY(endDotRect)} :
                                                       (CGPoint){NSMaxX(endDotRect), NSMidY(endDotRect)});
                const CGPoint startInLayer = [newAnnotationLayer convertPoint:startDotConnectionPoint fromLayer:self.layer];
                const CGPoint endInLayer = [newAnnotationLayer convertPoint:endDotConnectionPoint fromLayer:self.layer];
                
                CGMutablePathRef path = CGPathCreateMutable();
                CGPathMoveToPoint(path, NULL, startInLayer.x, startInLayer.y);
                CGPathAddLineToPoint(path, NULL, endInLayer.x, endInLayer.y);
                newAnnotationLayer.path = path;
                CGPathRelease(path);
            }
        }
        
        _multAnnotationLayers = [newMultAnnotationLayers copy];
    }
}


- (void)resetCursorRects
{
	if (self.interactionType == EXTChartInteractionTypeArtBoard) [_artBoard buildCursorRectsInView:self];
}

- (void)updateHighlight
{
    switch (self.interactionType) {
        case EXTChartInteractionTypeTerm:
            [self updateTermHighlight];
            break;

        case EXTChartInteractionTypeDifferential:
            [self updateDifferentialHighlight];
            break;

        case EXTChartInteractionTypeMultiplicativeStructure:
        case EXTChartInteractionTypeArtBoard:
        case EXTChartInteractionTypeNone:
        default:
            break;
    }
}

- (void)updateTermHighlight
{
    if (self.exportOnly) return;

    id<EXTChartViewInteraction> layerToHighlight = nil;

    const NSRect dataRect = [_trackingArea rect];
    const NSPoint currentMouseLocation = [self convertPoint:[[self window] mouseLocationOutsideOfEventStream] fromView:nil];
    if (NSPointInRect(currentMouseLocation, dataRect)) {
        const EXTIntPoint mouseLocationInGrid = [_grid convertPointFromView:currentMouseLocation];
        for (CALayer<EXTTermLayerBase, EXTChartViewInteraction> *layer in _termLayers) {
            if (EXTEqualIntPoints(layer.termCell.gridLocation, mouseLocationInGrid)) {
                layerToHighlight = layer;
                break;
            }
        }
    }

    id<EXTChartViewInteraction> currentlyHighlightedLayer = [_highlightedLayers firstObject];
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
    if (self.exportOnly) return;

    NSMutableArray *layersToHighlight = [NSMutableArray new];

    const NSRect dataRect = [_trackingArea rect];
    const NSPoint currentMouseLocation = [self convertPoint:[[self window] mouseLocationOutsideOfEventStream] fromView:nil];
    if (NSPointInRect(currentMouseLocation, dataRect)) {
        const EXTIntPoint mouseLocationInGrid = [_grid convertPointFromView:currentMouseLocation];
        for (EXTDifferentialLineLayer *layer in _differentialLineLayers) {
            if (EXTEqualIntPoints(layer.differential.startTerm.termCell.gridLocation, mouseLocationInGrid)) {
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

- (CGRect)frameForDifferential:(EXTChartViewModelDifferential *)differential {
    const CGPoint start = [self.grid convertPointToView:differential.startTerm.termCell.gridLocation];
    const CGPoint end = [self.grid convertPointToView:differential.endTerm.termCell.gridLocation];
    const CGPoint origin = {MIN(start.x, end.x), MIN(start.y, end.y)};
    const CGSize size = {ABS(start.x - end.x), ABS(start.y - end.y)};

    return (CGRect){origin, size};
}

- (void)getStart:(CGPoint *)start
             end:(CGPoint *)end
 forDifferential:(EXTChartViewModelDifferential *)differential
            line:(EXTChartViewModelDifferentialLine *)line
{
    NSParameterAssert(start);
    NSParameterAssert(end);
    NSParameterAssert(differential);
    NSParameterAssert(line);

    const NSInteger startTotalRank = differential.startTerm.termCell.totalRank;
    const NSInteger endTotalRank = differential.endTerm.termCell.totalRank;

    const NSRect startDotRect = [EXTChartView dotBoundingBoxForCellRank:startTotalRank
                                                              termIndex:line.startIndex
                                                           gridLocation:differential.startTerm.termCell.gridLocation
                                                            gridSpacing:self.grid.gridSpacing];
    const NSRect endDotRect = [EXTChartView dotBoundingBoxForCellRank:endTotalRank
                                                            termIndex:line.endIndex
                                                         gridLocation:differential.endTerm.termCell.gridLocation
                                                          gridSpacing:self.grid.gridSpacing];

    *start = (startTotalRank <= 3 ?
              (CGPoint){NSMidX(startDotRect), NSMidY(startDotRect)} :
              (CGPoint){NSMinX(startDotRect), NSMidY(startDotRect)});

    *end = (endTotalRank <= 3 ?
            (CGPoint){NSMidX(endDotRect), NSMidY(endDotRect)} :
            (CGPoint){NSMaxX(endDotRect), NSMidY(endDotRect)});
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

// FIXME: simplify this monster
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	if (context == _EXTChartViewArtBoardDrawingRectContext) {
        [self setNeedsDisplayInRect:NSUnionRect([change[NSKeyValueChangeOldKey] rectValue], [_artBoard drawingRect])];
        if (self.interactionType == EXTChartInteractionTypeArtBoard)
            [[self window] invalidateCursorRectsForView:self];
	}
    else if (context == _gridColorContext) {
        _baseGridLayer.strokeColor = [_grid.gridColor CGColor];
    }
    else if (context == _gridEmphasisColorContext) {
        _emphasisGridLayer.strokeColor = [_grid.emphasisGridColor CGColor];
    }
    else if (context == _gridAxisColorContext) {
        _axesGridLayer.strokeColor = [_grid.axisColor CGColor];
    }
    else if (context == _gridSpacingContext) {
        const CGFloat magnification = [[self enclosingScrollView] magnification];
        const CGFloat gridSpacing = self.grid.gridSpacing;

        [self reloadTermContentsWithBlock:^(EXTImageTermLayer *termLayer) {
            const EXTIntPoint gridLocation = termLayer.termCell.gridLocation;

            termLayer.frame = (CGRect){{gridLocation.x * gridSpacing, gridLocation.y * gridSpacing}, {gridSpacing, gridSpacing}};
            termLayer.contentsScale = magnification;
        } cancellable:false];


        [CATransaction begin];
        [CATransaction setDisableActions:YES];
        for (EXTDifferentialLineLayer *diffLayer in _differentialLineLayers) {
            EXTChartViewModelDifferential *diff = diffLayer.differential;
            EXTChartViewModelDifferentialLine *line = diffLayer.line;

            diffLayer.frame = [self frameForDifferential:diff];

            CGPoint start, end;
            [self getStart:&start end:&end forDifferential:diff line:line];
            const CGPoint startInLayer = [diffLayer convertPoint:start fromLayer:self.layer];
            const CGPoint endInLayer = [diffLayer convertPoint:end fromLayer:self.layer];

            CGMutablePathRef path = CGPathCreateMutable();
            CGPathMoveToPoint(path, NULL, startInLayer.x, startInLayer.y);
            CGPathAddLineToPoint(path, NULL, endInLayer.x, endInLayer.y);
            diffLayer.path = path;
            CGPathRelease(path);
        }
        [CATransaction commit];

        [self updateVisibleRect];
        [self _extAlignArtBoardToGrid];
        [self _extUpdateArtBoardMinimumSize];
	}
    else if (context == _gridEmphasisSpacingContext) {
        [self updateVisibleRect];
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
            [self updateVisibleRect];
        }
        else {
            [_gridLayer removeFromSuperlayer];
        }
    }
    else if (context == _selectedObjectContext) {
        [self reflectSelection];
    }
    else if (context == _highlightColorContext) {
        CGColorRef highlightColor = [self.highlightColor CGColor];
        for (CALayer<EXTChartViewInteraction> *layer in _termLayers) layer.highlightColor = highlightColor;
        for (CALayer<EXTChartViewInteraction> *layer in _differentialLineLayers) layer.highlightColor = highlightColor;
    }
    else if (context == _selectionColorContext) {
        CGColorRef selectionColor = [self.selectionColor CGColor];
        for (CALayer<EXTChartViewInteraction> *layer in _termLayers) layer.selectionColor = selectionColor;
        for (CALayer<EXTChartViewInteraction> *layer in _differentialLineLayers) layer.selectionColor = selectionColor;
    }
    else if (context == _inLiveMagnifyContext) {
        if (!self.inLiveMagnify) {
            [self reloadTermLayerContentsToFitMagnification:[[self enclosingScrollView] magnification]];
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

    if (self.interactionType == EXTChartInteractionTypeArtBoard) {
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

- (void)reflectSelection
{
    if (self.exportOnly) return;

    if ([self.selectedObject isKindOfClass:[EXTChartViewModelTerm class]]) {
        [self reflectSelectedTerm];
    }
    else if ([self.selectedObject isKindOfClass:[EXTChartViewModelDifferential class]]) {
        [self reflectSelectedDifferential];
    }
    else {
        [self reflectNoSelection];
    }
}

- (void)reflectSelectedTerm
{
    NSAssert([self.selectedObject isKindOfClass:[EXTChartViewModelTerm class]], @"Mismatched selected object");

    id<EXTChartViewInteraction> layerToSelect = nil;
    for (CALayer<EXTTermLayerBase, EXTChartViewInteraction> *layer in _termLayers) {
        if ([layer.termCell.terms containsObject:self.selectedObject]) {
            layerToSelect = layer;
            break;
        }
    }

    id<EXTChartViewInteraction> selectedLayer = _selectedLayers.anyObject;

    // FIXME: Need to think about this. We can click a term cell multiple times and the selection *changes* if there
    //        are multiple terms located on that cell, and we may want to distinguish this visually
//    if (_selectedLayer != layerToSelect) {
        [CATransaction begin];
        {
            if (selectedLayer != layerToSelect) {
            {
                [CATransaction setAnimationDuration:_kTermHighlightRemoveAnimationDuration];
                [CATransaction setAnimationTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn]];

                selectedLayer.selectedObject = false;
            }
            }
            {
                [CATransaction setAnimationDuration:_kTermHighlightAddAnimationDuration];
                [CATransaction setAnimationTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut]];

                layerToSelect.selectedObject = true;
            }
        }
        [CATransaction commit];

        _selectedLayers = [NSSet setWithObject:layerToSelect];
//    }
}

- (void)reflectSelectedDifferential
{
    NSAssert([self.selectedObject isKindOfClass:[EXTChartViewModelDifferential class]], @"Mismatched selected object");

    NSMutableSet *layersToSelect = [NSMutableSet new];

    for (EXTDifferentialLineLayer *layer in _differentialLineLayers) {
        if (layer.differential == self.selectedObject) {
            [layersToSelect addObject:layer];
        }
    }

    NSMutableSet *layersToRemoveSelection = [_selectedLayers mutableCopy];
    [layersToRemoveSelection minusSet:layersToSelect];

    [CATransaction begin];
    {
        [CATransaction setAnimationTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut]];

        {
            [CATransaction setAnimationDuration:_kDifferentialHighlightRemoveAnimationDuration];
            for (id<EXTChartViewInteraction> layer in layersToRemoveSelection) layer.selectedObject = false;

        }
        {
            [CATransaction setAnimationDuration:_kDifferentialHighlightAddAnimationDuration];
            for (id<EXTChartViewInteraction> layer in layersToSelect) layer.selectedObject = true;
        }
    }
    [CATransaction commit];

    _selectedLayers = [layersToSelect copy];
}

- (void)reflectNoSelection
{
    for (id<EXTChartViewInteraction> layer in _selectedLayers) layer.selectedObject = false;
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

+ (CGRect)dotBoundingBoxForCellRank:(NSInteger)cellRank
                          termIndex:(NSInteger)termIndex
                       gridLocation:(EXTIntPoint)gridLocation
                        gridSpacing:(NSInteger)gridSpacing
{
    switch (cellRank) {
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
