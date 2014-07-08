//
//  EXTChartView.h
//  Ext Chart
//
//  Created by Michael Hopkins on 7/20/11.
//  Copyright 2011 Harvard University. All rights reserved.
//


#import <Cocoa/Cocoa.h>
#import "EXTToolboxTag.h"

@class EXTChartView, EXTArtBoard, EXTGrid;
@protocol EXTChartViewDataSource, EXTChartViewDelegate;


// Objects in the chart view that can be highlighted or selected
typedef NS_ENUM(NSInteger, EXTChartViewInteractionType)
{
    EXTChartViewInteractionTypeNone = 0,
    EXTChartViewInteractionTypeTerm = 1,
    EXTChartViewInteractionTypeDifferential = 2,
    EXTChartViewInteractionTypeMultiplicativeStructure = 3,
    EXTChartViewInteractionTypeArtBoard = 4,
};


@interface EXTChartView : NSView <NSUserInterfaceValidations>
@property (nonatomic, assign) bool showsGrid;
@property (nonatomic, strong) EXTArtBoard *artBoard;
@property (nonatomic, readonly) EXTGrid *grid;
@property (nonatomic, assign) EXTIntRect artBoardGridFrame; // the art board frame in grid coordinate space

@property (nonatomic, assign) EXTChartViewInteractionType interactionType; // FIXME: should encompass editingArtBoard, too
@property (nonatomic, strong) NSColor *highlightColor;

@property (nonatomic, weak) id<EXTChartViewDataSource> dataSource;
@property (nonatomic, weak) id<EXTChartViewDelegate> delegate;

// New chart view
- (void)adjustContentForRect:(NSRect)rect;
- (void)reloadCurrentPage;

// Actions
- (IBAction)zoomToFit:(id)sender;

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
- (NSArray *)chartView:(EXTChartView *)chartView termCountsInGridRect:(EXTIntRect)gridRect; // an array of EXTChartViewTermCountData
- (NSArray *)chartView:(EXTChartView *)chartView differentialsInGridRect:(EXTIntRect)gridRect; // an array of EXTChartViewDifferentialData
@end


@interface EXTChartViewTermCountData : NSObject
/// Location in grid coordinates.
@property (nonatomic, assign) EXTIntPoint location;

/// Number of terms in a given grid location.
@property (nonatomic, assign) NSInteger count;

+ (instancetype)chartViewTermCountDataWithCount:(NSInteger)count location:(EXTIntPoint)location;
@end


@interface EXTChartViewDifferentialData : NSObject
/// Start endpoint in grid coordinates.
@property (nonatomic, assign) EXTIntPoint startLocation;

/// If several terms are present in startLocation, 0-based index of which of those terms this differential refers to.
@property (nonatomic, assign) NSInteger startIndex;

/// End endpoint in grid coordinates.
@property (nonatomic, assign) EXTIntPoint endLocation;

/// If several terms are present in startLocation, 0-based index of which of those terms this differential refers to.
@property (nonatomic, assign) NSInteger endIndex;

+ (instancetype)chartViewDifferentialDataWithStartLocation:(EXTIntPoint)startLocation
                                                startIndex:(NSInteger)startIndex
                                               endLocation:(EXTIntPoint)endLocation
                                                  endIndex:(NSInteger)endIndex;
@end

#pragma mark - Exported variables

extern NSString * const EXTChartViewHighlightColorPreferenceKey;
