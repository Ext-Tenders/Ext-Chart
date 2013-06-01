//
//  EXTView.h
//  Ext Chart
//
//  Created by Michael Hopkins on 7/20/11.
//  Copyright 2011 Harvard University. All rights reserved.
//


#import <Cocoa/Cocoa.h>
@class EXTScrollView, EXTArtBoard, EXTGrid, EXTDocument, EXTToolPaletteController, EXTTerm, EXTDifferential, EXTSpectralSequence;

@protocol EXTViewDelegate <NSObject>
    - (void)drawPageNumber:(NSUInteger)pageNumber ll:(NSPoint)lowerLeftCoord ur:(NSPoint)upperRightCoord withSpacing:(CGFloat)gridSpacing;
@end


@interface EXTView : NSView {
	BOOL showGrid;
	BOOL showPages;
	BOOL editMode;
	BOOL editingArtBoards;
	BOOL highlighting;

	// the gridspacing ivar should be taken out.   It's currently used in some of the data drawing code, which should be moved elsewhere.
	CGFloat gridSpacing;
	int pageInView;
	
	EXTArtBoard *artBoard;
	IBOutlet EXTGrid *_grid;
	NSMutableArray *pages;
	
	NSRect highlightRect;    // make this private?
	NSColor *highlightRectColor;  // if this is not customizable, it should be a constant.   I couldn't make it work as a static or extern...
		
	NSTrackingArea *trackingArea;
	
	Class currentTool;  // simple assignment?
	NSBezierPath *hightlightPath;
}



@property(assign) CGFloat gridSpacing; 
@property(nonatomic, assign) BOOL showGrid;
@property(assign) BOOL editMode, showPages, editingArtBoards, highlighting;
@property(strong) EXTArtBoard *artBoard;
@property(strong) EXTGrid *_grid;
@property(strong) NSBezierPath *highlightPath;
@property(strong) NSMutableArray *pages;


@property(nonatomic, strong) EXTSpectralSequence *sseq; // TODO: this should evolve to a copy property in order to avoid side effects
@property(nonatomic, weak) id<EXTViewDelegate> delegate;
@property(nonatomic, assign) int pageInView;



- (NSPoint) convertToGridCoordinates:(NSPoint)pixelLoc;
- (NSPoint) convertToPixelCoordinates:(NSPoint) gridLoc;

// paging and zooming

- (IBAction)nextPage:(id)sender;
- (IBAction)previousPage:(id)sender;
- (IBAction)computeHomology:(id)sender;

- (IBAction)fitWidth:(id)sender;
- (IBAction)fitHeight:(id)sender;
- (IBAction)setGridToDefaults:(id)sender;

- (void)toolSelectionDidChange;
- (void)resetHighlightRectAtLocation:(NSPoint)location;

@end

// I'm putting the grid stuff in here, temporarily.   We can break it out into the grid object as we add more functionality later.  