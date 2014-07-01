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
@class EXTGrid;


@interface EXTChartViewModel : NSObject <EXTChartViewDataSource>
@property (nonatomic, weak) EXTSpectralSequence *sequence;
@property (nonatomic, assign) NSInteger currentPage;
@property (nonatomic, weak) EXTGrid *grid;
@property (nonatomic, weak) id selectedObject;
@property (nonatomic, assign) EXTToolboxTag selectedToolTag;
@property (weak) NSMutableArray *multiplicationAnnotationRules;

- (void)reloadCurrentPage;
@end


@interface EXTViewModelPoint : NSObject <NSCopying> // NSValue with (floating-point) NSPoint?
@property (nonatomic, readonly, assign) NSInteger x;
@property (nonatomic, readonly, assign) NSInteger y;
+ (instancetype)newViewModelPointWithX:(NSInteger)x y:(NSInteger)y;
@end


@interface EXTViewModelDifferential : NSObject
@property (nonatomic, assign) NSPoint start;
@property (nonatomic, assign) NSPoint end;
+ (instancetype)newViewModelDifferentialWithStart:(NSPoint)start end:(NSPoint)end;
@end

@interface EXTViewModelMultAnnotation : NSObject
@property (nonatomic, assign) NSPoint start;
@property (nonatomic, assign) NSPoint end;
+ (instancetype)newViewModelMultAnnotationWithStart:(NSPoint)start end:(NSPoint)end;
@end
