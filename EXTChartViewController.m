//
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


@interface EXTChartViewController () <EXTChartViewDelegate>
@property (nonatomic, strong) EXTChartViewModel *chartViewModel;
@end


@implementation EXTChartViewController {
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
        [_chartViewModel bind:@"selectedObject"
                     toObject:self withKeyPath:@"selectedObject"
                      options:nil];
        [_chartViewModel bind:@"selectedToolTag"
                     toObject:document.mainWindowController
                  withKeyPath:@"selectedToolTag"
                      options:nil];
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

    [_chartViewModel unbind:@"selectedObject"];
    [_chartViewModel unbind:@"selectedToolTag"];

    self.chartViewModel = nil;
    _document = nil;
}

- (void)setView:(NSView *)view {
    NSAssert([view isKindOfClass:[EXTChartView class]],
             @"EXTChartViewController controls EXTChartViews only");
    NSAssert(_document, @"EXTChartViewController needs a document");

    [super setView:view];

    self.chartView.delegate = self;
    self.chartView.dataSource = self.chartViewModel;
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

- (void)setSelectedObject:(id)selectedObject {
    if (selectedObject == _selectedObject)
        return;

    [self.chartView setNeedsDisplayInRect:[self _extBoundingRectForObject:_selectedObject]]; // clear the previous selection
    _selectedObject = selectedObject;
    [self.chartView setNeedsDisplayInRect:[self _extBoundingRectForObject:selectedObject]]; // draw the new selection
    
    return;
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
    [self.chartView resetHighlightPath];
    [self.chartView setNeedsDisplay:YES];
}

#pragma mark - EXTChartViewDelegate

- (void)chartView:(EXTChartView *)chartView mouseDownAtGridLocation:(EXTIntPoint)gridLocation {
    // first, see if a modal tool is open.
    if ([self.leibnizWindowController.window isVisible]) {
        [self.leibnizWindowController mouseDownAtGridLocation:gridLocation];
        return;
    }
    
    // TODO: lots!
    switch (self.chartViewModel.selectedToolTag) {
        case EXTToolTagDifferential: {
            NSArray *terms = [_document.sseq findTermsUnderPoint:gridLocation];
            NSUInteger oldIndex = NSNotFound;

            // if there's nothing under this click, just quit now.
            if (terms.count == 0) {
                self.selectedObject = nil;
                return;
            }
            
            // if we used to have something selected, and it was a differential
            // on this page, then we should find its position in our list.
            if ([self.selectedObject isKindOfClass:[EXTDifferential class]] &&
                (((EXTDifferential*)self.selectedObject).page == _currentPage))
                oldIndex = [terms indexOfObject:((EXTDifferential*)self.selectedObject).start];
            
            // the new index is one past the old index, unless we have to wrap.
            int newIndex = oldIndex;
            EXTTerm *source = nil, *end = nil;
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
                    break;
                }
                
                // if there's no differential, then let's try to build it.
                EXTLocation *endLoc = [[source.location class] followDiffl:source.location page:_currentPage];
                end = [_document.sseq findTerm:endLoc];
                
                if (end) {
                    // but if there is, let's build it and set it up.
                    diff = [EXTDifferential newDifferential:source end:end page:_currentPage];
                    [_document.sseq addDifferential:diff];
                    self.selectedObject = diff;
                    break;
                }
                
                // if there's no target term, then this won't work, and we
                // should cycle.
            } while (newIndex != oldIndex);
            
            break;
        }

        case EXTToolTagMarquee: {
            const NSRect gridRectInView = [self.chartView.grid viewBoundingRectForGridPoint:gridLocation];
            NSIndexSet *marqueesAtPoint = [_document.marquees indexesOfObjectsPassingTest:^BOOL(EXTMarquee *marquee, NSUInteger idx, BOOL *stop) {
                return NSIntersectsRect(gridRectInView, marquee.frame);
            }];

            EXTMarquee *newSelectedMarquee = nil;

            if (marqueesAtPoint.count == 0) {
                newSelectedMarquee = [EXTMarquee new];
                newSelectedMarquee.string = @"New marquee";
                newSelectedMarquee.frame = (NSRect){gridRectInView.origin, {100.0, 15.0}};
                [_document.marquees addObject:newSelectedMarquee];
            }
            else {
                // Cycle through all marquees lying on that grid square
                const NSInteger previousSelectedMarqueeIndex = ([self.selectedObject isKindOfClass:[EXTMarquee class]] ?
                                                                [_document.marquees indexOfObject:self.selectedObject] :
                                                                -1);
                NSInteger newSelectedMarqueeIndex = [marqueesAtPoint indexGreaterThanIndex:previousSelectedMarqueeIndex];
                if (newSelectedMarqueeIndex == NSNotFound)
                    newSelectedMarqueeIndex = [marqueesAtPoint firstIndex];

                newSelectedMarquee = _document.marquees[newSelectedMarqueeIndex];
            }

            self.selectedObject = newSelectedMarquee;

            break;
        }

        default:
            break;
    }
}

#pragma mark - Drawing support

/* Returns the bounding rect of a given object in user coordinate space */
- (NSRect)_extBoundingRectForObject:(id)object {
    if ([object isKindOfClass:[EXTTerm class]]) {
        return [self _extBoundingRectForTerm:object];
    }
    else if ([object isKindOfClass:[EXTDifferential class]]) {
        EXTDifferential *differential = object;
        return NSUnionRect([self _extBoundingRectForTerm:[differential start]],
                           [self _extBoundingRectForTerm:[differential end]]);
    }
    else if ([object isKindOfClass:[EXTMarquee class]]) {
        EXTMarquee *marquee = object;
        return marquee.frame;
    }

    return NSZeroRect;
}

- (NSRect)_extBoundingRectForTerm:(EXTTerm *)term {
    EXTGrid *grid = self.chartView.grid;
    return [grid viewBoundingRectForGridPoint:[_document.sseq.locConvertor gridPoint:term.location]];
}

#pragma mark - NSKeyValueObserving

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == _selectedToolTagContext) {
        EXTToolboxTag newTag = [change[NSKeyValueChangeNewKey] integerValue];
        self.selectedObject = nil;
        [self.chartView.window invalidateCursorRectsForView:self.chartView];
        self.chartView.highlightsGridPositionUnderCursor = (newTag != EXTToolTagArtboard);
        self.chartView.editingArtBoard = (newTag == EXTToolTagArtboard);
        [self.chartView resetHighlightPath];
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

@end
