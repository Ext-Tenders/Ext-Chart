//
//  EXTChartViewModel.m
//  Ext Chart
//
//  Created by Bavarious on 10/06/2014.
//  Copyright (c) 2014 Harvard University. All rights reserved.
//

#import "EXTChartViewModel.h"
#import "EXTSpectralSequence.h"
#import "EXTGrid.h"
#import "EXTTerm.h"
#import "EXTDifferential.h"
#import "EXTPolynomialSSeq.h"
#import "NSValue+EXTIntPoint.h"


#pragma mark - Private classes & extensions

@interface EXTChartViewModel ()
/// Indexed by @(page). Each element is a dictionary mapping an NSValue-wrapped EXTIntPoint to an EXTChartViewModelTermCell object at that grid location.
@property (nonatomic, strong) NSMutableDictionary *privateTermCells;

/// Indexed by @(page). Each element is an NSMutableArray of EXTChartViewModelDifferential objects.
@property (nonatomic, strong) NSMutableDictionary *privateDifferentials;

// MERGE
// indexed by @(page). Each element is a mutable dictionary of a style, keyed on @"style", and an array, keyed on @"annotations", of EXTViewModelMultAnnotation objects
// @property (nonatomic, strong) NSMutableDictionary *privateMultAnnotations;

/// Indexed by @(page). Each element is an NSMapTable mapping EXTTerm objects to EXTChartViewModelTerm objects.
@property (nonatomic, strong) NSMutableDictionary *modelToViewModelTermMap;
@end


@interface EXTChartViewModelTermCell ()
@property (nonatomic, readwrite, assign) NSInteger totalRank;
@property (nonatomic, strong) NSMutableArray *privateTerms;
@property (nonatomic, assign) NSInteger numberOfReferencedTerms;
+ (instancetype)termCellAtGridLocation:(EXTIntPoint)gridLocation;
- (void)addTerm:(EXTChartViewModelTerm *)term withDimension:(NSInteger)dimension;
@end


@interface EXTChartViewModelTerm ()
@property (nonatomic, readwrite, weak) EXTChartViewModelTermCell *termCell;
@property (nonatomic, readwrite, weak) EXTChartViewModelDifferential *differential;
+ (instancetype)viewModelTermWithModelTerm:(EXTTerm *)modelTerm gridLocation:(EXTIntPoint)gridLocation;
@end


@interface EXTChartViewModelDifferential ()
@property (nonatomic, strong) NSMutableArray *privateLines;
+ (instancetype)viewModelDifferentialWithModelDifferential:(EXTDifferential *)modelDifferential
                                                 startTerm:(EXTChartViewModelTerm *)startTerm
                                                   endTerm:(EXTChartViewModelTerm *)endTerm;
- (void)addLine:(EXTChartViewModelDifferentialLine *)line;
@end


@interface EXTChartViewModelDifferentialLine ()
+ (instancetype)viewModelDifferentialLineWithStartIndex:(NSInteger)startIndex endIndex:(NSInteger)endIndex;
@end


#pragma mark - Private functions

static bool lineSegmentOverRect(NSPoint p1, NSPoint p2, NSRect rect);
static bool lineSegmentIntersectsLineSegment(NSPoint l1p1, NSPoint l1p2, NSPoint l2p1, NSPoint l2p2);


@implementation EXTChartViewModel

@dynamic termCells, differentials;

- (instancetype)init {
    self = [super init];
    if (self) {
        _privateTermCells = [NSMutableDictionary new];
        _privateDifferentials = [NSMutableDictionary new];
        // MERGE
        //_privateMultAnnotations = [NSMutableDictionary new];
        _modelToViewModelTermMap = [NSMutableDictionary new];
    }
    return self;
}

- (void)reloadCurrentPage
{
    [self.sequence computeGroupsForPage:self.currentPage];

    // --- Terms
    NSMutableDictionary *termCells = [NSMutableDictionary new];
    NSMapTable *modelToViewModelTermMap = [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsObjectPointerPersonality
                                                                valueOptions:NSPointerFunctionsObjectPersonality];

    // iterate through the available EXTTerms and count up how many project onto
    // a given grid location.  (this is a necessary step for, e.g., EXTTriple-
    // graded spectral sequences, where many EXTLocations might end up in the
    // same place.)
    //
    // TODO: the way this is set up does not allow EXTTerms to determine how
    // they get drawn.  this will probably need to be changed when we move to
    // Z-mods, since those have lots of interesting quotients which need to
    // represented visually.
    for (EXTTerm *term in self.sequence.terms.allValues) {
        const NSInteger termDimension = [term dimension:self.currentPage];
        if (termDimension == 0) continue;

        const EXTIntPoint gridLocation = [self.sequence.locConvertor gridPoint:term.location];
        NSValue *gridLocationValue = [NSValue extValueWithIntPoint:gridLocation];
        EXTChartViewModelTerm *viewModelTerm = [EXTChartViewModelTerm viewModelTermWithModelTerm:term gridLocation:gridLocation];
        EXTChartViewModelTermCell *termCell = termCells[gridLocationValue];
        if (!termCell) {
            termCell = [EXTChartViewModelTermCell termCellAtGridLocation:gridLocation];
            termCells[gridLocationValue] = termCell;
        }

        [termCell addTerm:viewModelTerm withDimension:termDimension];
        viewModelTerm.termCell = termCell;

        [modelToViewModelTermMap setObject:viewModelTerm forKey:term];
    }

    // --- Differentials
    NSMutableArray *differentials = [NSMutableArray new];

    if (self.currentPage < self.sequence.differentials.count) {
        for (EXTDifferential *differential in ((NSDictionary*)self.sequence.differentials[self.currentPage]).allValues) {
            // some sanity checks to make sure this differential is worth drawing
            if ([differential page] != self.currentPage)
                continue;
            
            EXTMatrix *boundaryMatrix = differential.end.boundaries[self.currentPage];
            boundaryMatrix.characteristic = differential.presentation.characteristic;
            int imageSize = [EXTMatrix rankOfMap:differential.presentation intoQuotientByTheInclusion:boundaryMatrix];
            
            if ((imageSize <= 0) ||
                ([differential.start dimension:differential.page] == 0) ||
                ([differential.end dimension:differential.page] == 0))
                continue;

            EXTChartViewModelTerm *startTerm = [modelToViewModelTermMap objectForKey:differential.start];
            EXTChartViewModelTerm *endTerm = [modelToViewModelTermMap objectForKey:differential.end];

            NSAssert(startTerm, @"Differential should have non nil start term");
            NSAssert(endTerm, @"Differential should have non nil end term");

            EXTChartViewModelDifferential *diff = [EXTChartViewModelDifferential viewModelDifferentialWithModelDifferential:differential
                                                                                                                  startTerm:startTerm
                                                                                                                    endTerm:endTerm];
            [differentials addObject:diff];
            startTerm.differential = diff;

            for (NSInteger i = 0; i < imageSize; ++i) {
                NSInteger startOffset = startTerm.termCell.numberOfReferencedTerms;
                NSInteger endOffset = endTerm.termCell.numberOfReferencedTerms;
                startTerm.termCell.numberOfReferencedTerms += 1;
                endTerm.termCell.numberOfReferencedTerms += 1;

                EXTChartViewModelDifferentialLine *line = [EXTChartViewModelDifferentialLine viewModelDifferentialLineWithStartIndex:startOffset endIndex:endOffset];
                [diff addLine:line];
            }
        }
    }
    
    // MERGE
    /*
    // --- Multiplicative annotations
    NSMutableArray *annotationPairs = [NSMutableArray new];
    for (NSMutableDictionary *rule in self.multiplicationAnnotationRules) {
        // each of these dictionaries has:
        //   @"enabled": bool toggling whether we should bother to draw these
        //   @"style": unimplemented, reserved for a class describing line style
        //   @"location": location of the term we're going to multiply through
        //   @"vector": vector in the term at @"location" we're ^^^
        if (![rule[@"enabled"] boolValue])
            continue;
        
        NSMutableArray *annotationArray = [NSMutableArray new];
        
        for (EXTTerm *term in self.sequence.terms.allValues) {
            int rank = [self.sequence rankOfVector:rule[@"vector"]
                                        inLocation:rule[@"location"]
                                          actingAt:term.location
                                            onPage:self.currentPage];
            if (rank == 0)
                continue;
            
            // otherwise, draw something.
            const EXTIntPoint startPoint = [self.sequence.locConvertor gridPoint:term.location];
            const EXTIntPoint endPoint = [self.sequence.locConvertor gridPoint:[self.sequence.indexClass addLocation:term.location to:rule[@"location"]]];
            EXTViewModelPoint *modelStartPoint = [EXTViewModelPoint newViewModelPointWithX:startPoint.x y:startPoint.y];
            EXTViewModelPoint *modelEndPoint = [EXTViewModelPoint newViewModelPointWithX:endPoint.x y:endPoint.y];
            const NSInteger startCount = [counts[modelStartPoint] integerValue];
            const NSInteger endCount = [counts[modelEndPoint] integerValue];
            NSArray *startRects = dotPositions(startCount, startPoint, self.grid.gridSpacing);
            NSArray *endRects = dotPositions(endCount, endPoint, self.grid.gridSpacing);
                
            NSRect startRect = [startRects[0] rectValue];
            NSRect endRect = [endRects[0] rectValue];
            NSPoint viewStartPoint = (NSPoint){startRect.origin.x, startRect.origin.y + startRect.size.height / 2};
            NSPoint viewEndPoint = (NSPoint){
                endRect.origin.x + endRect.size.width - 0.1 * self.grid.gridSpacing,
                endRect.origin.y + endRect.size.height / 2
            };
            EXTViewModelMultAnnotation *anno = [EXTViewModelMultAnnotation newViewModelMultAnnotationWithStart:viewStartPoint end:viewEndPoint];
            [annotationArray addObject:anno];
        }
        
        // add the array of annotations we've constructed as an entry
        NSMutableDictionary *entry = [NSMutableDictionary new];
        entry[@"annotations"] = annotationArray;
        if (rule[@"style"])
            entry[@"style"] = rule[@"style"];
        [annotationPairs addObject:entry];
    }
    */

    self.privateTermCells[@(self.currentPage)] = termCells;
    self.privateDifferentials[@(self.currentPage)] = differentials;
    // MERGE
    //self.multAnnotations[@(self.currentPage)] = annotationPairs;
    self.modelToViewModelTermMap[@(self.currentPage)] = modelToViewModelTermMap; // FIXME: Do we need to keep this?
}

- (void)selectObjectAtGridLocation:(EXTIntPoint)gridLocation
{
    switch (self.interactionType) {
        case EXTChartInteractionTypeTerm: {
            EXTChartViewModelTermCell *termCell = [self termCellAtGridLocation:gridLocation];
            if (termCell.terms.count == 0) {
                self.selectedObject = nil;
                break;
            }

            NSUInteger newSelectionIndex = [self indexOfObjectInArray:termCell.terms afterObjectIdenticalTo:self.selectedObject];
            self.selectedObject = (newSelectionIndex == NSNotFound ? nil : termCell.terms[newSelectionIndex]);

            break;
        }

        case EXTChartInteractionTypeDifferential: {
            EXTChartViewModelTermCell *termCell = [self termCellAtGridLocation:gridLocation];
            if (termCell.terms.count == 0) {
                self.selectedObject = nil;
                break;
            }

            // First, let’s check if the currently selected object is a differential whose start term is located at
            // the selected grid cell
            EXTChartViewModelTerm *selectedTermInCell = nil;
            if ([self.selectedObject isKindOfClass:[EXTChartViewModelDifferential class]]) {
                EXTChartViewModelTerm *selectedTerm = ((EXTChartViewModelDifferential *)self.selectedObject).startTerm;
                if (selectedTerm.termCell == termCell) selectedTermInCell = selectedTerm;
            }

            NSUInteger nextTermIndex;

            // If the selected term is located in this cell, try to select the differential for the next term in that cell
            if (selectedTermInCell) {
                nextTermIndex = [self indexOfObjectInArray:termCell.terms afterObjectIdenticalTo:selectedTermInCell];
            }
            // Otherwise, try to select the first differential--the first term that has a differential
            else {
                nextTermIndex = [termCell.terms indexOfObjectPassingTest:^BOOL(EXTChartViewModelTerm *term, NSUInteger idx, BOOL *stop) {
                    return term.differential != nil;
                }];
            }

            if (nextTermIndex != NSNotFound) {
                EXTChartViewModelTerm *newTerm = termCell.terms[nextTermIndex];
                self.selectedObject = newTerm.differential;
            }
            else {
                self.selectedObject = nil;
            }

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

        case EXTChartInteractionTypeArtBoard:
        case EXTChartInteractionTypeMultiplicativeStructure:
        default:
            break;
    }
}

- (EXTChartViewModelTermCell *)termCellAtGridLocation:(EXTIntPoint)gridLocation
{
    EXTChartViewModelTermCell *result = nil;
    for (EXTChartViewModelTermCell *termCell in [self.privateTermCells[@(self.currentPage)] allValues]) {
        if (EXTEqualIntPoints(termCell.gridLocation, gridLocation)) {
            result = termCell;
            break;
        }
    }
    return result;
}

// MERGE
/*
- (NSArray *)chartView:(EXTChartView *)chartView multAnnotationsInRect:(NSRect)gridRect {
    NSMutableArray *result = [NSMutableArray array];
    for (NSMutableDictionary *annoGroup in self.multAnnotations[@(self.currentPage)]) {
        NSMutableArray *convertedAnnotations = [NSMutableArray new];
        for (EXTViewModelMultAnnotation *anno in annoGroup[@"annotations"]) {
            if (lineSegmentOverRect(anno.start, anno.end, gridRect)) {
                EXTChartViewMultAnnotationData *data = [EXTChartViewMultAnnotationData new];
                data.start = anno.start;
                data.end = anno.end;
                [convertedAnnotations addObject:data];
            }
        }
        NSMutableDictionary *entry = [NSMutableDictionary new];
        entry[@"annotations"] = convertedAnnotations;
        if (annoGroup[@"style"])
            entry[@"style"] = annoGroup[@"style"];
        [result addObject:entry];
    }
    return result.copy;
}
*/

- (NSUInteger)indexOfObjectInArray:(NSArray *)array afterObjectIdenticalTo:(id)object
{
    if (array.count == 0) return NSNotFound;

    const NSUInteger currentIndex = [array indexOfObjectIdenticalTo:object];
    if (currentIndex == NSNotFound) return 0;
    if (currentIndex + 1 == array.count) return NSNotFound;

    return currentIndex + 1;
}

#pragma mark - Computed properties

- (NSArray *)termCells
{
    return [[self.privateTermCells[@(self.currentPage)] allValues] copy];
}

- (NSArray *)differentials
{
    return [self.privateDifferentials[@(self.currentPage)] copy];
}

@end


@implementation EXTChartViewModelTerm
+ (instancetype)viewModelTermWithModelTerm:(EXTTerm *)modelTerm gridLocation:(EXTIntPoint)gridLocation
{
    EXTChartViewModelTerm *newTerm = [[self class] new];
    if (newTerm) {
        newTerm->_gridLocation = gridLocation;
        newTerm->_modelTerm = modelTerm;
    }
    return newTerm;
}
@end


#pragma mark -- helper classes --


@implementation EXTChartViewModelTermCell
@dynamic terms;

- (instancetype)init
{
    self = [super init];
    if (self) {
        _privateTerms = [NSMutableArray new];
    }
    return self;
}

+ (instancetype)termCellAtGridLocation:(EXTIntPoint)gridLocation
{
    EXTChartViewModelTermCell *newTermCell = [[self class] new];
    if (newTermCell) {
        newTermCell->_gridLocation = gridLocation;
    }
    return newTermCell;
}

- (void)addTerm:(EXTChartViewModelTerm *)term withDimension:(NSInteger)dimension
{
    [self.privateTerms addObject:term];
    self.totalRank += dimension;
}

- (NSArray *)terms
{
    return [self.privateTerms copy];
}
@end

@implementation EXTChartViewModelDifferential
@dynamic lines;

+ (instancetype)viewModelDifferentialWithModelDifferential:(EXTDifferential *)modelDifferential
                                                 startTerm:(EXTChartViewModelTerm *)startTerm
                                                   endTerm:(EXTChartViewModelTerm *)endTerm
{
    EXTChartViewModelDifferential *newDiff = [[self class] new];
    if (newDiff) {
        newDiff->_modelDifferential = modelDifferential;
        newDiff->_startTerm = startTerm;
        newDiff->_endTerm = endTerm;
    }
    return newDiff;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _privateLines = [NSMutableArray array];
    }
    return self;
}

- (void)addLine:(EXTChartViewModelDifferentialLine *)line
{
    [self.privateLines addObject:line];
}

- (NSArray *)lines
{
    return [self.privateLines copy];
}
@end

// MERGE
/*
@implementation EXTViewModelMultAnnotation
+ (instancetype)newViewModelMultAnnotationWithStart:(NSPoint)start
                                                end:(NSPoint)end
{
    EXTViewModelMultAnnotation *newAnno = [[self class] new];
    newAnno->_start = start;
    newAnno->_end = end;
    return newAnno;
}
@end
*/


@implementation EXTChartViewModelDifferentialLine
+ (instancetype)viewModelDifferentialLineWithStartIndex:(NSInteger)startIndex endIndex:(NSInteger)endIndex
{
    EXTChartViewModelDifferentialLine *newLine = [[self class] new];
    if (newLine) {
        newLine->_startIndex = startIndex;
        newLine->_endIndex = endIndex;
    }
    return newLine;
}
@end


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
