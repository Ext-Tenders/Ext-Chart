//
//  EXTChartView.h
//  Ext Chart
//
//  Created by Michael Hopkins on 7/20/11.
//  Copyright 2011 Harvard University. All rights reserved.
//


#import <Cocoa/Cocoa.h>
#import "EXTChartInteractionType.h"


@class EXTChartView, EXTArtBoard, EXTGrid;
@protocol EXTChartViewDataSource, EXTChartViewDelegate;


@interface EXTChartView : NSView <NSUserInterfaceValidations>
@property (nonatomic, assign) bool showsGrid;
@property (nonatomic, strong) EXTArtBoard *artBoard;
@property (nonatomic, readonly) EXTGrid *grid;
@property (nonatomic, assign) EXTIntRect artBoardGridFrame; // the art board frame in grid coordinate space

@property (nonatomic, assign) EXTChartInteractionType interactionType;
@property (nonatomic, strong) NSColor *highlightColor;
@property (nonatomic, strong) NSColor *selectionColor;

@property (nonatomic, weak) id<EXTChartViewDataSource> dataSource;
@property (nonatomic, weak) id<EXTChartViewDelegate> delegate;

// New chart view
- (void)adjustContentForRect:(NSRect)rect;
- (void)reloadCurrentPage;

// Actions
- (IBAction)zoomToFit:(id)sender;

// Selection
- (void)selectTermAtGridLocation:(EXTIntPoint)gridLocation index:(NSInteger)index;
- (void)removeTermSelection;

- (void)selectDifferentialAtStartLocation:(EXTIntPoint)startLocation index:(NSInteger)index;
- (void)removeDifferentialSelection;

// Util
+ (CGRect)dotBoundingBoxForTermCount:(NSInteger)termCount
                           termIndex:(NSInteger)termIndex
                        gridLocation:(EXTIntPoint)gridLocation
                         gridSpacing:(CGFloat)gridSpacing;
@end


@protocol EXTChartViewDelegate <NSObject>
- (void)chartView:(EXTChartView *)chartView mouseDownAtGridLocation:(EXTIntPoint)gridLocation;
@end


@protocol EXTChartViewDataSource <NSObject>
- (NSArray *)chartView:(EXTChartView *)chartView termCellsInGridRect:(EXTIntRect)gridRect; // an array of EXTChartViewModelTermCell
- (NSArray *)chartView:(EXTChartView *)chartView differentialsInGridRect:(EXTIntRect)gridRect; // an array of EXTChartViewModelDifferential
@end


#pragma mark - Exported variables

extern NSString * const EXTChartViewHighlightColorPreferenceKey;
