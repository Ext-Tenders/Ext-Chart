//
//  EXTDocument.h
//  Ext Chart
//
//  Created by Michael Hopkins on 7/20/11.
//  Copyright 2011 LH Productions. All rights reserved.
//


#import <Cocoa/Cocoa.h>


@class EXTGrid, EXTArtBoard, EXTMultiplicationTables, EXTPair, EXTTerm, EXTDifferential;


@interface EXTDocument : NSDocument
    @property(nonatomic, strong) NSMutableArray *terms;
    @property(nonatomic, strong) NSMutableArray *differentials;
    @property(nonatomic, strong) EXTMultiplicationTables *multTables;

    @property(nonatomic, assign) CGFloat artboardRectX;
    @property(nonatomic, assign) NSUInteger maxPage;
    @property(nonatomic, strong) EXTArtBoard *theArtBoard;
    @property(nonatomic, strong) EXTGrid *theGrid;

    - (void)randomize;
    - (void)drawPagesUpTo:(NSUInteger)pageNumber;
    - (void)drawPageNumber:(NSUInteger)pageNumber ll:(EXTPair*)lowerLeftCoord ur:(EXTPair*)upperRightCoord withSpacing:(CGFloat)gridSpacing;

    - (EXTTerm*)findTerm:(EXTPair*)loc;
    - (EXTDifferential*)findDifflWithSource:(EXTPair*)loc onPage:(int)page;
    - (EXTDifferential*)findDifflWithTarget:(EXTPair*)loc onPage:(int)page;
@end

// Notes: need something to specify the size (width, height) of the document, origin location, serre or adams convention?  