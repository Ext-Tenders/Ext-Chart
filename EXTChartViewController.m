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
@property (nonatomic, strong) EXTChartViewModel *chartViewModel;
@end


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
    self.chartView.interactionType = [EXTChartViewController interactionTypeFromToolTag:_document.mainWindowController.selectedToolTag];
    self.chartViewModel.grid = self.chartView.grid;

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

#pragma mark - Properties

- (EXTChartView *)chartView {
    return (EXTChartView *)[self view];
}

- (void)setCurrentPage:(int)currentPage {
    if (currentPage == _currentPage || currentPage < 0)
        
        return;

    _currentPage = currentPage;

    self.selectedObject = nil;
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
    
    // TODO: lots!
    switch (self.chartView.interactionType) {
        case EXTChartViewInteractionTypeTerm: {
            NSArray *terms = [_document.sseq findTermsUnderPoint:gridLocation];
            NSUInteger oldIndex = NSNotFound;
            
            // if there's nothing under this click, just quit now.
            if (terms.count == 0) {
                self.selectedObject = nil;
                [self.chartView removeTermSelection];
                return;
            }
            
            // if we used to have something selected, and it was a term at this
            // location, then we should find its position in our list.
            if ([self.selectedObject isKindOfClass:[EXTTerm class]])
                oldIndex = [terms indexOfObject:(EXTTerm*)self.selectedObject];
            
            // the new index is one past the old index, unless we have to wrap.
            int newIndex = oldIndex;
            EXTTerm *term = nil;
            if (oldIndex == NSNotFound) {
                oldIndex = 0;
                newIndex = 0;
            }
            do {
                if (newIndex == (terms.count - 1))
                    newIndex = 0;
                else
                    newIndex = newIndex + 1;
                term = terms[newIndex];
                
                // if we've found it, good!  quit!
                if (term) {
                    self.selectedObject = term;
                    [self.chartView selectTermAtGridLocation:gridLocation index:newIndex];
                    break;
                }
            } while (newIndex != oldIndex);
            
            break;
        }
            
        case EXTChartViewInteractionTypeDifferential: {
            NSArray *terms = [_document.sseq findTermsUnderPoint:gridLocation];
            NSUInteger oldIndex = NSNotFound;

            // if there's nothing under this click, just quit now.
            if (terms.count == 0) {
                self.selectedObject = nil;
                [self.chartView removeDifferentialSelection];
                return;
            }
            
            // if we used to have something selected, and it was a differential
            // on this page, then we should find its position in our list.
            if ([self.selectedObject isKindOfClass:[EXTDifferential class]] &&
                (((EXTDifferential*)self.selectedObject).page == _currentPage))
                oldIndex = [terms indexOfObject:((EXTDifferential*)self.selectedObject).start];
            
            // the new index is one past the old index, unless we have to wrap.
            int newIndex = oldIndex;
            EXTTerm *source = nil/*, *end = nil*/;
            EXTDifferential *diff = nil;
            if (oldIndex == NSNotFound) {
                oldIndex = 0;
                newIndex = 0;
            }
            do {
                if (newIndex == (terms.count - 1))
                    newIndex = 0;
                else
                    newIndex = newIndex + 1;
                source = terms[newIndex];
                diff = [_document.sseq findDifflWithSource:source.location onPage:_currentPage];
                
                // if we've found it, good!  quit!
                if (diff) {
                    self.selectedObject = diff;
                    // FIXME: Need to find a decent way to bind model differentials with chart view differentials.
                    //        Maybe the view model should do this.
                    [self.chartView selectDifferentialAtStartLocation:gridLocation index:newIndex];
                    break;
                }

                // FIXME: Ask Eric whether this still makes sense. If it does, we'll need to refresh the view model
                //        and the chart view, it seems.
//                // if there's no differential, then let's try to build it.
//                EXTLocation *endLoc = [[source.location class] followDiffl:source.location page:_currentPage];
//                end = [_document.sseq findTerm:endLoc];
//                
//                if (end) {
//                    // but if there is, let's build it and set it up.
//                    diff = [EXTDifferential newDifferential:source end:end page:_currentPage];
//                    [_document.sseq addDifferential:diff];
//                    self.selectedObject = diff;
//                    break;
//                }

                // if there's no target term, then this won't work, and we
                // should cycle.
            } while (newIndex != oldIndex);
            
            break;
        }

//        case EXTToolTagMarquee: {
//            const NSRect gridRectInView = [self.chartView.grid viewBoundingRectForGridPoint:gridLocation];
//            NSIndexSet *marqueesAtPoint = [_document.marquees indexesOfObjectsPassingTest:^BOOL(EXTMarquee *marquee, NSUInteger idx, BOOL *stop) {
//                return NSIntersectsRect(gridRectInView, marquee.frame);
//            }];
//
//            EXTMarquee *newSelectedMarquee = nil;
//
//            if (marqueesAtPoint.count == 0) {
//                newSelectedMarquee = [EXTMarquee new];
//                newSelectedMarquee.string = @"New marquee";
//                newSelectedMarquee.frame = (NSRect){gridRectInView.origin, {100.0, 15.0}};
//                [_document.marquees addObject:newSelectedMarquee];
//            }
//            else {
//                // Cycle through all marquees lying on that grid square
//                const NSInteger previousSelectedMarqueeIndex = ([self.selectedObject isKindOfClass:[EXTMarquee class]] ?
//                                                                [_document.marquees indexOfObject:self.selectedObject] :
//                                                                -1);
//                NSInteger newSelectedMarqueeIndex = [marqueesAtPoint indexGreaterThanIndex:previousSelectedMarqueeIndex];
//                if (newSelectedMarqueeIndex == NSNotFound)
//                    newSelectedMarqueeIndex = [marqueesAtPoint firstIndex];
//
//                newSelectedMarquee = _document.marquees[newSelectedMarqueeIndex];
//            }
//
//            self.selectedObject = newSelectedMarquee;
//
//            break;
//        }

        default:
            break;
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
        self.selectedObject = nil;
        [self.chartView.window invalidateCursorRectsForView:self.chartView];

        self.chartView.interactionType = [EXTChartViewController interactionTypeFromToolTag:newTag];
    }
    else [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
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

+ (EXTChartViewInteractionType)interactionTypeFromToolTag:(EXTToolboxTag)tag
{
    EXTChartViewInteractionType type;
    switch (tag) {
        case EXTToolTagArtboard: type = EXTChartViewInteractionTypeArtBoard; break;
        case EXTToolTagGenerator: type = EXTChartViewInteractionTypeTerm; break;
        case EXTToolTagDifferential: type = EXTChartViewInteractionTypeDifferential; break;
        case EXTToolTagMultiplicativeStructure: type = EXTChartViewInteractionTypeMultiplicativeStructure; break;
        case EXTToolTagMarquee:
        case EXTToolTagLastSentinel:
        default:
            type = EXTChartViewInteractionTypeNone;
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
