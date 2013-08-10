//
//  EXTChartView.h
//  Ext Chart
//
//  Created by Michael Hopkins on 7/20/11.
//  Copyright 2011 Harvard University. All rights reserved.
//


#import <Cocoa/Cocoa.h>

typedef enum : NSInteger {
    _EXTSelectionToolTag = 1,
    _EXTArtboardToolTag = 2,
    _EXTGeneratorToolTag = 3,
    _EXTDifferentialToolTag = 4,
    _EXTEraseToolTag = 5,
    _EXTMarqueeToolTag = 6,
    _EXTToolTagCount
} EXTToolboxTag;


@class EXTChartView, EXTArtBoard, EXTGrid, EXTSpectralSequence;
@protocol EXTLocation;

@protocol EXTChartViewDelegate <NSObject>
    - (void)chartView:(EXTChartView *)chartView willDisplayPage:(NSUInteger)pageNumber;

    - (void)chartView:(EXTChartView *)chartView
       drawPageNumber:(NSUInteger)pageNumber
            lowerLeft:(NSPoint)lowerLeftCoord
           upperRight:(NSPoint)upperRightCoord
          withSpacing:(CGFloat)gridSpacing;

    - (Class<EXTLocation>)indexClassForChartView:(EXTChartView *)chartView;

    - (void)chartView:(EXTChartView *)chartView mouseDownAtGridLocation:(NSPoint)gridLocation;
@end


@interface EXTChartView : NSView <NSUserInterfaceValidations>

@property(nonatomic, assign) bool showsGrid;
@property(nonatomic, strong) EXTArtBoard *artBoard;
@property(nonatomic, readonly) EXTGrid *grid;
@property(nonatomic, strong) NSColor *highlightColor;

@property(nonatomic, weak) id<EXTChartViewDelegate> delegate;
@property(nonatomic, assign) NSUInteger selectedPageIndex;
@property(nonatomic, assign) EXTToolboxTag selectedToolTag;

- (void)displaySelectedPage;

// Actions
- (IBAction)nextPage:(id)sender;
- (IBAction)previousPage:(id)sender;
- (IBAction)zoomToFit:(id)sender;
- (IBAction)changeTool:(id)sender;
@end

#pragma mark - Exported variables

extern NSString * const EXTChartViewSelectedPageIndexBindingName;
