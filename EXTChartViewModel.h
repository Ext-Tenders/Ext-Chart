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


@interface EXTChartViewModel : NSObject
@property (nonatomic, weak) EXTSpectralSequence *sequence;

/// An array of EXTChartViewModelTermCell objects.
@property (nonatomic, readonly) NSArray *termCells;

/// An array of EXTViewModelDifferential objects.
@property (nonatomic, readonly) NSArray *differentials;

@property (nonatomic, assign) NSInteger currentPage;
@property (nonatomic, weak) EXTGrid *grid;
@property (nonatomic, assign) EXTChartInteractionType interactionType;

@property (nonatomic, weak) id selectedObject;

- (void)reloadCurrentPage;
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
@property (nonatomic, readonly, assign) NSInteger dimension;

+ (instancetype)viewModelTermFromModelTerm:(EXTTerm *)modelTerm gridLocation:(EXTIntPoint)gridLocation;
@end


@interface EXTChartViewModelDifferential : NSObject
@property (nonatomic, readonly, strong) EXTChartViewModelTerm *startTerm;
@property (nonatomic, readonly, assign) NSInteger startIndex;
@property (nonatomic, readonly, strong) EXTChartViewModelTerm *endTerm;
@property (nonatomic, readonly, assign) NSInteger endIndex;

+ (instancetype)viewModelDifferentialWithStartTerm:(EXTChartViewModelTerm *)startTerm
                                        startIndex:(NSInteger)startIndex
                                           endTerm:(EXTChartViewModelTerm *)endTerm
                                        endIndex:(NSInteger)endIndex;
@end
