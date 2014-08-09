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

// Indexed by @(page). Each element is a mutable dictionary of a style, keyed on @"style", and an array, keyed on @"annotations", of EXTViewModelMultAnnotation objects
@property (nonatomic, strong) NSMutableDictionary *privateMultAnnotations;

/// Indexed by @(page). Each element is an NSMapTable mapping EXTTerm objects to EXTChartViewModelTerm objects.
@property (nonatomic, strong) NSMutableDictionary *modelToViewModelTermMap;
@end


@interface EXTChartViewModelTermCell ()
@property (nonatomic, strong) NSMutableArray *privateTerms;
+ (instancetype)termCellAtGridLocation:(EXTIntPoint)gridLocation;
- (void)addTerm:(EXTChartViewModelTerm *)term;
/// Given a term, all of its homology representatives are distinct. Given a term cell, the homology representatives of all terms in that cell are pairwise-distinct. We can use this property to induce an ordering of terms in that cell: we pick the lexicographically smallest hReps for each term in that cell and use the same lexicographic order to order terms according to their smallest hReps.
- (void)sortTerms;
/// Given the term position inside the cell and the orders/dimensions? (FIXME: ask Eric to review this), computes the initial offset for that term.
- (NSUInteger)baseOffsetForTerm:(EXTChartViewModelTerm *)term;
@end


@interface EXTChartViewModelTerm ()
@property (nonatomic, readwrite, weak) EXTChartViewModelTermCell *termCell;
@property (nonatomic, readwrite, weak) EXTChartViewModelDifferential *differential;
@property (nonatomic, readwrite, copy) NSArray *homologyReps;
+ (instancetype)viewModelTermWithModelTerm:(EXTTerm *)modelTerm modelHomologyReps:(NSDictionary *)modelHomologyReps sequence:(EXTSpectralSequence *)sequence;
@end


@interface EXTChartViewModelTermHomologyReps ()
@property (nonatomic, readwrite, weak) EXTChartViewModelTerm *term;
+ (instancetype)viewModelTermHomologyRepsWithTerm:(EXTChartViewModelTerm *)term hReps:(NSArray *)hReps order:(NSInteger)order;
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

@interface EXTChartViewModelMultAnnotation ()
@property (nonatomic, strong) NSMutableArray *privateLines;
+ (instancetype)viewModelMultAnnotationWithModelAnnotation:(NSDictionary*)modelMultAnnotation startTerm:(EXTChartViewModelTerm*)startTerm endTerm:(EXTChartViewModelTerm*)endTerm fixedMultTerm:(EXTChartViewModelTerm*)fixedMultTerm sseq:(EXTSpectralSequence*)sseq page:(int)page;
- (void)addLine:(EXTChartViewModelMultAnnoLine *)line;
@end

@interface EXTChartViewModelMultAnnoLine ()
+ (instancetype)viewModelMultAnnoLineWithStartIndex:(NSInteger)startIndex endIndex:(NSInteger)endIndex;
@end


#pragma mark - Private functions

static bool lineSegmentOverRect(NSPoint p1, NSPoint p2, NSRect rect);
static bool lineSegmentIntersectsLineSegment(NSPoint l1p1, NSPoint l1p2, NSPoint l2p1, NSPoint l2p2);

static NSComparisonResult(^hRepsComparator)(EXTChartViewModelTermHomologyReps *, EXTChartViewModelTermHomologyReps *) = ^(EXTChartViewModelTermHomologyReps *obj1, EXTChartViewModelTermHomologyReps *obj2){
    NSArray *reps1 = obj1.representatives;
    NSArray *reps2 = obj2.representatives;

    if (reps1.count < reps2.count) return NSOrderedAscending;
    if (reps1.count > reps2.count) return NSOrderedDescending;

    const NSInteger count = reps1.count;
    for (NSInteger i = 0; i < count; ++i) {
        NSComparisonResult result = [reps1[i] compare:reps2[i]];
        if (result != NSOrderedSame) return result;
    }

    return NSOrderedSame;
};


@implementation EXTChartViewModel

@dynamic termCells, differentials;

- (instancetype)init {
    self = [super init];
    if (self) {
        _privateTermCells = [NSMutableDictionary new];
        _privateDifferentials = [NSMutableDictionary new];
        _privateMultAnnotations = [NSMutableDictionary new];
        _modelToViewModelTermMap = [NSMutableDictionary new];
    }
    return self;
}

- (void)reloadCurrentPage
{
    [self.sequence computeGroupsForPage:self.currentPage];

    // --- Terms
    NSMutableDictionary *termCells = [NSMutableDictionary new];
    NSMapTable *modelToViewModelTermMap = [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsObjectPersonality
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
        EXTChartViewModelTerm *viewModelTerm = [EXTChartViewModelTerm viewModelTermWithModelTerm:term
                                                                               modelHomologyReps:term.homologyReps[self.currentPage]
                                                                                        sequence:self.sequence];
        EXTChartViewModelTermCell *termCell = termCells[gridLocationValue];
        if (!termCell) {
            termCell = [EXTChartViewModelTermCell termCellAtGridLocation:gridLocation];
            termCells[gridLocationValue] = termCell;
        }

        [termCell addTerm:viewModelTerm];
        viewModelTerm.termCell = termCell;

        [modelToViewModelTermMap setObject:viewModelTerm forKey:term.location];
    }

    // --- Term cells

    for (EXTChartViewModelTermCell *termCell in termCells.allValues) [termCell sortTerms];

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

            EXTChartViewModelTerm *startTerm = [modelToViewModelTermMap objectForKey:differential.start.location];
            EXTChartViewModelTerm *endTerm = [modelToViewModelTermMap objectForKey:differential.end.location];

            NSAssert(startTerm, @"Differential should have non nil start term");
            NSAssert(endTerm, @"Differential should have non nil end term");

            EXTChartViewModelDifferential *diff = [EXTChartViewModelDifferential viewModelDifferentialWithModelDifferential:differential
                                                                                                                  startTerm:startTerm
                                                                                                                    endTerm:endTerm];
            [differentials addObject:diff];
            startTerm.differential = diff;

            const NSUInteger startBaseOffset = [startTerm.termCell baseOffsetForTerm:startTerm];
            const NSUInteger endBaseOffset = [endTerm.termCell baseOffsetForTerm:endTerm];

            [diff.hRepAssignments enumerateKeysAndObjectsUsingBlock:^(NSArray *sourceHReps, NSArray *targetHReps, BOOL *stop) {
                const NSUInteger startOffset = [startTerm.homologyReps indexOfObjectPassingTest:^BOOL(EXTChartViewModelTermHomologyReps *hReps, NSUInteger idx, BOOL *stop) {
                    return [hReps.representatives isEqualToArray:sourceHReps];
                }] + startBaseOffset;
                NSAssert(startOffset != NSNotFound, @"HReps not found");

                const NSUInteger endOffset = [endTerm.homologyReps indexOfObjectPassingTest:^BOOL(EXTChartViewModelTermHomologyReps *hReps, NSUInteger idx, BOOL *stop) {
                    return [hReps.representatives isEqualToArray:targetHReps];
                }] + endBaseOffset;
                NSAssert(endOffset != NSNotFound, @"HReps not found");

                EXTChartViewModelDifferentialLine *line = [EXTChartViewModelDifferentialLine viewModelDifferentialLineWithStartIndex:startOffset endIndex:endOffset];
                [diff addLine:line];
            }];
        }
    }
    
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
            // otherwise, draw something.
            EXTChartViewModelTerm *startTerm = [modelToViewModelTermMap objectForKey:term.location];
            EXTChartViewModelTerm *endTerm = [modelToViewModelTermMap objectForKey:[self.sequence.indexClass addLocation:term.location to:rule[@"location"]]];
            EXTChartViewModelTerm *fixedMultTerm = [modelToViewModelTermMap objectForKey:rule[@"location"]];
            
            EXTChartViewModelMultAnnotation *anno = [EXTChartViewModelMultAnnotation viewModelMultAnnotationWithModelAnnotation:rule startTerm:startTerm endTerm:endTerm fixedMultTerm:fixedMultTerm sseq:self.sequence page:self.currentPage];
            
            [annotationArray addObject:anno];
            
            const NSUInteger startBaseOffset = [startTerm.termCell baseOffsetForTerm:startTerm];
            const NSUInteger endBaseOffset = [endTerm.termCell baseOffsetForTerm:endTerm];
            
            [anno.hRepAssignments enumerateKeysAndObjectsUsingBlock:^(NSArray *sourceHReps, NSArray *targetHReps, BOOL *stop) {
                const NSUInteger startOffset = [startTerm.homologyReps indexOfObjectPassingTest:^BOOL(EXTChartViewModelTermHomologyReps *hReps, NSUInteger idx, BOOL *stop) {
                    return [hReps.representatives isEqualToArray:sourceHReps];
                }] + startBaseOffset;
                NSAssert(startOffset != NSNotFound, @"HReps not found");
                
                const NSUInteger endOffset = [endTerm.homologyReps indexOfObjectPassingTest:^BOOL(EXTChartViewModelTermHomologyReps *hReps, NSUInteger idx, BOOL *stop) {
                    return [hReps.representatives isEqualToArray:targetHReps];
                }] + endBaseOffset;
                NSAssert(endOffset != NSNotFound, @"HReps not found");
                
                EXTChartViewModelMultAnnoLine *line = [EXTChartViewModelMultAnnoLine viewModelMultAnnoLineWithStartIndex:startOffset endIndex:endOffset];
                [anno addLine:line];
            }];
        }
        
        // add the array of annotations we've constructed as an entry
        NSMutableDictionary *entry = [NSMutableDictionary new];
        entry[@"annotations"] = annotationArray;
        if (rule[@"style"])
            entry[@"style"] = rule[@"style"];
        [annotationPairs addObject:entry];
    }

    self.privateTermCells[@(self.currentPage)] = termCells;
    self.privateDifferentials[@(self.currentPage)] = differentials;
    self.privateMultAnnotations[@(self.currentPage)] = annotationPairs;
    self.modelToViewModelTermMap[@(self.currentPage)] = modelToViewModelTermMap; // FIXME: Do we need to keep this?
}

- (EXTChartViewModelTerm *)viewModelTermForModelTerm:(EXTTerm *)term {
    return [self.modelToViewModelTermMap[@(self.currentPage)] objectForKey:term.location];
}

- (EXTChartViewModelDifferential *)viewModelDifferentialForModelDifferential:(EXTDifferential *)differential {
    for (EXTChartViewModelDifferential *viewModelDiff in self.privateDifferentials[@(self.currentPage)]) {
        if ([viewModelDiff.modelDifferential.start.location isEqual:differential.start.location]) {
            return viewModelDiff;
        }
    }

    return nil;
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

#pragma mark - Computed properties

- (NSArray *)termCells
{
    return [[self.privateTermCells[@(self.currentPage)] allValues] copy];
}

- (NSArray *)differentials
{
    return [self.privateDifferentials[@(self.currentPage)] copy];
}

- (NSArray *)multAnnotations
{
    return [self.privateMultAnnotations[@(self.currentPage)] copy];
}

@end


@implementation EXTChartViewModelTerm
@dynamic dimension;

+ (instancetype)viewModelTermWithModelTerm:(EXTTerm *)modelTerm modelHomologyReps:(NSDictionary *)modelHomologyReps sequence:(EXTSpectralSequence *)sequence
{
    NSParameterAssert(modelTerm);
    NSAssert(modelHomologyReps.allKeys.count > 0, @"Need non-empty model hReps");

    EXTChartViewModelTerm *newTerm = [[self class] new];
    if (!newTerm) return nil;

    newTerm->_modelTerm = modelTerm;

    NSMutableArray *tempHomologyReps = [NSMutableArray new];
    [modelHomologyReps enumerateKeysAndObjectsUsingBlock:^(NSArray *modelHReps, NSNumber *order, BOOL *stop) {
        NSInteger intOrder = ABS(order.integerValue); // TODO: Check this with Eric
        if (intOrder == 0 && sequence.defaultCharacteristic != 0) intOrder = sequence.defaultCharacteristic;

        EXTChartViewModelTermHomologyReps *hReps = [EXTChartViewModelTermHomologyReps viewModelTermHomologyRepsWithTerm:newTerm hReps:modelHReps order:intOrder];
        [tempHomologyReps addObject:hReps];
    }];

    // We need to specify some order to homology representatives so that we can consistently locate them inside a grid cell.
    newTerm->_homologyReps = [tempHomologyReps sortedArrayUsingComparator:hRepsComparator];

    return newTerm;
}

- (NSInteger)dimension {
    return self.homologyReps.count;
}
@end


@implementation EXTChartViewModelTermHomologyReps
+ (instancetype)viewModelTermHomologyRepsWithTerm:(EXTChartViewModelTerm *)term hReps:(NSArray *)hReps order:(NSInteger)order {
    EXTChartViewModelTermHomologyReps *newHReps = [EXTChartViewModelTermHomologyReps new];
    if (newHReps) {
        newHReps->_term = term;
        newHReps->_representatives = [hReps copy];
        newHReps->_order = order;
    }
    return newHReps;
}
@end


@implementation EXTChartViewModelTermCell
@dynamic terms;
@dynamic totalRank;

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

- (void)addTerm:(EXTChartViewModelTerm *)term
{
    [self.privateTerms addObject:term];
}

- (void)sortTerms {
    NSMutableArray *cellHReps = [NSMutableArray new];
    for (EXTChartViewModelTerm *term in self.privateTerms) [cellHReps addObject:term.homologyReps.firstObject];
    [cellHReps sortUsingComparator:hRepsComparator];

    NSMutableArray *sortedTerms = [NSMutableArray new];
    for (EXTChartViewModelTermHomologyReps *hReps in cellHReps) [sortedTerms addObject:hReps.term];
    self.privateTerms = sortedTerms;
}

- (NSArray *)terms
{
    return [self.privateTerms copy];
}

- (NSInteger)totalRank
{
    return [[self.privateTerms valueForKeyPath:@"@sum.dimension"] integerValue];
}

- (NSUInteger)baseOffsetForTerm:(EXTChartViewModelTerm *)sourceTerm {
    NSUInteger base = 0;

    for (EXTChartViewModelTerm *term in self.privateTerms) {
        if (term == sourceTerm) break;
        base += term.dimension;
    }

    return base;
}

@end

@implementation EXTChartViewModelDifferential
@dynamic lines;

+ (instancetype)viewModelDifferentialWithModelDifferential:(EXTDifferential *)modelDifferential
                                                 startTerm:(EXTChartViewModelTerm *)startTerm
                                                   endTerm:(EXTChartViewModelTerm *)endTerm
{
    EXTChartViewModelDifferential *newDiff = [[self class] new];
    if (!newDiff) return nil;

    newDiff->_modelDifferential = modelDifferential;
    newDiff->_startTerm = startTerm;
    newDiff->_endTerm = endTerm;
    
    newDiff->_hRepAssignments = [modelDifferential.presentation homologyToHomologyKeysFrom:modelDifferential.start to:modelDifferential.end onPage:modelDifferential.page];
    
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


@implementation EXTChartViewModelMultAnnotation
@dynamic lines;

+ (instancetype)viewModelMultAnnotationWithModelAnnotation:(NSDictionary*)modelMultAnnotation startTerm:(EXTChartViewModelTerm*)startTerm endTerm:(EXTChartViewModelTerm*)endTerm fixedMultTerm:(EXTChartViewModelTerm*)fixedMultTerm sseq:(EXTSpectralSequence *)sseq page:(int)page {
    
    EXTChartViewModelMultAnnotation *newAnno = [[self class] new];
    
    if (newAnno) {
        newAnno->_modelMultAnnotation = modelMultAnnotation;
        newAnno->_startTerm = startTerm;
        newAnno->_endTerm = endTerm;
        
        EXTLocation *loc = modelMultAnnotation[@"location"];
        NSArray *vector = modelMultAnnotation[@"vector"];
        
        EXTMatrix *columnMatrix = [EXTMatrix matrixWidth:1 height:fixedMultTerm.modelTerm.size];
        int *columnData = columnMatrix.presentation.mutableBytes;
        for (int i = 0; i < columnMatrix.height; i++)
            columnData[i] = [vector[i] intValue];
        EXTMatrix *actionMatrix = [EXTMatrix newMultiply:[sseq productWithLeft:startTerm.modelTerm.location right:loc] by:[EXTMatrix hadamardProduct:[EXTMatrix identity:startTerm.modelTerm.size] with:columnMatrix]];
        
        newAnno->_hRepAssignments = [actionMatrix homologyToHomologyKeysFrom:startTerm.modelTerm to:endTerm.modelTerm onPage:page];
    }
    
    return newAnno;
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

@implementation EXTChartViewModelMultAnnoLine
+ (instancetype)viewModelMultAnnoLineWithStartIndex:(NSInteger)startIndex endIndex:(NSInteger)endIndex
{
    EXTChartViewModelMultAnnoLine *newLine = [[self class] new];
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
