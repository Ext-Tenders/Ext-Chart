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

@interface EXTChartView : NSView <NSUserInterfaceValidations>
@property(nonatomic, assign) bool showsGrid;
@property(nonatomic, strong) EXTArtBoard *artBoard;
@property(nonatomic, readonly) EXTGrid *grid;
@property(nonatomic, strong) NSColor *highlightColor;
@property(nonatomic, assign) EXTIntRect artBoardGridFrame; // the art board frame in grid coordinate space
@property(nonatomic, assign) bool highlightsGridPositionUnderCursor;
@property(nonatomic, assign) bool editingArtBoard;

@property (nonatomic, weak) id<EXTChartViewDataSource> dataSource;
@property(nonatomic, weak) id<EXTChartViewDelegate> delegate;

// TODO: I feel like maybe this doesn't belong here.  Shouldn't this be handled
// by the controller somehow?  Hmph.
- (void)resetHighlightPath;

// Actions
- (IBAction)zoomToFit:(id)sender;
@end


@protocol EXTChartViewDelegate <NSObject>
- (void)chartView:(EXTChartView *)chartView mouseDownAtGridLocation:(EXTIntPoint)gridLocation;
@end


@protocol EXTChartViewDataSource <NSObject>
- (CGLayerRef)chartView:(EXTChartView *)chartView layerForTermCount:(NSInteger)count;
- (NSArray *)chartView:(EXTChartView *)chartView termCountsInGridRect:(EXTIntRect)gridRect; // an array of EXTChartViewTermCountData
- (NSArray *)chartView:(EXTChartView *)chartView differentialsInRect:(NSRect)gridRect; // an array of EXTChartViewDifferentialData
- (NSArray *)chartViewBackgroundRectsForSelectedObject:(EXTChartView *)chartView; // an array of NSRects
- (NSBezierPath *)chartView:(EXTChartView *)chartView highlightPathForToolAtGridLocation:(EXTIntPoint)gridLocation;
@end


@interface EXTChartViewTermCountData : NSObject
@property (nonatomic, assign) EXTIntPoint point;
@property (nonatomic, assign) NSInteger count;
+ (instancetype)chartViewTermCountDataWithCount:(NSInteger)count atGridPoint:(EXTIntPoint)gridPoint;
@end


@interface EXTChartViewDifferentialData : NSObject
@property (nonatomic, assign) NSPoint start;
@property (nonatomic, assign) NSPoint end;
+ (instancetype)chartViewDifferentialDataWithStart:(NSPoint)start end:(NSPoint)end;
@end

#pragma mark - Exported variables

extern NSString * const EXTChartViewHighlightColorPreferenceKey;
