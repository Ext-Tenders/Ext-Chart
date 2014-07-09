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


#pragma mark - Private classes & extensions

@interface EXTChartViewModel ()
/// Indexed by @(page). Each element is a dictionary mapping an EXTViewModelPoint to an NSMutableArray of EXTChartViewModelTermCell objects at that grid location.
@property (nonatomic, strong) NSMutableDictionary *privateTermCells;

/// Indexed by @(page). Each element is an NSMutableArray of EXTChartViewModelDifferential objects.
@property (nonatomic, strong) NSMutableDictionary *privateDifferentials;

/// Indexed by @(page). Each element is an NSMapTable mapping model terms to view model terms.
@property (nonatomic, strong) NSMutableDictionary *modelToViewModelTermMap;
@end


@interface EXTChartViewModelTermCell ()
@property (nonatomic, readwrite, assign) NSInteger totalRank;
@property (nonatomic, strong) NSMutableArray *privateTerms;
+ (instancetype)termCellAtGridLocation:(EXTIntPoint)gridLocation;
- (void)addTerm:(EXTChartViewModelTerm *)term withDimension:(NSInteger)dimension;
@end


@interface EXTViewModelPoint : NSObject <NSCopying> // FIXME: NSValue with (floating-point) NSPoint? NSValue category?
@property (nonatomic, readonly, assign) NSInteger x;
@property (nonatomic, readonly, assign) NSInteger y;

+ (instancetype)viewModelPointWithX:(NSInteger)x y:(NSInteger)y;
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

        EXTIntPoint gridLocation = [self.sequence.locConvertor gridPoint:term.location];
        EXTViewModelPoint *viewPoint = [EXTViewModelPoint viewModelPointWithX:gridLocation.x y:gridLocation.y];
        EXTChartViewModelTerm *viewModelTerm = [EXTChartViewModelTerm viewModelTermFromModelTerm:term gridLocation:gridLocation];
        EXTChartViewModelTermCell *termCell = termCells[viewPoint];
        if (!termCell) {
            termCell = [EXTChartViewModelTermCell termCellAtGridLocation:gridLocation];
            termCells[viewPoint] = termCell;
        }

        [termCell addTerm:viewModelTerm withDimension:termDimension];
        [modelToViewModelTermMap setObject:viewModelTerm forKey:term];
    }

    // --- Differentials
    NSMutableArray *differentials = [NSMutableArray new];
    NSMutableDictionary *termCellOffsets = [NSMutableDictionary new];

    if (self.currentPage < self.sequence.differentials.count) {
        for (EXTDifferential *differential in ((NSDictionary*)self.sequence.differentials[self.currentPage]).allValues) {
            // some sanity checks to make sure this differential is worth drawing
            if ([differential page] != self.currentPage)
                continue;
            
            NSMutableArray *boundaryList = differential.end.boundaries[self.currentPage];
            EXTMatrix *boundaryMatrix = [EXTMatrix matrixWidth:boundaryList.count height:differential.end.size];
            boundaryMatrix.presentation = boundaryList;
            boundaryMatrix.characteristic = differential.presentation.characteristic;
            NSArray *span = [EXTMatrix formIntersection:differential.presentation with:boundaryMatrix];
            EXTMatrix *reducedMatrix = [(EXTMatrix*)span[0] columnReduce];
            int imageSize = differential.presentation.width;
            for (NSArray *column in reducedMatrix.presentation)
                for (NSNumber *entry in column)
                    if (abs([entry intValue]) == 1) {
                        imageSize--;
                        continue;
                    }
            
            if ((imageSize <= 0) ||
                ([differential.start dimension:differential.page] == 0) ||
                ([differential.end dimension:differential.page] == 0))
                continue;

            const EXTIntPoint startPoint = [self.sequence.locConvertor gridPoint:differential.start.location];
            const EXTIntPoint endPoint = [self.sequence.locConvertor gridPoint:differential.end.location];
            EXTViewModelPoint *modelStartPoint = [EXTViewModelPoint viewModelPointWithX:startPoint.x y:startPoint.y];
            EXTViewModelPoint *modelEndPoint = [EXTViewModelPoint viewModelPointWithX:endPoint.x y:endPoint.y];

            for (NSInteger i = 0; i < imageSize; ++i) {
                NSInteger startOffset = [termCellOffsets[modelStartPoint] integerValue];
                NSInteger endOffset = [termCellOffsets[modelEndPoint] integerValue];
                termCellOffsets[modelStartPoint] = @(startOffset + 1);
                termCellOffsets[modelEndPoint] = @(endOffset + 1);

                EXTChartViewModelDifferential *diff = [EXTChartViewModelDifferential viewModelDifferentialWithStartTerm:[modelToViewModelTermMap objectForKey:diff.startTerm]
                                                                                                             startIndex:startOffset
                                                                                                                endTerm:[modelToViewModelTermMap objectForKey:diff.endTerm]
                                                                                                               endIndex:endOffset];
                [differentials addObject:diff];
            }
        }
    }

    self.privateTermCells[@(self.currentPage)] = termCells;
    self.privateDifferentials[@(self.currentPage)] = differentials;
    self.modelToViewModelTermMap[@(self.currentPage)] = modelToViewModelTermMap; // FIXME: Do we need to keep this?
}

#pragma mark - Computed properties

- (NSArray *)termCells
{
    return [self.privateTermCells[@(self.currentPage)] copy];
}

- (NSArray *)differentials
{
    return [self.privateDifferentials[@(self.currentPage)] copy];
}

@end


@implementation EXTViewModelPoint
+ (instancetype)viewModelPointWithX:(NSInteger)x y:(NSInteger)y
{
    EXTViewModelPoint *newPoint = [[self class] new];
    if (newPoint) {
        newPoint->_x = x;
        newPoint->_y = y;
    }
    return newPoint;
}

- (instancetype)copyWithZone:(NSZone *)zone
{
    return [[self class] viewModelPointWithX:_x y:_y];
}

- (NSUInteger)hash {
    return NSUINTROTATE(((NSUInteger)_x), NSUINT_BIT / 2) ^ _y;
}

- (BOOL)isEqual:(id)object
{
    EXTViewModelPoint *point = object;
    return ([point isKindOfClass:[EXTViewModelPoint class]] &&
            point.x == _x &&
            point.y == _y);
}
@end


@implementation EXTChartViewModelTerm
+ (instancetype)viewModelTermFromModelTerm:(EXTTerm *)modelTerm gridLocation:(EXTIntPoint)gridLocation
{
    EXTChartViewModelTerm *newTerm = [[self class] new];
    if (newTerm) {
        newTerm->_gridLocation = gridLocation;
        newTerm->_modelTerm = modelTerm;
    }
    return newTerm;
}
@end


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
+ (instancetype)viewModelDifferentialWithStartTerm:(EXTChartViewModelTerm *)startTerm
                                        startIndex:(NSInteger)startIndex
                                           endTerm:(EXTChartViewModelTerm *)endTerm
                                          endIndex:(NSInteger)endIndex
{
    EXTChartViewModelDifferential *newDiff = [[self class] new];
    if (newDiff) {
        newDiff->_startTerm = startTerm;
        newDiff->_startIndex = startIndex;
        newDiff->_endTerm = endTerm;
        newDiff->_endIndex = endIndex;
    }
    return newDiff;
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
