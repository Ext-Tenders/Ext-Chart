//
//  EXTChartView.h
//  Ext Chart
//
//  Created by Michael Hopkins on 7/20/11.
//  Copyright 2011 Harvard University. All rights reserved.
//


#import <Cocoa/Cocoa.h>
@class EXTScrollView, EXTArtBoard, EXTGrid, EXTDocument, EXTToolPaletteController, EXTTerm, EXTDifferential, EXTSpectralSequence;

@protocol EXTChartViewDelegate <NSObject>
    - (void)drawPageNumber:(NSUInteger)pageNumber ll:(NSPoint)lowerLeftCoord ur:(NSPoint)upperRightCoord withSpacing:(CGFloat)gridSpacing;
@end


@interface EXTChartView : NSView {
	BOOL showGrid;
	BOOL showPages;
	BOOL editMode;
	BOOL highlighting;

	NSRect highlightRect;    // make this private?
	NSColor *highlightRectColor;  // if this is not customizable, it should be a constant.   I couldn't make it work as a static or extern...
		
	NSTrackingArea *trackingArea;
	
	Class currentTool;  // simple assignment?
	NSBezierPath *hightlightPath;
}



@property(nonatomic, assign) BOOL showGrid;
@property(nonatomic, assign) BOOL editMode, showPages, editingArtBoards, highlighting;
@property(strong) EXTArtBoard *artBoard;
@property(nonatomic, readonly) EXTGrid *grid;
@property(strong) NSBezierPath *highlightPath;

@property(nonatomic, strong) EXTSpectralSequence *sseq; // TODO: this should evolve to a copy property in order to avoid side effects
@property(nonatomic, weak) id<EXTChartViewDelegate> delegate;
@property(nonatomic, assign) NSUInteger selectedPageIndex;



- (NSPoint) convertToGridCoordinates:(NSPoint)pixelLoc;
- (NSPoint) convertToPixelCoordinates:(NSPoint) gridLoc;

// paging and zooming

- (IBAction)nextPage:(id)sender;
- (IBAction)previousPage:(id)sender;
- (IBAction)computeHomology:(id)sender;

- (IBAction)zoomToFit:(id)sender;
- (IBAction)setGridToDefaults:(id)sender;

- (void)toolSelectionDidChange;
- (void)resetHighlightRectAtLocation:(NSPoint)location;

@end

// I'm putting the grid stuff in here, temporarily.   We can break it out into the grid object as we add more functionality later.

#pragma mark - Exported variables

extern NSString * const EXTChartViewSseqBindingName;
extern NSString * const EXTChartViewSelectedPageIndexBindingName;
