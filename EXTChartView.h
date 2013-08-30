//
//  EXTChartView.h
//  Ext Chart
//
//  Created by Michael Hopkins on 7/20/11.
//  Copyright 2011 Harvard University. All rights reserved.
//


#import <Cocoa/Cocoa.h>

typedef enum : NSInteger {
    _EXTGeneratorToolTag = 1,
    _EXTDifferentialToolTag = 2,
    _EXTMultiplicativeStructure = 3,
    _EXTArtboardToolTag = 4,
    _EXTMarqueeToolTag = 5,
    _EXTToolTagCount
} EXTToolboxTag;


@class EXTChartView, EXTArtBoard, EXTGrid, EXTSpectralSequence;
@protocol EXTLocation;

@protocol EXTChartViewDelegate <NSObject>
    - (void)chartView:(EXTChartView *)chartView willDisplayPage:(NSUInteger)pageNumber;

    - (NSBezierPath *)chartView:(EXTChartView *)chartView
           highlightPathForTool:(EXTToolboxTag)toolTag
                           page:(NSUInteger)page
                   gridLocation:(EXTIntPoint)gridLocation;

    - (void)chartView:(EXTChartView *)chartView
       drawPageNumber:(NSUInteger)pageNumber
           inGridRect:(EXTIntRect)gridRect;

    - (void)chartView:(EXTChartView *)chartView mouseDownAtGridLocation:(EXTIntPoint)gridLocation;

    - (void)pageChangedIn:(EXTChartView*)chartView;
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
@end

#pragma mark - Exported variables

extern NSString * const EXTChartViewSelectedPageIndexBindingName;
extern NSString * const EXTChartViewHighlightColorPreferenceKey;
