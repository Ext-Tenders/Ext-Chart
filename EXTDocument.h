//
//  EXTDocument.h
//  Ext Chart
//
//  Created by Michael Hopkins on 7/20/11.
//  Copyright 2011 Harvard University. All rights reserved.
//


#import <Cocoa/Cocoa.h>
#import "EXTLocation.h"

@class EXTDocumentWindowController;
@class EXTSpectralSequence;


@interface EXTDocument : NSDocument
    @property(nonatomic, strong) EXTSpectralSequence *sseq;
    @property(nonatomic, strong) NSMutableArray *marquees; // an array of EXTMarquee objects

    // User interface configuration
    @property(nonatomic, strong) NSColor *gridColor;
    @property(nonatomic, strong) NSColor *gridEmphasisColor;
    @property(nonatomic, strong) NSColor *axisColor;
    @property(nonatomic, strong) NSColor *highlightColor;
    @property(nonatomic, strong) NSColor *selectionColor;
    @property(nonatomic, assign) NSInteger gridSpacing;
    @property(nonatomic, assign) NSInteger gridEmphasisSpacing;
    @property(nonatomic, assign) EXTIntRect artBoardGridFrame;
    @property(nonatomic, readonly) EXTDocumentWindowController *mainWindowController;

    // array of dictionaries: {"style", "enabled", "location", "vector"}
    @property(nonatomic, strong) NSMutableArray *multiplicationAnnotations;
@end

// Notes: need something to specify the size (width, height) of the document, origin location, serre or adams convention?
