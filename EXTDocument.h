//
//  EXTDocument.h
//  Ext Chart
//
//  Created by Michael Hopkins on 7/20/11.
//  Copyright 2011 LH Productions. All rights reserved.
//


#import <Cocoa/Cocoa.h>
#import "EXTView.h"
@class EXTGrid, EXTArtBoard, EXTMultiplicationTables;

@interface EXTDocument : NSDocument
{
	// file data
    NSMutableArray *terms;
    NSMutableArray *differentials;
    EXTMultiplicationTables *multTables;
	
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
@property(nonatomic, assign) NSUInteger maxPage;
@property(strong) EXTArtBoard *theArtBoard;
@property(strong) EXTGrid *theGrid;
@property(strong) NSMutableArray *terms;
@property(strong) NSMutableArray *differentials;
@property(strong) EXTMultiplicationTables *multTables;

-(void)randomize;
-(void)drawPagesUpTo: (NSUInteger) pageNumber;
-(void) drawPageNumber:(NSUInteger)pageNumber ll:(EXTPair*)lowerLeftCoord ur:(EXTPair*)upperRightCoord withSpacing:(CGFloat)gridSpacing;
//- (NSUInteger) maxPage;

-(EXTTerm*) findTerm:(EXTPair*)loc;
-(EXTDifferential*) findDifflWithSource:(EXTPair*)loc onPage:(int)page;
-(EXTDifferential*) findDifflWithTarget:(EXTPair*)loc onPage:(int)page;

@end

// Notes: need something to specify the size (width, height) of the document, origin location, serre or adams convention?  