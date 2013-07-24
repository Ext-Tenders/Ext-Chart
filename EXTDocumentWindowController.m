//
//  EXTDocumentWindowController.m
//  Ext Chart
//
//  Created by Bavarious on 31/05/2013.
//  Copyright (c) 2013 Harvard University. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "EXTDocumentWindowController.h"
#import "EXTDocument.h"
#import "EXTTerm.h"
#import "EXTDifferential.h"
#import "EXTChartView.h"
#import "EXTGrid.h"
#import "EXTArtBoard.h"
#import "EXTScrollView.h"
#import "EXTSpectralSequence.h"
#import "EXTDocumentInspectorView.h"


#pragma mark - Private variables

static void *_EXTScrollViewMagnificationContext = &_EXTScrollViewMagnificationContext;
static void *_EXTSelectedPageIndexContext = &_EXTSelectedPageIndexContext;
static CGFloat const _EXTDefaultMagnificationSteps[] = {0.1, 0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 2.0, 4.0, 8.0, 16.0, 32.0};
static size_t const _EXTDefaultMagnificationStepsCount = sizeof(_EXTDefaultMagnificationSteps) / sizeof(_EXTDefaultMagnificationSteps[0]);
static CGFloat _EXTMagnificationStepRoundingMultiplier = 100.0;

// We use -[NSMenuItem representedObject] to store the magnification that a zoom pop up menu item represents. Since
// other magnifications are added to the pop up menu (for instance, when the user chooses zoom to fit) and we remove
// them if the user then chooses a default magnification, we use -[NSMenuItem tag] to indicate whether a menu item
// is a default magnification or a custom one. For the sake of completeness, we also set a different tag for the other
// menu item that does not represent a default magnification: zoom to fit.
typedef enum : NSInteger {
    _EXTDefaultMagnificationStepTag = 1,
    _EXTCustomMagnificationTag = 2,
    _EXTZoomToFitTag = 3,
} EXTMagnificationTag;


@interface EXTDocumentWindowController () <NSWindowDelegate, NSUserInterfaceValidations>
    @property(nonatomic, weak) IBOutlet NSView *mainView;
    @property(nonatomic, weak) IBOutlet EXTChartView *chartView;
    @property(nonatomic, weak) IBOutlet EXTScrollView *chartScrollView;
    @property(nonatomic, weak) IBOutlet NSView *controlsView;
    @property(nonatomic, weak) IBOutlet NSPopUpButton *zoomPopUpButton;
    @property(nonatomic, weak) IBOutlet NSPopUpButton *pagesPopUpButton;
    @property(nonatomic, weak) IBOutlet NSButton *editArtBoardsButton;
    @property(nonatomic, weak) IBOutlet NSMatrix *toolboxMatrix;

    @property(nonatomic, strong) NSView *sidebarView;
    @property(nonatomic, weak) IBOutlet NSView *gridInspectorView;

    @property(nonatomic, assign) NSUInteger maxPage;
    @property(nonatomic, readonly) EXTDocument *extDocument;
@end


@implementation EXTDocumentWindowController {
    EXTDocumentInspectorView *_inspectorView;
    bool _sidebarHidden;
    bool _sidebarAnimating;
}

#pragma mark - Life cycle

- (id)init {
    return [super initWithWindowNibName:@"EXTDocument"];
}

- (void)windowDidLoad {
    [super windowDidLoad];
    [[self window] setDelegate:self];

    // Edit art boards pop up button
    {
        [[_editArtBoardsButton cell] setHighlightsBy:NSChangeBackgroundCellMask];
    }

    // Zoom levels pop up button
    {
        NSMenu *zoomMenu = [[NSMenu alloc] initWithTitle:@""];
        for (NSInteger i = 0; i < _EXTDefaultMagnificationStepsCount; i++) {
            NSString *plainTitle = [NSString stringWithFormat:@"%ld%%", lround(_EXTDefaultMagnificationSteps[i] * _EXTMagnificationStepRoundingMultiplier)];
            NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:plainTitle action:@selector(applyMagnification:) keyEquivalent:@""];
            [menuItem setRepresentedObject:@(_EXTDefaultMagnificationSteps[i])];
            [menuItem setTag:_EXTDefaultMagnificationStepTag];
            [zoomMenu addItem:menuItem];
        }

        [zoomMenu addItem:[NSMenuItem separatorItem]];

        NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:@"Zoom to Fit" action:@selector(zoomToFit:) keyEquivalent:@""];
        [menuItem setTag:_EXTZoomToFitTag];
        [zoomMenu addItem:menuItem];
        
        [_zoomPopUpButton setMenu:zoomMenu];
    }

    // Chart view
    {
        [_chartView setDelegate:self];
        [_chartView bind:EXTChartViewSseqBindingName toObject:[self document] withKeyPath:@"sseq" options:nil];
        [_chartView addObserver:self forKeyPath:@"selectedPageIndex" options:0 context:_EXTSelectedPageIndexContext];
    }

    // Chart scroll view
    {
        [_chartScrollView setHasHorizontalRuler:YES];
        [_chartScrollView setHasVerticalRuler:YES];
        [[_chartScrollView horizontalRulerView] setOriginOffset:-[_chartView bounds].origin.x];
        [[_chartScrollView horizontalRulerView] setReservedThicknessForMarkers:0.0];
        [[_chartScrollView verticalRulerView] setOriginOffset:-[_chartView bounds].origin.y];
        [_chartScrollView setUsesPredominantAxisScrolling:NO];
        [_chartScrollView setRulersVisible:YES];
        [_chartScrollView setAllowsMagnification:YES];
        [_chartScrollView setMinMagnification:_EXTDefaultMagnificationSteps[0]];
        [_chartScrollView setMaxMagnification:_EXTDefaultMagnificationSteps[_EXTDefaultMagnificationStepsCount - 1]];

        [_chartScrollView addObserver:self forKeyPath:@"magnification" options:0 context:_EXTScrollViewMagnificationContext];

        // Offset the clip view a bit to the left and bottom so that the origin does not coincide with the window’s bottom-left corner,
        // making the art board border and the axes more noticeable.
        // Also, increase the initial scale factor.
        // IMO, this looks nicer than -[EXTChartView zoomToFit:]
        const NSRect visibleRect = NSInsetRect([[_chartView artBoard] frame], -20.0, -20.0);
        [_chartScrollView magnifyToFitRect:visibleRect];
        [_chartView scrollRectToVisible:visibleRect];
    }

    // Controls view
    {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(controlsViewFrameDidChange:) name:NSViewFrameDidChangeNotification object:_controlsView];
    }

    // Pages pop up button
    {
        NSMenu *pagesMenu = [[NSMenu alloc] initWithTitle:@""];

        // TODO: this is not quite right. I’m setting an arbitrary number of pages, but this actually depends on the current document
        [self setMaxPage:10];
        for (NSInteger page = 0; page < _maxPage; page++) {
            NSString *title = [NSString stringWithFormat:@"Page %ld", page];
            NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:title action:@selector(selectPage:) keyEquivalent:@""];
            [menuItem setRepresentedObject:@(page)];
            [pagesMenu addItem:menuItem];
        }
        
        [pagesMenu addItem:[NSMenuItem separatorItem]];
        
        NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:@"Add Page" action:@selector(addPage:) keyEquivalent:@""];
        [pagesMenu addItem:menuItem];

        [_pagesPopUpButton setMenu:pagesMenu];
    }

    // Toolbox matrix
    {
        [_chartView setSelectedToolTag:_EXTSelectionToolTag];
        [self _extCenterToolbox];
    }


    // Sidebar & inspector views
    {
        _inspectorView = [[EXTDocumentInspectorView alloc] initWithFrame:NSZeroRect];

        NSTextView *sampleTextView = [[NSTextView alloc] initWithFrame:(NSRect){.size = {200.0, 50.0}}];
        [sampleTextView setAutoresizingMask:NSViewWidthSizable];
        [_inspectorView addSubview:sampleTextView withTitle:@"Text" collapsed:true];

        [_inspectorView addSubview:_gridInspectorView withTitle:@"Grid" collapsed:false];

        sampleTextView = [[NSTextView alloc] initWithFrame:(NSRect){.size = {250.0, 800.0}}];
        [sampleTextView setAutoresizingMask:NSViewWidthSizable];
        [_inspectorView addSubview:sampleTextView withTitle:@"More text" collapsed:true];

        NSRect contentFrame = [[[self window] contentView] frame];
        NSSize scrollViewSize = [NSScrollView contentSizeForFrameSize:[_inspectorView frame].size hasHorizontalScroller:NO hasVerticalScroller:YES borderType:NSNoBorder];
        scrollViewSize.height = contentFrame.size.height;
        NSScrollView *inspectorScrollView = [[NSScrollView alloc] initWithFrame:(NSRect){NSZeroPoint, scrollViewSize}];
        [inspectorScrollView setHasHorizontalScroller:NO];
        [inspectorScrollView setHasVerticalScroller:YES];
        [inspectorScrollView setAutohidesScrollers:YES];
        [inspectorScrollView setBorderType:NSNoBorder];
        [inspectorScrollView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
        [inspectorScrollView setDrawsBackground:YES];
        [inspectorScrollView setBackgroundColor:[NSColor windowBackgroundColor]];
        [inspectorScrollView setDocumentView:_inspectorView];

        NSRect sidebarFrame = {{NSMaxX(contentFrame), 0.0}, scrollViewSize};
        _sidebarView = [[NSView alloc] initWithFrame:sidebarFrame];
        [_sidebarView setWantsLayer:YES];
        [_sidebarView setAutoresizingMask:NSViewHeightSizable | NSViewMinXMargin];
        [_sidebarView addSubview:inspectorScrollView];

        // Sidebar left border
        CALayer *sidebarLeftBorderLayer = [CALayer layer];
        [sidebarLeftBorderLayer setBorderWidth:0.5];
        [sidebarLeftBorderLayer setBorderColor:[[NSColor darkGrayColor] CGColor]];
        [sidebarLeftBorderLayer setFrame:(CGRect){NSZeroPoint, {0.5, scrollViewSize.height}}];
        [sidebarLeftBorderLayer setAutoresizingMask:kCALayerHeightSizable];
        [sidebarLeftBorderLayer setShadowColor:[[NSColor whiteColor] CGColor]];
        [sidebarLeftBorderLayer setShadowRadius:0.0];
        [sidebarLeftBorderLayer setShadowOpacity:1.0];
        [sidebarLeftBorderLayer setShadowOffset:(CGSize){1.0, 0.0}];
        [[_sidebarView layer] addSublayer:sidebarLeftBorderLayer];
        
        [[[self window] contentView] addSubview:_sidebarView];
        _sidebarHidden = true;
    }

    // Ready, set, go
    [[self window] makeFirstResponder:_chartView];

    // For debug only at the moment, but this may evolve to a preference
    // $ defaults write edu.harvard.math.Ext-Chart EXTInspectorVisible -bool YES
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"EXTInspectorVisible"])
        [self toggleInspector:nil];
}

- (void)windowWillClose:(NSNotification *)notification {
    [_chartView removeObserver:self forKeyPath:@"selectedPageIndex"];
    [_chartScrollView removeObserver:self forKeyPath:@"magnification"];

    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSViewFrameDidChangeNotification object:_controlsView];
}

#pragma mark - Zoom

- (IBAction)applyMagnification:(id)sender {
    NSAssert([sender respondsToSelector:@selector(representedObject)], @"Sender must respond to -representedObject");
    const CGFloat targetMagnification = [[sender representedObject] doubleValue];
    if (targetMagnification == [_chartScrollView magnification])
        return;
    NSClipView *clipView = [_chartScrollView contentView];
    const NSRect clipViewBounds = [clipView bounds];
    const NSPoint clipViewCentre = {NSMidX(clipViewBounds), NSMidY(clipViewBounds)};

    // TODO: -setMagnification:centeredAtPoint: does not work correctly with visible rulers, so we
    // scroll manually after setting the magnification whilst this bug is not fixed.
    //    [self setMagnification:[step scaleFactor] centeredAtPoint:clipViewCentre];

    [_chartScrollView setMagnification:targetMagnification];

    const NSPoint documentViewCentre = [[_chartScrollView documentView] convertPoint:clipViewCentre fromView:clipView];
    const NSSize newSize = [clipView bounds].size;
    const NSPoint newOrigin = {
        .x = documentViewCentre.x - newSize.width / 2.0,
        .y = documentViewCentre.y - newSize.height / 2.0
    };
    [[_chartScrollView documentView] scrollPoint:newOrigin];

    // Since we’ve just applied one of the default magnifications, there’s no need to show the previous custom magnification, if any.
    [self _extRemoveCustomZoomFromPopUpMenu];
}

- (IBAction)zoomIn:(id)sender {
    const long currentRoundedMagnification = lround([_chartScrollView magnification] * _EXTMagnificationStepRoundingMultiplier);
    NSInteger nextStepIndex;
    for (nextStepIndex = 0; nextStepIndex < _EXTDefaultMagnificationStepsCount; nextStepIndex++) {
        const long stepRoundedMagnification = lround(_EXTDefaultMagnificationSteps[nextStepIndex] * _EXTMagnificationStepRoundingMultiplier);
        if (stepRoundedMagnification > currentRoundedMagnification)
            break;
    }

    [self _extRemoveCustomZoomFromPopUpMenu];

    if (nextStepIndex != _EXTDefaultMagnificationStepsCount) {
        [_zoomPopUpButton selectItemAtIndex:nextStepIndex];
        [[_zoomPopUpButton menu] performActionForItemAtIndex:nextStepIndex];
    }
}

- (IBAction)zoomOut:(id)sender {
    const long currentRoundedMagnification = lround([_chartScrollView magnification] * _EXTMagnificationStepRoundingMultiplier);
    NSInteger previousStepIndex;
    for (previousStepIndex = _EXTDefaultMagnificationStepsCount - 1; previousStepIndex >= 0; previousStepIndex--) {
        const long stepRoundedMagnification = lround(_EXTDefaultMagnificationSteps[previousStepIndex] * _EXTMagnificationStepRoundingMultiplier);
        if (stepRoundedMagnification < currentRoundedMagnification)
            break;
    }

    [self _extRemoveCustomZoomFromPopUpMenu];

    if (previousStepIndex >= 0) {
        [_zoomPopUpButton selectItemAtIndex:previousStepIndex];
        [[_zoomPopUpButton menu] performActionForItemAtIndex:previousStepIndex];
    }
}

- (void)_extRemoveCustomZoomFromPopUpMenu {
    NSMenu *menu = [_zoomPopUpButton menu];
    NSUInteger indexToRemove = [[menu itemArray] indexOfObjectPassingTest:^BOOL(NSMenuItem *menuItem, NSUInteger idx, BOOL *stop) {
        return [menuItem tag] == _EXTCustomMagnificationTag;
    }];
    if (indexToRemove != NSNotFound)
        [menu removeItemAtIndex:indexToRemove];
}

#pragma mark - Pages

- (void)selectPage:(id)sender {
    NSAssert([sender respondsToSelector:@selector(representedObject)], @"Sender must respond to -representedObject");
    const NSUInteger targetPage = [[sender representedObject] unsignedIntegerValue];

    if (targetPage <= _maxPage)
        [_chartView setSelectedPageIndex:targetPage];
}

- (IBAction)addPage:(id)sender {
    [self setMaxPage:[self maxPage] + 1];

    NSString *title = [NSString stringWithFormat:@"Page %lu", _maxPage];
    NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:title action:@selector(selectPage:) keyEquivalent:@""];
    [menuItem setRepresentedObject:@(_maxPage)];
    [[_pagesPopUpButton menu] insertItem:menuItem atIndex:_maxPage];
    [_pagesPopUpButton selectItemAtIndex:_maxPage];
    [[_pagesPopUpButton menu] performActionForItemAtIndex:_maxPage];
}

#pragma mark - Properties

- (void)setDocument:(NSDocument *)document {
    NSAssert(!document || [document isKindOfClass:[EXTDocument class]], @"This window controller accepts EXTDocument documents only");

    if (document != [self document]) {
        if ([self document])
            [[self chartView] unbind:EXTChartViewSseqBindingName];
        
        [super setDocument:document];

        if (document)
            [[self chartView] bind:EXTChartViewSseqBindingName toObject:document withKeyPath:@"sseq" options:nil];
    }
}

- (EXTDocument *)extDocument {
    return [self document];
}

#pragma mark -

-(NSArray*) dotPositions:(int)count
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

// this performs the culling and delegation calls for drawing a page of the SS
// TODO: does this need spacing to be passed in?  probably a lot of data passing
// needs to be investigated and untangled... :(
- (void)drawPageNumber:(NSUInteger)pageNumber
                    ll:(NSPoint)lowerLeft
                    ur:(NSPoint)upperRight
           withSpacing:(CGFloat)spacing
{
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
    for (EXTTerm *term in self.extDocument.sseq.terms.allValues) {
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
    [[NSColor blackColor] set];
    for (int i = (int)lowerLeft.x; i <= upperRight.x; i++) {
        NSArray *column = (NSArray*)counts[i - (int)lowerLeft.x];
        for (int j = (int)lowerLeft.y; j <= upperRight.y; j++) {
            NSArray *tuple = column[j - (int)lowerLeft.y];
            int count = [tuple[0] intValue];
            
            if (count == 0)
                continue;
            
            NSArray *dotPositions = [self dotPositions:count
                                                     x:(float)i
                                                     y:(float)j
                                               spacing:spacing];
            
            NSBezierPath* path = [NSBezierPath new];
            
            if (count <= 3) {
                for (int i = 0; i < count; i++)
                    [path appendBezierPathWithOvalInRect:
                                                [dotPositions[i] rectValue]];
                
                [path fill];
            } else {
                NSString *output = [NSString stringWithFormat:@"%d", count];
                NSFont *font = output.length >= 2 ? [NSFont fontWithName:@"Palatino-Roman" size:4.5] : [NSFont fontWithName:@"Palatino-Roman" size:5.0];
                NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
                [paragraphStyle setAlignment:NSCenterTextAlignment];
                NSDictionary *attributes = [NSDictionary dictionaryWithObjects:@[paragraphStyle,font] forKeys:@[NSParagraphStyleAttributeName,NSFontAttributeName]];
                NSRect frame = NSMakeRect((float)i * spacing, ((float)j - 0.1) * spacing, spacing, spacing);
                [output drawInRect:frame withAttributes:attributes];
                            
                [path appendBezierPathWithOvalInRect:[dotPositions[0] rectValue]];
                [path stroke];
            }
        }
    }

    // iterate also through the available differentials
    if (pageNumber >= self.extDocument.sseq.differentials.count)
        return;
    
    [[NSColor blackColor] set];
    for (EXTDifferential *differential in ((NSDictionary*)self.extDocument.sseq.differentials[pageNumber]).allValues) {
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
        
        NSArray *startRects = [self dotPositions:[startPosition[0] intValue]
                                               x:pointStart.x
                                               y:pointStart.y
                                         spacing:spacing],
                *endRects = [self dotPositions:[endPosition[0] intValue]
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

- (void)drawPagesUpTo:(NSUInteger)pageNumber {
    // TODO: what’s this supposed to do?
}

#pragma mark - Key-value observing

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (context == _EXTSelectedPageIndexContext)
        [_pagesPopUpButton selectItemAtIndex:[_chartView selectedPageIndex]];
    else if (context == _EXTScrollViewMagnificationContext) {
        const long roundedMagnification = lround([_chartScrollView magnification] * _EXTMagnificationStepRoundingMultiplier);
        NSUInteger stepIndex = NSNotFound;
        int i;
        for (i = 0; i < _EXTDefaultMagnificationStepsCount; i++) {
            const long stepRoundedMagnification = lround(_EXTDefaultMagnificationSteps[i] * _EXTMagnificationStepRoundingMultiplier);
            if (stepRoundedMagnification > roundedMagnification)
                break;
            if (stepRoundedMagnification == roundedMagnification) {
                stepIndex = i;
                break;
            }
        };
        NSUInteger indexToInsertCustomStep = i;

        // If the magnification corresponds to a default magnification step, the pop up button menu does not show any custom steps.
        // Otherwise, we need to remove the previous step since there can be only one and at an index possibly different from the
        // previous one.
        [self _extRemoveCustomZoomFromPopUpMenu];

        // If it’s not one of the default magnification steps, add a custom step
        if (stepIndex == NSNotFound) {
            NSString *title = [NSString stringWithFormat:@"%ld%%", roundedMagnification];
            NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:title action:NULL keyEquivalent:@""];
            [menuItem setTag:_EXTCustomMagnificationTag];
            [[_zoomPopUpButton menu] insertItem:menuItem atIndex:indexToInsertCustomStep];
            [_zoomPopUpButton selectItemAtIndex:indexToInsertCustomStep];
        }
        else
            [_zoomPopUpButton selectItemAtIndex:stepIndex];

        [[self window] invalidateCursorRectsForView:[_chartScrollView documentView]];
    }
    else
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

#pragma mark - Notifications

- (void)controlsViewFrameDidChange:(NSNotification *)notification {
    [self _extCenterToolbox];
}

- (void)_extCenterToolbox {
    const CGFloat toolboxWidth = [_toolboxMatrix frame].size.width;
    const CGFloat controlsViewWidth = [_controlsView frame].size.width;
    NSPoint toolboxOrigin = [_toolboxMatrix frame].origin;
    toolboxOrigin.x = floor((controlsViewWidth - toolboxWidth) / 2);
    [_toolboxMatrix setFrameOrigin:toolboxOrigin];
}

#pragma mark - Actions

- (IBAction)toggleInspector:(id)sender {
    if (_sidebarAnimating)
        return;

    const NSRect contentFrame = [[[self window] contentView] frame];
    NSRect sidebarFrame = [_sidebarView frame];
    NSSize mainSize = [_mainView frame].size;

    if (_sidebarHidden) {
        sidebarFrame.origin.x = NSMaxX(contentFrame) - sidebarFrame.size.width;
        mainSize.width -= sidebarFrame.size.width;
    }
    else {
        sidebarFrame.origin.x = NSMaxX(contentFrame);
        mainSize.width += sidebarFrame.size.width;
    }

    // TODO: check why the chart view sometimes flashes during the animation. It is apparently
    // related to the overlay scrollers showing up, and sometimes they won’t even automatically
    // disappear afterwards!
    _sidebarAnimating = true;
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
        [[_sidebarView animator] setFrame:sidebarFrame];
        [[_mainView animator] setFrameSize:mainSize];
    } completionHandler:^{
        _sidebarHidden = !_sidebarHidden;
        _sidebarAnimating = false;
    }];

    [[self window] makeFirstResponder:_chartView];
}

- (IBAction)exportArtBoard:(id)sender {
    NSData *artBoardPDFData = [_chartView dataWithPDFInsideRect:[[_chartView artBoard] frame]];

    NSSavePanel *savePanel = [NSSavePanel savePanel];
    [savePanel setNameFieldStringValue:[NSString stringWithFormat:@"page_%lu", [_chartView selectedPageIndex]]];
    [savePanel setAllowedFileTypes:@[@"pdf"]];
    [savePanel setAllowsOtherFileTypes:NO];

    [savePanel beginSheetModalForWindow:[self window] completionHandler:^(NSInteger result) {
        // TODO: error handling
        if (result == NSFileHandlingPanelOKButton)
            [artBoardPDFData writeToURL:[savePanel URL] atomically:YES];
    }];
}

- (IBAction)resetGridToDefaults:(id)sender {
    [[_chartView grid] resetToDefaults];
}

- (IBAction)demoGroups:(id)sender {
    [[self document] runDemo];
    [[self chartView] setSelectedPageIndex:0];
}

#pragma mark - NSUserInterfaceValidations

- (BOOL)validateUserInterfaceItem:(id<NSValidatedUserInterfaceItem>)item {
    if ([item action] == @selector(toggleInspector:) && [(id)item isKindOfClass:[NSMenuItem class]])
        [(NSMenuItem *)item setTitle:_sidebarHidden ? @"Show Inspector" : @"Hide Inspector"];
    else if ([item action] == @selector(toggleFullScreen:) && [(id)item isKindOfClass:[NSMenuItem class]]) {
        bool fullScreen = [[self window] styleMask] & NSFullScreenWindowMask;
        [(NSMenuItem *)item setTitle:fullScreen ? @"Exit Full Screen" : @"Enter Full Screen"];
    }

    return [self respondsToSelector:[item action]];
}

@end
