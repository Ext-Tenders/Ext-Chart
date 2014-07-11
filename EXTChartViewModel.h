//
//  EXTChartViewModel.h
//  Ext Chart
//
//  Created by Bavarious on 10/06/2014.
//  Copyright (c) 2014 Harvard University. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EXTChartInteractionType.h"

@class EXTSpectralSequence;
@class EXTTerm;
@class EXTDifferential;
@class EXTGrid;
@class EXTChartViewModelTermCell;
@class EXTChartViewModelDifferential;


@interface EXTChartViewModel : NSObject
@property (nonatomic, weak) EXTSpectralSequence *sequence;

/// An array of EXTChartViewModelTermCell objects.
@property (nonatomic, readonly) NSArray *termCells;

/// An array of EXTViewModelDifferential objects.
@property (nonatomic, readonly) NSArray *differentials;

@property (nonatomic, assign) NSInteger currentPage;
@property (nonatomic, weak) EXTGrid *grid;
@property (nonatomic, assign) EXTChartInteractionType interactionType;

@property (nonatomic, weak) id selectedObject; // TODO: Should this really be readwrite?

- (void)reloadCurrentPage;
- (void)selectObjectAtGridLocation:(EXTIntPoint)gridLocation;
- (EXTChartViewModelTermCell *)termCellAtGridLocation:(EXTIntPoint)gridLocation;
@end


@interface EXTChartViewModelTermCell : NSObject
@property (nonatomic, readonly, assign) EXTIntPoint gridLocation;
@property (nonatomic, readonly, assign) NSInteger totalRank;

/// An array of EXTChartViewModelTerm objects.
@property (nonatomic, readonly, strong) NSArray *terms;
@end


@interface EXTChartViewModelTerm : NSObject
@property (nonatomic, readonly, assign) EXTIntPoint gridLocation;
@property (nonatomic, readonly, strong) EXTTerm *modelTerm;
@property (nonatomic, readonly, weak) EXTChartViewModelTermCell *termCell;
@property (nonatomic, readonly, assign) NSInteger dimension;

/// There’s at most one differential per (term, page).
@property (nonatomic, readonly, weak) EXTChartViewModelDifferential *differential;
@end


@interface EXTChartViewModelDifferential : NSObject
@property (nonatomic, readonly, strong) EXTDifferential *modelDifferential;
@property (nonatomic, readonly, strong) EXTChartViewModelTerm *startTerm;
@property (nonatomic, readonly, strong) EXTChartViewModelTerm *endTerm;

/// An array of EXTChartViewModelDifferentialLine objects.
@property (nonatomic, readonly, copy) NSArray *lines;
@end


@interface EXTChartViewModelDifferentialLine : NSObject
@property (nonatomic, readonly, assign) NSInteger startIndex;
@property (nonatomic, readonly, assign) NSInteger endIndex;
@end
