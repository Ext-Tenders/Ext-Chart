//
//  EXTDocument.h
//  Ext Chart
//
//  Created by Michael Hopkins on 7/20/11.
//  Copyright 2011 LH Productions. All rights reserved.
//


#import <Cocoa/Cocoa.h>
#import "EXTView.h"
@class EXTPage, EXTGrid, EXTArtBoard;

@interface EXTDocument : NSDocument
{
	// file data
    NSMutableArray *terms;
    NSMutableArray *differentials;
	
	// view configuration
	CGFloat gridSpacing;
	CGFloat gridScalingFactor;
	NSSize extDocumentSize;
	NSPoint extDocumentOrigin;
//	extern CGFloat gridSpacing;
//	extern NSRect canvasRect;
	NSColor *gridLineColor;
	NSColor *emphasGridLineColor;
	
	CGFloat artboardRectX;
	
	IBOutlet EXTView *extview;

	IBOutlet EXTGrid *theGrid;
	EXTArtBoard *theArtBoard;
	NSUInteger maxPage;
}

@property(assign) CGFloat artboardRectX;
@property(assign) NSUInteger maxPage;
@property(retain) EXTArtBoard *theArtBoard;
@property(retain) EXTGrid *theGrid;
@property(retain) NSMutableArray *terms;
@property(retain) NSMutableArray *differentials;

-(void)drawPageNumber: (NSUInteger) pageNumber;
-(void)drawPagesUpTo: (NSUInteger) pageNumber;
-(void) drawPageNumber:(NSUInteger)pageNumber ll:(EXTPair*)lowerLeftCoord ur:(EXTPair*)upperRightCoord withSpacing:(CGFloat)gridSpacing;
//- (NSUInteger) maxPage;


@end

// Notes: need something to specify the size (width, height) of the document, origin location, serre or adams convention?  