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


@interface EXTChartViewModel ()
/// Indexed by @(page). Each element is a dictionary mapping an EXTViewModelPoint to an NSMutableArray of EXTViewModelTerm objects at that grid location.
@property (nonatomic, strong) NSMutableDictionary *termCounts;

/// Indexed by @(page). Each element is an NSArray (eventually an edge quadtree?) of EXTViewModelDifferential objects.
@property (nonatomic, strong) NSMutableDictionary *differentials;
@end


#pragma mark - Private functions

static bool lineSegmentOverRect(NSPoint p1, NSPoint p2, NSRect rect);
static bool lineSegmentIntersectsLineSegment(NSPoint l1p1, NSPoint l1p2, NSPoint l2p1, NSPoint l2p2);


@implementation EXTChartViewModel

- (instancetype)init {
    self = [super init];
    if (self) {
        _termCounts = [NSMutableDictionary new];
        _differentials = [NSMutableDictionary new];
    }
    return self;
}

- (void)reloadCurrentPage
{
    [self.sequence computeGroupsForPage:self.currentPage];

    // --- Terms
    NSMutableDictionary *counts = [NSMutableDictionary new];

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
        // FIXME: Ask Eric whether dimension can be > 1. If it can, then the number of terms with non-zero dimension
        //        at that grid location does not represent the term count, so we need to keep both an array of terms
        //        and a term count based on dimensions. Also, if all terms at a given location have dimension 0 at a
        //        given page, we do not show them visually. Does that mean they cannot be selected either?
        //
        //        The only demo that shows terms with dimension > 1 is the random demo, which cannot really be
        //        trusted anyway.
        const NSInteger termDimension = [term dimension:self.currentPage];

//        NSInteger termCount = ((NSNumber *)counts[viewPoint]).integerValue;
//        termCount += termDimension;
//        if (termCount > 0) {
//            counts[viewPoint] = @(termCount);
//        }

        if (termDimension > 0) {
            EXTIntPoint gridLocation = [self.sequence.locConvertor gridPoint:term.location];
            EXTViewModelPoint *viewPoint = [EXTViewModelPoint viewModelPointWithX:gridLocation.x y:gridLocation.y];
            EXTViewModelTerm *viewModelTerm = [EXTViewModelTerm viewModelTermFromModelTerm:term /*gridLocation:gridLocation*/];
            
            NSMutableArray *termsAtGridLocation = counts[viewPoint];
            if (!termsAtGridLocation) termsAtGridLocation = [NSMutableArray new];
            [termsAtGridLocation addObject:viewModelTerm];
            counts[viewPoint] = termsAtGridLocation;
        }
    }

    // --- Differentials
    NSMutableArray *differentials = [NSMutableArray new];
    NSMutableDictionary *termCountOffsets = [NSMutableDictionary new];

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
                NSInteger startOffset = [termCountOffsets[modelStartPoint] integerValue];
                NSInteger endOffset = [termCountOffsets[modelEndPoint] integerValue];
                termCountOffsets[modelStartPoint] = @(startOffset + 1);
                termCountOffsets[modelEndPoint] = @(endOffset + 1);

                EXTViewModelDifferential *diff = [EXTViewModelDifferential viewModelDifferentialWithStartLocation:startPoint
                                                                                                       startIndex:startOffset
                                                                                                      endLocation:endPoint
                                                                                                         endIndex:endOffset];
                [differentials addObject:diff];
            }
        }
    }

    self.termCounts[@(self.currentPage)] = counts;
    self.differentials[@(self.currentPage)] = differentials;
}

- (NSArray *)chartView:(EXTChartView *)chartView termCountsInGridRect:(EXTIntRect)gridRect
{
    NSMutableArray *result = [NSMutableArray array];
    [self.termCounts[@(self.currentPage)] enumerateKeysAndObjectsUsingBlock:^(EXTViewModelPoint *point, NSArray *terms, BOOL *stop) {
        EXTIntPoint gridPoint = (EXTIntPoint){.x = point.x, .y = point.y};
        if (EXTIntPointInRect(gridPoint, gridRect)) {
            EXTChartViewTermCountData *data = [EXTChartViewTermCountData new];
            data.location = (EXTIntPoint){.x = point.x, .y = point.y};
            data.count = terms.count;
            [result addObject:data];
        }
    }];

    return result.copy;
}

- (NSArray *)chartView:(EXTChartView *)chartView differentialsInGridRect:(EXTIntRect)gridRect
{
    const NSRect rect = [self.grid convertRectToView:gridRect];

    NSMutableArray *result = [NSMutableArray array];
    for (EXTViewModelDifferential *diff in self.differentials[@(self.currentPage)]) {
        const NSPoint start = [self.grid convertPointToView:diff.startLocation];
        const NSPoint end = [self.grid convertPointToView:diff.endLocation];
        if (lineSegmentOverRect(start, end, rect)) {
            [result addObject:[diff chartViewDifferentialData]];
        }
    }
    return result.copy;
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


@implementation EXTViewModelTerm
+ (instancetype)viewModelTermFromModelTerm:(EXTTerm *)modelTerm /*gridLocation:(EXTIntPoint)gridLocation*/
{
    EXTViewModelTerm *newTerm = [[self class] new];
    if (newTerm) {
        newTerm->_modelTerm = modelTerm;
//        newTerm->_gridLocation = gridLocation;
    }
    return newTerm;
}
@end


@implementation EXTViewModelDifferential
+ (instancetype)viewModelDifferentialWithStartLocation:(EXTIntPoint)startLocation
                                            startIndex:(NSInteger)startIndex
                                           endLocation:(EXTIntPoint)endLocation
                                              endIndex:(NSInteger)endIndex
{
    EXTViewModelDifferential *newDiff = [[self class] new];
    if (newDiff) {
        newDiff->_startLocation = startLocation;
        newDiff->_startIndex = startIndex;
        newDiff->_endLocation = endLocation;
        newDiff->_endIndex = endIndex;
    }
    return newDiff;
}

- (EXTChartViewDifferentialData *)chartViewDifferentialData
{
   return [EXTChartViewDifferentialData chartViewDifferentialDataWithStartLocation:_startLocation
                                                                        startIndex:_startIndex
                                                                       endLocation:_endLocation
                                                                          endIndex:_endIndex];
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
