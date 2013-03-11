//
//  EXTView.h
//  Ext Chart
//
//  Created by Michael Hopkins on 7/20/11.
//  Copyright 2011 Harvard. All rights reserved.
//


#import <Cocoa/Cocoa.h>
@class EXTPair, EXTScrollView, EXTArtBoard, EXTGrid, EXTDocument, EXTToolPaletteController, EXTTerm, EXTdifferential; 


@interface EXTView : NSView {
	EXTDocument *delegate; // the EXTDocument
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
@property(assign) BOOL showGrid, editMode, showPages, editingArtBoards, highlighting;
@property(retain) EXTArtBoard *artBoard;
@property(retain) EXTGrid *_grid;
@property(retain) NSBezierPath *highlightPath;
@property(retain) NSMutableArray *pages;


// this is an exception to the usual "retain" for objects, since the document and the view are always
// cretaed together
// http://en.wikibooks.org/wiki/Programming_Mac_OS_X_with_Cocoa_for_Beginners/Wikidraw%27s_view_class
@property(assign) id delegate;
@property(assign) int pageInView;



- (EXTPair*) convertToGridCoordinates:(NSPoint)pixelLoc;
- (NSPoint) convertToPixelCoordinates:(EXTPair*) gridLoc;

// paging and zooming

- (IBAction)nextPage:(id)sender;
- (IBAction)previousPage:(id)sender;
- (IBAction)computeHomology:(id)sender;

- (IBAction)fitWidth:(id)sender;
- (IBAction)fitHeight:(id)sender;
- (IBAction)setGridToDefaults:(id)sender;

- (void)toolSelectionDidChange;
- (void)resetHighlightRectAtLocation:(NSPoint)location;

- (IBAction) randomGroups:(id)sender;



@end

// I'm putting the grid stuff in here, temporarily.   We can break it out into the grid object as we add more functionality later.  