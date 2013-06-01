//
//  EXTDocument.h
//  Ext Chart
//
//  Created by Michael Hopkins on 7/20/11.
//  Copyright 2011 LH Productions. All rights reserved.
//


#import <Cocoa/Cocoa.h>
#import "EXTLocation.h"
#import "EXTSpectralSequence.h"

@class EXTGrid, EXTArtBoard, EXTMultiplicationTables, EXTTerm, EXTDifferential;


@interface EXTDocument : NSDocument
    @property(nonatomic, strong) EXTSpectralSequence *sseq;

    @property(nonatomic, assign) CGFloat artboardRectX;
    @property(nonatomic, assign) NSUInteger maxPage;
    @property(nonatomic, strong) EXTArtBoard *theArtBoard;
    @property(nonatomic, strong) EXTGrid *theGrid;

    - (void)randomize;
    - (void)drawPagesUpTo:(NSUInteger)pageNumber;
    - (void)drawPageNumber:(NSUInteger)pageNumber ll:(NSPoint)lowerLeftCoord ur:(NSPoint)upperRightCoord withSpacing:(CGFloat)gridSpacing;

@end

// Notes: need something to specify the size (width, height) of the document, origin location, serre or adams convention?
