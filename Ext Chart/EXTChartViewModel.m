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
@property (nonatomic, assign) NSInteger numberOfReferencedTerms;
+ (instancetype)termCellAtGridLocation:(EXTIntPoint)gridLocation;
- (void)addTerm:(EXTChartViewModelTerm *)term;
/// Given a term, all of its homology representatives are distinct. Given a term cell, the homology representatives of all terms in that cell are pairwise-distinct. We can use this property to induce an ordering of terms in that cell: we pick the lexicographically smallest hReps for each term in that cell and use the same lexicographic order to order terms according to their smallest hReps.
- (void)sortTerms;
@end


@interface EXTChartViewModelTerm ()
@property (nonatomic, readwrite, weak) EXTChartViewModelTermCell *termCell;
@property (nonatomic, readwrite, weak) EXTChartViewModelDifferential *differential;
@property (nonatomic, readwrite, copy) NSArray *homologyReps;
+ (instancetype)viewModelTermWithModelTerm:(EXTTerm *)modelTerm modelHomologyReps:(NSDictionary *)modelHomologyReps;
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
+ (instancetype)viewModelMultAnnotationWithModelAnnotation:(NSDictionary*)modelMultAnnotation startTerm:(EXTChartViewModelTerm*)startTerm endTerm:(EXTChartViewModelTerm*)endTerm;
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
        EXTChartViewModelTerm *viewModelTerm = [EXTChartViewModelTerm viewModelTermWithModelTerm:term
                                                                               modelHomologyReps:term.homologyReps[self.currentPage]];
        EXTChartViewModelTermCell *termCell = termCells[gridLocationValue];
        if (!termCell) {
            termCell = [EXTChartViewModelTermCell termCellAtGridLocation:gridLocation];
            termCells[gridLocationValue] = termCell;
        }

        [termCell addTerm:viewModelTerm];
        viewModelTerm.termCell = termCell;

        [modelToViewModelTermMap setObject:viewModelTerm forKey:term];
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
            EXTTerm *targetTerm = [self.sequence findTerm:[self.sequence.indexClass addLocation:term.location to:rule[@"location"]]];
            EXTChartViewModelTerm *startTerm = [modelToViewModelTermMap objectForKey:term];
            EXTChartViewModelTerm *endTerm = [modelToViewModelTermMap objectForKey:targetTerm];
            
            EXTChartViewModelMultAnnotation *anno = [EXTChartViewModelMultAnnotation viewModelMultAnnotationWithModelAnnotation:rule startTerm:startTerm endTerm:endTerm];
            
            [annotationArray addObject:anno];
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
    return [self.modelToViewModelTermMap[@(self.currentPage)] objectForKey:term];
}

- (EXTChartViewModelDifferential *)viewModelDifferentialForModelDifferential:(EXTDifferential *)differential {
    for (EXTChartViewModelDifferential *viewModelDiff in self.privateDifferentials[@(self.currentPage)]) {
        if (viewModelDiff.modelDifferential == differential) {
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

+ (instancetype)viewModelTermWithModelTerm:(EXTTerm *)modelTerm modelHomologyReps:(NSDictionary *)modelHomologyReps
{
    NSParameterAssert(modelTerm);
    NSAssert(modelHomologyReps.allKeys.count > 0, @"Need non-empty model hReps");

    EXTChartViewModelTerm *newTerm = [[self class] new];
    if (!newTerm) return nil;

    newTerm->_modelTerm = modelTerm;

    NSMutableArray *tempHomologyReps = [NSMutableArray new];
    [modelHomologyReps enumerateKeysAndObjectsUsingBlock:^(NSArray *modelHReps, NSNumber *order, BOOL *stop) {
        EXTChartViewModelTermHomologyReps *hReps = [EXTChartViewModelTermHomologyReps viewModelTermHomologyRepsWithTerm:newTerm hReps:modelHReps order:order.integerValue];
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
    
    EXTTerm *source = modelDifferential.start, *target = modelDifferential.end;
    EXTMatrix *hSource = [EXTMatrix matrixWidth:((NSDictionary*)source.homologyReps[modelDifferential.page]).count height:source.size],
              *hTarget = [EXTMatrix matrixWidth:((NSDictionary*)target.homologyReps[modelDifferential.page]).count height:target.size];
    
    NSArray *hSourceKeys = ((NSDictionary*)source.homologyReps[modelDifferential.page]).allKeys,
            *hTargetKeys = ((NSDictionary*)target.homologyReps[modelDifferential.page]).allKeys;
    
    // build source and target
    int *hSourceData = hSource.presentation.mutableBytes;
    for (int i = 0; i < hSource.width; i++) {
        NSArray *vector = hSourceKeys[i];
        for (int j = 0; j < hSource.height; j++)
            hSourceData[i*hSource.height + j] = [vector[j] intValue];
    }
    
    int *hTargetData = hTarget.presentation.mutableBytes;
    for (int i = 0; i < hTarget.width; i++) {
        NSArray *vector = hTargetKeys[i];
        for (int j = 0; j < hTarget.height; j++)
            hTargetData[i*hTarget.height + j] = [vector[j] intValue];
    }
    
    NSArray *pair = [EXTMatrix formIntersection:[EXTMatrix newMultiply:modelDifferential.presentation by:hSource] with:[EXTMatrix directSumWithCommonTargetA:hTarget B:target.boundaries[modelDifferential.page]]];
    
    EXTMatrix *lift = [EXTMatrix newMultiply:pair[1] by:[(EXTMatrix*)pair[0] invertOntoMap]];
    
    NSMutableDictionary *assignment = [NSMutableDictionary dictionaryWithCapacity:hSourceKeys.count];
    for (int i = 0; i < hSourceKeys.count; i++)
        for (int j = 0; j < hTargetKeys.count; j++) {
            if (((int*)lift.presentation.mutableBytes)[i*lift.height+j] == 0)
                continue;
            if ([[assignment allValues] indexOfObject:hTargetKeys[j]] == NSNotFound)
                continue;
            assignment[hSourceKeys[i]] = hTargetKeys[j];
        }
    
    newDiff->_hRepAssignments = assignment;
    
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
+ (instancetype)viewModelMultAnnotationWithModelAnnotation:(NSDictionary*)modelMultAnnotation startTerm:(EXTChartViewModelTerm*)startTerm endTerm:(EXTChartViewModelTerm*)endTerm {
    
    EXTChartViewModelMultAnnotation *newAnno = [[self class] new];
    
    if (newAnno) {
        newAnno->_modelMultAnnotation = modelMultAnnotation;
        newAnno->_startTerm = startTerm;
        newAnno->_endTerm = endTerm;
    }
    
    return newAnno;
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
