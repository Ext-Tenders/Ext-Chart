//
//  EXTChartView.h
//  Ext Chart
//
//  Created by Michael Hopkins on 7/20/11.
//  Copyright 2011 Harvard University. All rights reserved.
//


#import <Cocoa/Cocoa.h>
#import "EXTToolboxView.h"


@class EXTChartView, EXTArtBoard, EXTGrid;

@protocol EXTChartViewDelegate <NSObject>
    - (NSBezierPath *)chartView:(EXTChartView *)chartView
           highlightPathForTool:(EXTToolboxTag)toolTag
                   gridLocation:(EXTIntPoint)gridLocation;

    - (void)chartView:(EXTChartView *)chartView drawPageInGridRect:(EXTIntRect)gridRect;
    - (void)chartView:(EXTChartView *)chartView mouseDownAtGridLocation:(EXTIntPoint)gridLocation;
@end


@interface EXTChartView : NSView <NSUserInterfaceValidations>

@property(nonatomic, assign) bool showsGrid;
@property(nonatomic, strong) EXTArtBoard *artBoard;
@property(nonatomic, readonly) EXTGrid *grid;
@property(nonatomic, strong) NSColor *highlightColor;
@property(nonatomic, assign) EXTIntRect artBoardGridFrame; // the art board frame in grid coordinate space

@property(nonatomic, weak) id<EXTChartViewDelegate> delegate;
@property(nonatomic, assign) EXTToolboxTag selectedToolTag;

// TODO: I feel like maybe this doesn't belong here.  Shouldn't this be handled
// by the controller somehow?  Hmph.
- (void)resetHighlightPath;

// Actions
- (IBAction)zoomToFit:(id)sender;
@end

#pragma mark - Exported variables

extern NSString * const EXTChartViewHighlightColorPreferenceKey;
