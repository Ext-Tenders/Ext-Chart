//
//  EXTChartViewModel.h
//  Ext Chart
//
//  Created by Bavarious on 10/06/2014.
//  Copyright (c) 2014 Harvard University. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EXTChartView.h"


@class EXTSpectralSequence;
@class EXTTerm;
@class EXTGrid;


@interface EXTChartViewModel : NSObject <EXTChartViewDataSource>
@property (nonatomic, weak) EXTSpectralSequence *sequence;
@property (nonatomic, assign) NSInteger currentPage;
@property (nonatomic, weak) EXTGrid *grid;

- (void)reloadCurrentPage;
@end


@interface EXTViewModelPoint : NSObject <NSCopying> // NSValue with (floating-point) NSPoint?
@property (nonatomic, readonly, assign) NSInteger x;
@property (nonatomic, readonly, assign) NSInteger y;

+ (instancetype)viewModelPointWithX:(NSInteger)x y:(NSInteger)y;
@end


@interface EXTViewModelTerm : NSObject
@property (nonatomic, readonly, strong) EXTTerm *modelTerm;
//@property (nonatomic, readonly, assign) EXTIntPoint gridLocation;

+ (instancetype)viewModelTermFromModelTerm:(EXTTerm *)modelTerm;
//+ (instancetype)viewModelTermFromModelTerm:(EXTTerm *)modelTerm gridLocation:(EXTIntPoint)gridLocation;
@end


@interface EXTViewModelDifferential : NSObject
@property (nonatomic, assign) EXTIntPoint startLocation;
@property (nonatomic, assign) NSInteger startIndex;
@property (nonatomic, assign) EXTIntPoint endLocation;
@property (nonatomic, assign) NSInteger endIndex;

+ (instancetype)viewModelDifferentialWithStartLocation:(EXTIntPoint)startLocation
                                            startIndex:(NSInteger)startIndex
                                           endLocation:(EXTIntPoint)endLocation
                                              endIndex:(NSInteger)endIndex;

- (EXTChartViewDifferentialData *)chartViewDifferentialData;
@end
