//
//  EXTTerm.h
//  Ext Chart
//
//  Created by Michael Hopkins on 7/22/11.
//  Copyright 2011 Harvard. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "EXTDocument.h"

// forward prototypes for classes in other headers.
@class EXTPair;
@class EXTGrid;

// this class models a cell in the spectral sequence.  it needs to keep track of
// many things, including not just its position but also its cycle/boundary
// filtration, any multiplicative structures present, ...
//
// TODO: for the moment, i'm only even trying to make vector spaces work. any
// more sophisticated variant of modules is going to take a substantial rewrite.
@interface EXTTerm : NSObject <NSCoding>
    {
        EXTPair* location;          // position on grid
        NSMutableArray* names;      // contains NSString's, basis element names
        // TODO: this next item means we need to understand some kind of linear
        // algebra, and how to name things inside a vector space.
        NSMutableArray* cycles;     // contains NSArray's of Elements, which are
                                    // bases for future pages
        NSMutableArray* boundaries; // contains NSArray's of Elements, which are
                                    // the subspaces of boundaries
        
        // TODO: add some list that keeps track of multiplicative structures
    }

    @property(retain) EXTPair* location;
    @property(retain) NSMutableArray* names;
    @property(retain) NSMutableArray* cycles;
    @property(retain) NSMutableArray* boundaries;

    // a constructor
    +(id) newTerm:(EXTPair*)whichLocation andNames:(NSMutableArray*)whichNames;
    +(id) term:(EXTPair*)whichLocation andNames:(NSMutableArray*)whichNames;
    // and an in-place constructor
    -(id) setTerm:(EXTPair*)whichLocation andNames:(NSMutableArray*)whichNames;
    // TODO: a direct sum constructor might be nice?


    // this gets called when the Term tool receives a click event
    +(id) dealWithClick:(NSPoint)location document:(EXTDocument*)document;

    -(int) dimension:(int)whichPage; // useful for drawing
    -(void) computeCycles:(int)whichPage
        differentialArray:(NSMutableArray*)differentials;
    -(void) computeBoundaries:(int)whichPage
        differentialArray:(NSMutableArray*)differentials;

    // TODO: here are some other routines that i haven't investigated yet.
    // TODO: this drawing code must be offloaded into some other module!!
    -(void)drawWithSpacing:(CGFloat)spacing page:(int)page;
    + (NSBezierPath *)makeHighlightPathAtPoint:(NSPoint)point onGrid:(EXTGrid *)theGrid onPage:(NSInteger)page;
    - (void)addSelfToSS:(EXTDocument*)theDocument;
@end