///
//  EXTChartViewController.m
//  Ext Chart
//
//  Created by Bavarious on 10/08/2013.
//  Copyright (c) 2013 Harvard University. All rights reserved.
//

#import "EXTChartViewController.h"
#import "EXTChartView.h"
#import "EXTChartViewModel.h"
#import "EXTDocumentWindowController.h"
#import "EXTGrid.h"
#import "EXTMarquee.h"
#import "EXTDocument.h"
#import "EXTSpectralSequence.h"
#import "EXTTerm.h"
#import "EXTDifferential.h"


@interface EXTChartViewController () <EXTChartViewDataSource, EXTChartViewDelegate>
@property (nonatomic, weak) id selectedObject;
@property (nonatomic, strong) EXTChartViewModel *chartViewModel;
@end

#pragma mark - Private variables

static void *_selectedObjectContext = &_selectedObjectContext;

#pragma mark - Private functions

static bool lineSegmentOverRect(NSPoint p1, NSPoint p2, NSRect rect);
static bool lineSegmentIntersectsLineSegment(NSPoint l1p1, NSPoint l1p2, NSPoint l2p1, NSPoint l2p2);


@implementation EXTChartViewController
{
    EXTDocument *_document;
}

static void *_selectedToolTagContext = &_selectedToolTagContext;

#pragma mark - Life cycle

- (instancetype)initWithDocument:(EXTDocument *)document {
    self = [super init];
    if (self) {
        NSAssert(document, @"We need a document");
        NSAssert(document.mainWindowController,
            @"The document should have a main window controller at this point");

        _document = document;
        [document.mainWindowController addObserver:self
                                        forKeyPath:@"selectedToolTag"
                                           options:NSKeyValueObservingOptionNew
                                           context:_selectedToolTagContext];
        
        [[NSNotificationCenter defaultCenter]
                             addObserver:self
                                selector:@selector(mainDocumentWindowWillClose:)
                                    name:NSWindowWillCloseNotification
                                  object:document.mainWindowController.window];

        _chartViewModel = [EXTChartViewModel new];
        _chartViewModel.sequence = document.sseq;

        [_chartViewModel addObserver:self forKeyPath:@"selectedObject" options:0 context:_selectedObjectContext];
    }
    return self;
}

- (void)mainDocumentWindowWillClose:(NSNotification *)notification
{
    [[NSNotificationCenter defaultCenter]
                        removeObserver:self
                                  name:NSWindowWillCloseNotification
                                object:_document.mainWindowController.window];
    
    [_document.mainWindowController removeObserver:self
                                        forKeyPath:@"selectedToolTag"];

    [self.chartViewModel removeObserver:self forKeyPath:@"selectedObject" context:_selectedObjectContext];

    self.chartViewModel = nil;
    _document = nil;
}

- (void)setView:(NSView *)view {
    NSAssert([view isKindOfClass:[EXTChartView class]],
             @"EXTChartViewController controls EXTChartViews only");
    NSAssert(_document, @"EXTChartViewController needs a document");

    [super setView:view];

    self.chartView.delegate = self;
    self.chartView.dataSource = self;
    self.chartViewModel.interactionType = [EXTChartViewController interactionTypeFromToolTag:_document.mainWindowController.selectedToolTag];
    self.chartViewModel.grid = self.chartView.grid;

    [self.chartView bind:@"interactionType" toObject:self.chartViewModel withKeyPath:@"interactionType" options:nil];
    [self.chartView bind:@"selectedObject" toObject:self.chartViewModel withKeyPath:@"selectedObject" options:nil];

    [self reloadCurrentPage];
}

+ (instancetype)new {
    return [super new];
}

- (instancetype)init {
    return [super init];
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil
                         bundle:(NSBundle *)nibBundleOrNil {
    return [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
}

- (void)dealloc
{
    [self.chartView unbind:@"interactionType"];
    [self.chartView unbind:@"selectedObject"];
}

#pragma mark - Properties

- (EXTChartView *)chartView {
    return (EXTChartView *)[self view];
}

- (void)setCurrentPage:(int)currentPage {
    if (currentPage == _currentPage || currentPage < 0)
        
        return;

    _currentPage = currentPage;

    self.chartViewModel.selectedObject = nil;
    self.chartViewModel.currentPage = currentPage;
    [self reloadCurrentPage]; // FIXME: We should only reload if the model has been changed. Otherwise, we should just redisplay the page.
}

#pragma mark -

- (void)reloadCurrentPage {
    [self.chartViewModel reloadCurrentPage];
    [self.chartView setNeedsDisplay:YES];
    [self.chartView reloadCurrentPage];
}

#pragma mark - EXTChartViewDelegate

- (void)chartView:(EXTChartView *)chartView mouseDownAtGridLocation:(EXTIntPoint)gridLocation {
    // first, see if a modal tool is open.
    if ([self.leibnizWindowController.window isVisible]) {
        [self.leibnizWindowController mouseDownAtGridLocation:gridLocation];
        return;
    }

    [self.chartViewModel selectObjectAtGridLocation:gridLocation];

    // If we couldn’t select a differential, try to build one
    if (!self.selectedObject && self.chartViewModel.interactionType == EXTChartInteractionTypeDifferential) {
        EXTChartViewModelTermCell *termCell = [self.chartViewModel termCellAtGridLocation:gridLocation];
        for (EXTChartViewModelTerm *term in termCell.terms) {
            if (term.differentials.count > 0) continue;

            EXTLocation *sourceLoc = term.modelTerm.location;
            EXTLocation *endLoc = [[sourceLoc class] followDiffl:sourceLoc page:self.currentPage];
            EXTTerm *modelEndTerm = [_document.sseq findTerm:endLoc];
            if (!modelEndTerm) continue;

            EXTDifferential *newModelDiff = [EXTDifferential newDifferential:term.modelTerm end:modelEndTerm page:self.currentPage];
            [_document.sseq addDifferential:newModelDiff];
            self.selectedObject = newModelDiff;
            break;
        }
    }
}

#pragma mark - EXTChartViewDataSource

- (NSArray *)chartView:(EXTChartView *)chartView termCellsInGridRect:(EXTIntRect)gridRect
{
    NSMutableArray *result = [NSMutableArray new];
    for (EXTChartViewModelTermCell *termCell in self.chartViewModel.termCells) {
        if (EXTIntPointInRect(termCell.gridLocation, gridRect)) {
            [result addObject:termCell];
        }
    }
    return [result copy];
}

- (NSArray *)chartView:(EXTChartView *)chartView differentialsInGridRect:(EXTIntRect)gridRect
{
    const NSRect rect = [self.chartView.grid convertRectToView:gridRect];

    NSMutableArray *result = [NSMutableArray array];
    for (EXTChartViewModelDifferential *diff in self.chartViewModel.differentials) {
        const NSPoint start = [self.chartView.grid convertPointToView:diff.startTerm.gridLocation];
        const NSPoint end = [self.chartView.grid convertPointToView:diff.endTerm.gridLocation];
        if (lineSegmentOverRect(start, end, rect)) {
            [result addObject:diff];
        }
    }
    return [result copy];
}

#pragma mark - NSKeyValueObserving

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == _selectedToolTagContext) {
        EXTToolboxTag newTag = [change[NSKeyValueChangeNewKey] integerValue];
        self.chartViewModel.selectedObject = nil;
        [self.chartView.window invalidateCursorRectsForView:self.chartView];

        self.chartViewModel.interactionType = [EXTChartViewController interactionTypeFromToolTag:newTag];
    }
    else if (context == _selectedObjectContext) {
        if ([self.chartViewModel.selectedObject isKindOfClass:[EXTChartViewModelTerm class]]) {
            self.selectedObject = ((EXTChartViewModelTerm *)self.chartViewModel.selectedObject).modelTerm;
        }
        else if ([self.chartViewModel.selectedObject isKindOfClass:[EXTChartViewModelDifferential class]]) {
            self.selectedObject = ((EXTChartViewModelDifferential *)self.chartViewModel.selectedObject).modelDifferential;
        }
        else {
            self.selectedObject = nil;
        }
    }
    else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark - Key-Value Coding

- (void)setNilValueForKey:(NSString *)key {
    if ([key isEqualToString:@"currentPage"]) {
        self.currentPage = 0;
    }
    else
        [super setNilValueForKey:key];
}

#pragma mark - Support

+ (EXTChartInteractionType)interactionTypeFromToolTag:(EXTToolboxTag)tag
{
    EXTChartInteractionType type;
    switch (tag) {
        case EXTToolTagArtboard:
            type = EXTChartInteractionTypeArtBoard;
            break;

        case EXTToolTagGenerator:
            type = EXTChartInteractionTypeTerm;
            break;

        case EXTToolTagDifferential:
            type = EXTChartInteractionTypeDifferential;
            break;

        case EXTToolTagMultiplicativeStructure:
            type = EXTChartInteractionTypeMultiplicativeStructure; break;

        case EXTToolTagMarquee:
        case EXTToolTagLastSentinel:
        default:
            type = EXTChartInteractionTypeNone;
    }
    
    return type;
}

@end

#pragma mark - Util

static bool lineSegmentOverRect(NSPoint p1, NSPoint p2, NSRect rect)
{
#define LEFT (NSPoint){(rect.origin.x), (rect.origin.y)}, (NSPoint){(rect.origin.x), (rect.origin.y + rect.size.height)}
#define RIGHT (NSPoint){(rect.origin.x + rect.size.width), (rect.origin.y)}, (NSPoint){(rect.origin.x + rect.size.width), (rect.origin.y + rect.size.height)}
#define TOP (NSPoint){(rect.origin.x), (rect.origin.y + rect.size.height)}, (NSPoint){(rect.origin.x + rect.size.width), (rect.origin.y + rect.size.height)}
#define BOTTOM (NSPoint){(rect.origin.x), (rect.origin.y)}, (NSPoint){(rect.origin.x + rect.size.width), (rect.origin.y)}
    return (lineSegmentIntersectsLineSegment(p1, p2, LEFT) ||
            lineSegmentIntersectsLineSegment(p1, p2, RIGHT) ||
            lineSegmentIntersectsLineSegment(p1, p2, TOP) ||
            lineSegmentIntersectsLineSegment(p1, p2, BOTTOM) ||
            NSPointInRect(p1, rect) ||
            NSPointInRect(p2, rect));
#undef LEFT
#undef RIGHT
#undef TOP
#undef BOTTOM
}

static bool lineSegmentIntersectsLineSegment(NSPoint l1p1, NSPoint l1p2, NSPoint l2p1, NSPoint l2p2)
{
    CGFloat q = (l1p1.y - l2p1.y) * (l2p2.x - l2p1.x) - (l1p1.x - l2p1.x) * (l2p2.y - l2p1.y);
    CGFloat d = (l1p2.x - l1p1.x) * (l2p2.y - l2p1.y) - (l1p2.y - l1p1.y) * (l2p2.x - l2p1.x);

    if (d == 0.0) return false;

    CGFloat r = q / d;

    q = (l1p1.y - l2p1.y) * (l1p2.x - l1p1.x) - (l1p1.x - l2p1.x) * (l1p2.y - l1p1.y);
    CGFloat s = q / d;

    return !(r < 0 || r > 1 || s < 0 || s > 1);
}
