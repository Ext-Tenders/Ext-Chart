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
#import "EXTChartView.h"
#import "EXTGrid.h"
#import "EXTArtBoard.h"
#import "EXTScrollView.h"
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

    @property(nonatomic, strong) NSView *sidebarView;
    @property(nonatomic, weak) IBOutlet NSView *gridInspectorView;
    @property(nonatomic, weak) IBOutlet NSView *horizontalToolboxView;

    @property(nonatomic, assign) NSUInteger maxPage;
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
    }


    // Sidebar & inspector views
    {
        _inspectorView = [[EXTDocumentInspectorView alloc] initWithFrame:NSZeroRect];

        [_inspectorView addSubview:_horizontalToolboxView withTitle:@"Toolbox" collapsed:false centered:true];

        NSTextView *sampleTextView = [[NSTextView alloc] initWithFrame:(NSRect){.size = {200.0, 50.0}}];
        [sampleTextView setAutoresizingMask:NSViewWidthSizable];
        [_inspectorView addSubview:sampleTextView withTitle:@"Text" collapsed:true centered:true];

        [_inspectorView addSubview:_gridInspectorView withTitle:@"Grid" collapsed:false centered:false];

        sampleTextView = [[NSTextView alloc] initWithFrame:(NSRect){.size = {250.0, 800.0}}];
        [sampleTextView setAutoresizingMask:NSViewWidthSizable];
        [_inspectorView addSubview:sampleTextView withTitle:@"More text" collapsed:true centered:true];

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
