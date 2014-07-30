//
//  EXTChartView.h
//  Ext Chart
//
//  Created by Michael Hopkins on 7/20/11.
//  Copyright 2011 Harvard University. All rights reserved.
//

@import Cocoa;

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

@property (nonatomic, weak) id selectedObject;
@property (nonatomic, assign) bool inLiveMagnify;
@property (nonatomic, assign, getter=isExportOnly) bool exportOnly;

// New chart view
- (void)updateVisibleRect;
- (void)updateRect:(NSRect)rect;
- (void)reloadCurrentPage;

// Actions
- (IBAction)zoomToFit:(id)sender;

// Util
+ (CGRect)dotBoundingBoxForCellRank:(NSInteger)cellRank
                          termIndex:(NSInteger)termIndex
                       gridLocation:(EXTIntPoint)gridLocation
                        gridSpacing:(NSInteger)gridSpacing;
@end


@protocol EXTChartViewDelegate <NSObject>
- (void)chartView:(EXTChartView *)chartView mouseDownAtGridLocation:(EXTIntPoint)gridLocation;
@end


@protocol EXTChartViewDataSource <NSObject>

- (NSArray *)chartView:(EXTChartView *)chartView termCellsInGridRect:(EXTIntRect)gridRect; // an array of EXTChartViewModelTermCell
- (NSArray *)chartView:(EXTChartView *)chartView differentialsInGridRect:(EXTIntRect)gridRect; // an array of EXTChartViewModelDifferential
- (NSArray *)chartView:(EXTChartView *)chartView multAnnotationsInRect:(EXTIntRect)gridRect; // an array of {style, array of EXTChartViewMultAnnotationData}

@end

#pragma mark - Exported variables

extern NSString * const EXTChartViewHighlightColorPreferenceKey;
extern NSString * const EXTChartViewSelectionColorPreferenceKey;
