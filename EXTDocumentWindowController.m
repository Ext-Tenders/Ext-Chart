//
//  EXTDocumentWindowController.m
//  Ext Chart
//
//  Created by Bavarious on 31/05/2013.
//  Copyright (c) 2013 Harvard University. All rights reserved.
//

@import QuartzCore;

#import "EXTDocumentWindowController.h"
#import "EXTDocument.h"
#import "EXTChartView.h"
#import "EXTChartViewController.h"
#import "EXTChartViewModel.h"
#import "EXTGrid.h"
#import "EXTArtBoard.h"
#import "EXTScrollView.h"
#import "EXTDocumentInspectorView.h"
#import "EXTChartViewController.h"
#import "EXTGridInspectorViewController.h"
#import "EXTGeneratorInspectorViewController.h"
#import "EXTDifferentialPaneController.h"
#import "EXTDifferential.h"
#import "EXTLeibnizWindowController.h"
#import "EXTZeroRangesInspector.h"
#import "NSUserDefaults+EXTAdditions.h"
#import "EXTToolboxTag.h"
#import "EXTTermInspectorViewController.h"
#import "EXTChartRulerView.h"
#import "EXTMultAnnotationInspectorController.h"
#import "EXTChartClipView.h"


#pragma mark - Private variables

static void *_EXTScrollViewMagnificationContext = &_EXTScrollViewMagnificationContext;
static void *_EXTChartViewControllerSelectedObjectContext = &_EXTChartViewControllerSelectedObjectContext;
static void *_EXTArtBoardFrameContext = &_EXTArtBoardFrameContext;

static CGFloat const _EXTDefaultMagnificationSteps[] = {0.1, 0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 2.0, 4.0, 8.0, 16.0, 32.0};
static size_t const _EXTDefaultMagnificationStepsCount = sizeof(_EXTDefaultMagnificationSteps) / sizeof(_EXTDefaultMagnificationSteps[0]);
static CGFloat const _EXTMagnificationStepRoundingMultiplier = 100.0;

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
    @property(nonatomic, weak) IBOutlet EXTScrollView *chartScrollView;
    @property(nonatomic, weak) IBOutlet NSPopUpButton *zoomPopUpButton;
    @property(nonatomic, strong) IBOutlet NSView *pageControlsView;
    @property(nonatomic, weak) IBOutlet NSToolbarItem *pageControlsToolbarItem;

    @property(nonatomic, strong) IBOutlet NSView *sidebarView;

    @property(nonatomic, weak) IBOutlet NSTextField *highlightLabel;
    @property(nonatomic, weak) IBOutlet NSProgressIndicator *progressIndicator;

    @property(nonatomic, assign) EXTToolboxTag selectedToolTag;
    @property(nonatomic, strong) EXTChartViewController *chartViewController;
@end


@implementation EXTDocumentWindowController {
    EXTGridInspectorViewController *_gridInspectorViewController;
    EXTTermInspectorViewController *_termInspectorViewController;
    EXTGeneratorInspectorViewController *_generatorInspectorViewController;
    EXTDifferentialPaneController *_differentialPaneController;
    EXTLeibnizWindowController *_leibnizWindowController;
    EXTZeroRangesInspector *_zeroRangesInspectorController;
    EXTMultAnnotationInspectorController *_multAnnotationInspectorController;
    NSArray *_inspectorViewDelegates;
    EXTDocumentInspectorView *_inspectorView;
    bool _sidebarHidden;
    bool _sidebarAnimating;
}

#pragma mark - Life cycle

+ (void)initialize {
    if (self == [EXTDocumentWindowController class]) {
        [EXTScrollView setRulerViewClass:[EXTChartRulerView class]];
    }
}

- (instancetype)init {
    return [super initWithWindowNibName:@"EXTDocument"];
}

- (void)windowDidLoad {
    [super windowDidLoad];
    [[self window] setDelegate:self];

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
        [menuItem setTarget:_chartView];
        [menuItem setTag:_EXTZoomToFitTag];
        [zoomMenu addItem:menuItem];
        
        [_zoomPopUpButton setMenu:zoomMenu];
    }

    // Chart view
    {
        self.chartViewController = [[EXTChartViewController alloc] initWithDocument:self.extDocument];
        _chartViewController.view = _chartView;

        [_chartView.artBoard addObserver:self forKeyPath:@"frame" options:0 context:_EXTArtBoardFrameContext];
        [_chartViewController addObserver:self forKeyPath:@"selectedObject" options:NSKeyValueObservingOptionNew context:_EXTChartViewControllerSelectedObjectContext];

        [_chartView bind:@"highlightColor" toObject:self.extDocument withKeyPath:@"highlightColor" options:nil];
        [_chartView bind:@"selectionColor" toObject:self.extDocument withKeyPath:@"selectionColor" options:nil];
        [_chartView bind:@"artBoardGridFrame" toObject:self.extDocument withKeyPath:@"artBoardGridFrame" options:nil];

        [self.chartViewController.chartViewModel.grid bind:@"gridColor" toObject:self.extDocument withKeyPath:@"gridColor" options:nil];
        [self.chartViewController.chartViewModel.grid bind:@"emphasisGridColor" toObject:self.extDocument withKeyPath:@"gridEmphasisColor" options:nil];
        [self.chartViewController.chartViewModel.grid bind:@"axisColor" toObject:self.extDocument withKeyPath:@"axisColor" options:nil];
        [self.chartViewController.chartViewModel.grid bind:@"gridSpacing" toObject:self.extDocument withKeyPath:@"gridSpacing" options:nil];
        [self.chartViewController.chartViewModel.grid bind:@"emphasisSpacing" toObject:self.extDocument withKeyPath:@"gridEmphasisSpacing" options:nil];
    }

    // Chart scroll view
    {
        [_chartScrollView setWantsLayer:YES];

        // Swap clip view
        EXTChartClipView *clipView = [[EXTChartClipView alloc] initWithFrame:_chartScrollView.contentView.frame];
        clipView.postsBoundsChangedNotifications = YES;
        _chartScrollView.contentView = clipView;
        _chartScrollView.documentView = _chartView;

        [_chartScrollView setHasHorizontalRuler:YES];
        [_chartScrollView setHasVerticalRuler:YES];

        EXTChartRulerView *horizontalRulerView = (EXTChartRulerView *)_chartScrollView.horizontalRulerView;
        EXTChartRulerView *verticalRulerView = (EXTChartRulerView *)_chartScrollView.verticalRulerView;

        [horizontalRulerView setReservedThicknessForMarkers:0.0];
        [horizontalRulerView setOriginOffset:-([_chartView bounds].origin.x)];
        [verticalRulerView setOriginOffset:-([_chartView bounds].origin.y)];

        [horizontalRulerView bind:@"unitToPointsConversionFactor" toObject:self.extDocument withKeyPath:@"gridSpacing" options:nil];
        [horizontalRulerView bind:@"emphasisSpacing" toObject:self.extDocument withKeyPath:@"gridEmphasisSpacing" options:nil];
        [verticalRulerView bind:@"unitToPointsConversionFactor" toObject:self.extDocument withKeyPath:@"gridSpacing" options:nil];
        [verticalRulerView bind:@"emphasisSpacing" toObject:self.extDocument withKeyPath:@"gridEmphasisSpacing" options:nil];

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
        [_chartView scrollPoint:visibleRect.origin];

        // FIXME: It looks like some magnification factors make the scroll/chart view a bit blurry when it's layer-backed,
        // and rounding the magnification factor (in this case, up to two decimal numbers) solves this. If this is indeed
        // the case, the scroll view should always constrain its magnification factor, not only here. Maybe this is
        // related to the document view bounds being fractional?
        // FIXME
        _chartScrollView.magnification = lround(_chartScrollView.magnification * _EXTMagnificationStepRoundingMultiplier) / _EXTMagnificationStepRoundingMultiplier;

        NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];

        // FIXME: move this to the view or the view controller
        [nc addObserverForName:NSViewBoundsDidChangeNotification object:clipView queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
            [self.chartView updateVisibleRect];
        }];

        [nc addObserverForName:NSScrollViewWillStartLiveMagnifyNotification object:self.chartScrollView queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
            self.chartView.inLiveMagnify = true;
        }];

        [nc addObserverForName:NSScrollViewDidEndLiveMagnifyNotification object:self.chartScrollView queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
            self.chartView.inLiveMagnify = false;
        }];

        [self.chartView updateVisibleRect];
    }

    // Toolbox
    {
        [self setSelectedToolTag:EXTToolTagGenerator];
        self.pageControlsToolbarItem.view = self.pageControlsView;
    }


    // Sidebar & inspector views
    {
        _inspectorView = [[EXTDocumentInspectorView alloc] initWithFrame:NSZeroRect];

        // set up the subviews
        _generatorInspectorViewController = [EXTGeneratorInspectorViewController new];
        [_inspectorView addSubview:_generatorInspectorViewController.view withTitle:@"Generators" collapsed:true centered:true];
        
        _termInspectorViewController = [EXTTermInspectorViewController new];
        [_chartViewController addObserver:_termInspectorViewController forKeyPath:@"selectedObject" options:NSKeyValueObservingOptionNew context:nil];
        [_inspectorView addSubview:_termInspectorViewController.view withTitle:@"Term" collapsed:true centered:true];
        
        _differentialPaneController = [EXTDifferentialPaneController new];
        [_chartViewController addObserver:_differentialPaneController forKeyPath:@"selectedObject" options:NSKeyValueObservingOptionNew context:nil];
        [_inspectorView addSubview:_differentialPaneController.view withTitle:@"Differential" collapsed:true centered:true];
        
        _zeroRangesInspectorController = [EXTZeroRangesInspector new];
        [_inspectorView addSubview:_zeroRangesInspectorController.view withTitle:@"Zero Ranges" collapsed:true centered:true];
        
        _multAnnotationInspectorController = [EXTMultAnnotationInspectorController new];
        [_inspectorView addSubview:_multAnnotationInspectorController.view withTitle:@"Multiplication Annotations" collapsed:true centered:true];

        _gridInspectorViewController = [EXTGridInspectorViewController new];
        [_inspectorView addSubview:_gridInspectorViewController.view withTitle:@"Grid" collapsed:true centered:false];

        _inspectorViewDelegates = @[
                                    @{@"view" : _generatorInspectorViewController.view, @"delegate" : _generatorInspectorViewController},
                                    @{@"view" : _termInspectorViewController.view, @"delegate" : _termInspectorViewController},
                                    @{@"view" : _differentialPaneController.view, @"delegate" : _differentialPaneController},
                                    @{@"view" : _zeroRangesInspectorController.view, @"delegate" : _zeroRangesInspectorController },
                                    @{@"view" : _gridInspectorViewController.view, @"delegate" : _gridInspectorViewController},
                                    @{@"view" : _multAnnotationInspectorController.view, @"delegate" : _multAnnotationInspectorController},
                                    ];

        const NSRect contentFrame = [[[self window] contentView] frame];

        NSSize scrollViewSize = [NSScrollView contentSizeForFrameSize:_inspectorView.frame.size
                                              horizontalScrollerClass:nil
                                                verticalScrollerClass:NSScroller.class
                                                           borderType:NSNoBorder
                                                          controlSize:NSRegularControlSize
                                                        scrollerStyle:NSScrollerStyleOverlay];
        scrollViewSize.height = contentFrame.size.height;
        NSScrollView *inspectorScrollView = [[NSScrollView alloc] initWithFrame:(NSRect){NSZeroPoint, scrollViewSize}];
        [inspectorScrollView setHasHorizontalScroller:NO];
        [inspectorScrollView setHasVerticalScroller:YES];
        [inspectorScrollView setAutohidesScrollers:YES];
        [inspectorScrollView setBorderType:NSNoBorder];
        [inspectorScrollView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
        [inspectorScrollView setDrawsBackground:YES];
        [inspectorScrollView setBackgroundColor:[EXTDocumentInspectorView backgroundColor]];
        [inspectorScrollView setDocumentView:_inspectorView];

        NSRect mainFrame = [_mainView frame];
        mainFrame.size.width = contentFrame.size.width - scrollViewSize.width;
        [_mainView setFrameSize:mainFrame.size];

        NSRect sidebarFrame = {{NSMaxX(mainFrame), 0.0}, scrollViewSize};
        [_sidebarView setFrame:sidebarFrame];
        [_sidebarView setWantsLayer:YES];
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

        // Now that the sidebar is set up, notify delegates
        for (NSDictionary *viewDelegatePair in _inspectorViewDelegates) {
            id<EXTDocumentInspectorViewDelegate> delegate = viewDelegatePair[@"delegate"];
            if (delegate && [delegate respondsToSelector:@selector(documentWindowController:didAddInspectorView:)])
                [delegate documentWindowController:self didAddInspectorView:viewDelegatePair[@"view"]];
        }
    }
    
    {
        // set up tool handlers
        _leibnizWindowController = [[EXTLeibnizWindowController alloc] initWithWindowNibName:@"EXTLeibnizWindow"];
        _chartViewController.leibnizWindowController = _leibnizWindowController;
        _leibnizWindowController.documentWindowController = self;
    }

    [[self window] makeFirstResponder:_chartView];
}

- (void)windowWillClose:(NSNotification *)notification {
    // TODO: should these observer adds and removes be put into the EXTDIVD calls?
    [_chartScrollView removeObserver:self forKeyPath:@"magnification"];
    [_chartView.artBoard removeObserver:self forKeyPath:@"frame" context:_EXTArtBoardFrameContext];
    [_chartViewController removeObserver:_termInspectorViewController forKeyPath:@"selectedObject"];
    [_chartViewController removeObserver:_differentialPaneController forKeyPath:@"selectedObject"];
    [_chartViewController removeObserver:self forKeyPath:@"selectedObject"];

    [_chartView unbind:@"highlightColor"];
    [_chartView unbind:@"selectionColor"];
    [_chartView unbind:@"artBoardGridFrame"];

    [_chartViewController.chartViewModel.grid unbind:@"gridColor"];
    [_chartViewController.chartViewModel.grid unbind:@"emphasisGridColor"];
    [_chartViewController.chartViewModel.grid unbind:@"axisColor"];
    [_chartViewController.chartViewModel.grid unbind:@"gridSpacing"];
    [_chartViewController.chartViewModel.grid unbind:@"emphasisSpacing"];

    [_chartScrollView.horizontalRulerView unbind:@"unitToPointsConversionFactor"];
    [_chartScrollView.horizontalRulerView unbind:@"emphasisSpacing"];
    [_chartScrollView.verticalRulerView unbind:@"unitToPointsConversionFactor"];
    [_chartScrollView.verticalRulerView unbind:@"emphasisSpacing"];

    for (NSDictionary *viewDelegatePair in _inspectorViewDelegates) {
        id<EXTDocumentInspectorViewDelegate> delegate = viewDelegatePair[@"delegate"];
        if (delegate && [delegate respondsToSelector:@selector(documentWindowController:willRemoveInspectorView:)])
            [delegate documentWindowController:self willRemoveInspectorView:viewDelegatePair[@"view"]];
    }

    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc removeObserver:self name:NSViewBoundsDidChangeNotification object:[_chartScrollView contentView]];
    [nc removeObserver:self name:NSScrollViewWillStartLiveMagnifyNotification object:self.chartScrollView];
    [nc removeObserver:self name:NSScrollViewDidEndLiveMagnifyNotification object:self.chartScrollView];
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

#pragma mark - Properties

- (EXTDocument *)extDocument {
    return [self document];
}

- (void)setSelectedToolTag:(EXTToolboxTag)selectedToolTag
{
    _selectedToolTag = selectedToolTag;

    NSDictionary *tagToId = @{@(EXTToolTagGenerator): @"GeneratorTool",
                              @(EXTToolTagDifferential): @"DifferentialTool",
                              @(EXTToolTagMultiplicativeStructure): @"MultiplicativeStructureTool",
                              @(EXTToolTagArtboard): @"ArtBoardTool",
                              @(EXTToolTagMarquee): @"MarqueeTool",
                              };
    NSString *identifier = tagToId[@(selectedToolTag)];
    NSAssert(identifier, @"Toolbar item tag should always match a toolbar item identifier");

    [self.window.toolbar setSelectedItemIdentifier:identifier];
}

#pragma mark - Key-value observing

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (context == _EXTScrollViewMagnificationContext) {
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
    else if (context == _EXTArtBoardFrameContext) {
        self.extDocument.artBoardGridFrame = [_chartView.grid convertRectFromView:_chartView.artBoard.frame];
    }
    else if (context == _EXTChartViewControllerSelectedObjectContext) {
        NSObject *newValue = change[NSKeyValueChangeNewKey];
        if ([newValue isKindOfClass:[EXTDifferential class]]) {
            EXTDifferential *diff = (EXTDifferential*)newValue;
            self.highlightLabel.stringValue = [NSString stringWithFormat:@"Differential: %@ → %@", [self.extDocument.sseq.locConvertor convertToString:diff.start.location], [self.extDocument.sseq.locConvertor convertToString:diff.end.location]];
        } else if ([newValue isKindOfClass:[EXTTerm class]]) {
            EXTTerm *term = (EXTTerm*)newValue;
            self.highlightLabel.stringValue = [NSString stringWithFormat:@"Term: %@", [self.extDocument.sseq.locConvertor convertToString:term.location]];
        } else {
            self.highlightLabel.stringValue = @"No selection.";
        }
    }
    else
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
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

    _sidebarAnimating = true;
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
        [_sidebarView.animator setFrame:sidebarFrame];
        [_mainView.animator setFrameSize:mainSize];
    } completionHandler:^{
        _sidebarHidden = !_sidebarHidden;
        _sidebarAnimating = false;

        [[self window] makeFirstResponder:_chartView];
        [[self window] invalidateCursorRectsForView:_sidebarView];
    }];
}

- (IBAction)nextPage:(id)sender {
    self.chartViewController.currentPage++;
}

- (IBAction)previousPage:(id)sender {
    if (self.chartViewController.currentPage > 0)
        self.chartViewController.currentPage--;
}

- (IBAction)exportArtBoard:(id)sender {
    NSSavePanel *savePanel = [NSSavePanel savePanel];
    [savePanel setNameFieldStringValue:[NSString stringWithFormat:@"page_%d", [_chartViewController currentPage]]];
    [savePanel setAllowedFileTypes:@[@"pdf"]];
    [savePanel setAllowsOtherFileTypes:NO];

    [savePanel beginSheetModalForWindow:[self window] completionHandler:^(NSInteger result) {
        // TODO: error handling
        if (result == NSFileHandlingPanelOKButton)
            [self exportArtBoardToURL:[savePanel URL]];
    }];
}

- (void)exportArtBoardToURL:(NSURL *)URL
{
    const CGRect frame = self.chartView.artBoard.frame;

    EXTChartView *exportChartView = [[EXTChartView alloc] initWithFrame:(NSRect){NSZeroPoint, self.chartView.frame.size}];
    exportChartView.vectorChart = true;
    exportChartView.dataSource = self.chartViewController;
    exportChartView.delegate = self.chartViewController;
    exportChartView.grid.gridSpacing = self.chartViewController.chartViewModel.grid.gridSpacing;
    exportChartView.grid.emphasisSpacing = self.chartViewController.chartViewModel.grid.emphasisSpacing;
    [exportChartView bind:@"artBoardGridFrame" toObject:self.extDocument withKeyPath:@"artBoardGridFrame" options:nil];

    [exportChartView reloadCurrentPage];
    [exportChartView updateRect:frame];

    CGContextRef PDFContext = CGPDFContextCreateWithURL((__bridge CFURLRef)URL, &frame, NULL);

    CGLayerRef layer = CGLayerCreateWithContext(PDFContext, frame.size, NULL);
    CGContextRef layerContext = CGLayerGetContext(layer);

    // Funny thing: -[CALayer renderInContext:] does not respect CALayer.zPosition. Instead, it simply follows
    // the order in CALayer.sublayers.

    NSGraphicsContext *drawingContext = [NSGraphicsContext graphicsContextWithGraphicsPort:layerContext flipped:NO];
    [NSGraphicsContext saveGraphicsState];
    [NSGraphicsContext setCurrentContext:drawingContext];
    CGContextBeginPage(PDFContext, &frame);
    {
        [exportChartView.layer renderInContext:PDFContext];
    }
    CGContextEndPage(PDFContext);
    CGPDFContextClose(PDFContext);
    CGContextRelease(PDFContext);
    CGLayerRelease(layer);
    [NSGraphicsContext restoreGraphicsState];

    [exportChartView unbind:@"artBoardGridFrame"];
}

- (IBAction)resetGridToDefaults:(id)sender {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    EXTDocument *doc = self.extDocument;

	doc.gridSpacing = [defaults integerForKey:EXTGridSpacingPreferenceKey];
	doc.gridEmphasisSpacing = [defaults integerForKey:EXTGridEmphasisSpacingPreferenceKey];

	doc.gridColor = [defaults extColorForKey:EXTGridColorPreferenceKey];
	doc.gridEmphasisColor = [defaults extColorForKey:EXTGridEmphasisColorPreferenceKey];
	doc.axisColor = [defaults extColorForKey:EXTGridAxisColorPreferenceKey];
}

- (IBAction)startLeibnizPropagation:(id)sender {
    [_leibnizWindowController showWindow:sender];
    return;
}


- (IBAction)changeTool:(id)sender {
    NSAssert([sender respondsToSelector:@selector(tag)], @"This action requires senders that respond to -tag");

    EXTToolboxTag tag = [sender tag];
    if (tag <= 0 || tag >= EXTToolTagLastSentinel)
        return;

    self.selectedToolTag = tag;
}

#pragma mark - NSUserInterfaceValidations

- (BOOL)validateUserInterfaceItem:(id<NSValidatedUserInterfaceItem>)item {
    if ([item action] == @selector(toggleInspector:) && [(id)item isKindOfClass:[NSMenuItem class]])
        [(NSMenuItem *)item setTitle:_sidebarHidden ? @"Show Inspector" : @"Hide Inspector"];
    else if ([item action] == @selector(toggleFullScreen:) && [(id)item isKindOfClass:[NSMenuItem class]]) {
        bool fullScreen = [[self window] styleMask] & NSFullScreenWindowMask;
        [(NSMenuItem *)item setTitle:fullScreen ? @"Exit Full Screen" : @"Enter Full Screen"];
    }
    else if ([item action] == @selector(changeTool:)) {
        if ([(id)item respondsToSelector:@selector(setState:)]) {
            [(id)item setState:([item tag] == self.selectedToolTag ? NSOnState : NSOffState)];
        }
    }

    return [self respondsToSelector:[item action]];
}

#pragma mark - NSToolbarItemValidation

- (BOOL)validateToolbarItem:(NSToolbarItem *)item
{
    return ![item.itemIdentifier isEqualToString:@"MarqueeTool"];
}

@end
