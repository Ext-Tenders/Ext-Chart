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


@class EXTArtBoard, EXTGrid, EXTSpectralSequence;


@protocol EXTChartViewDelegate <NSObject>
    - (void)drawPageNumber:(NSUInteger)pageNumber ll:(NSPoint)lowerLeftCoord ur:(NSPoint)upperRightCoord withSpacing:(CGFloat)gridSpacing;
@end


@interface EXTChartView : NSView <NSUserInterfaceValidations>

@property(nonatomic, assign) bool showGrid;
@property(nonatomic, strong) EXTArtBoard *artBoard;
@property(nonatomic, readonly) EXTGrid *grid;

@property(nonatomic, strong) EXTSpectralSequence *sseq;
@property(nonatomic, weak) id<EXTChartViewDelegate> delegate;
@property(nonatomic, assign) NSUInteger selectedPageIndex;
@property(nonatomic, assign) EXTToolboxTag selectedToolTag;


// Actions
- (IBAction)nextPage:(id)sender;
- (IBAction)previousPage:(id)sender;
- (IBAction)zoomToFit:(id)sender;
- (IBAction)changeTool:(id)sender;
@end

#pragma mark - Exported variables

extern NSString * const EXTChartViewSseqBindingName;
extern NSString * const EXTChartViewSelectedPageIndexBindingName;
