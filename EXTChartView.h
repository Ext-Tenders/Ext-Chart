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


@class EXTScrollView, EXTArtBoard, EXTGrid, EXTDocument, EXTToolPaletteController, EXTTerm, EXTDifferential, EXTSpectralSequence;


@protocol EXTChartViewDelegate <NSObject>
    - (void)drawPageNumber:(NSUInteger)pageNumber ll:(NSPoint)lowerLeftCoord ur:(NSPoint)upperRightCoord withSpacing:(CGFloat)gridSpacing;
@end


@interface EXTChartView : NSView <NSUserInterfaceValidations> {
	BOOL highlighting;

	NSRect highlightRect;    // make this private?
	NSColor *highlightRectColor;  // if this is not customizable, it should be a constant.   I couldn't make it work as a static or extern...
		
	NSTrackingArea *trackingArea;
	
	NSBezierPath *hightlightPath;
}



@property(nonatomic, assign) bool showGrid;
@property(nonatomic, assign) BOOL highlighting;
@property(strong) EXTArtBoard *artBoard;
@property(nonatomic, readonly) EXTGrid *grid;
@property(strong) NSBezierPath *highlightPath;

@property(nonatomic, strong) EXTSpectralSequence *sseq; // TODO: this should evolve to a copy property in order to avoid side effects
@property(nonatomic, weak) id<EXTChartViewDelegate> delegate;
@property(nonatomic, assign) NSUInteger selectedPageIndex;
@property(nonatomic, assign) EXTToolboxTag selectedToolTag;


- (NSPoint) convertToGridCoordinates:(NSPoint)pixelLoc;
- (NSPoint) convertToPixelCoordinates:(NSPoint) gridLoc;

// paging and zooming

- (IBAction)nextPage:(id)sender;
- (IBAction)previousPage:(id)sender;
- (IBAction)computeHomology:(id)sender;

- (IBAction)zoomToFit:(id)sender;
- (IBAction)setGridToDefaults:(id)sender;

- (IBAction)changeTool:(id)sender;

- (void)resetHighlightRectAtLocation:(NSPoint)location;

@end

// I'm putting the grid stuff in here, temporarily.   We can break it out into the grid object as we add more functionality later.

#pragma mark - Exported variables

extern NSString * const EXTChartViewSseqBindingName;
extern NSString * const EXTChartViewSelectedPageIndexBindingName;
