//
//  EXTTerm.h
//  Ext Chart
//
//  Created by Michael Hopkins on 7/22/11.
//  Copyright 2011 Harvard University. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "EXTDocument.h"
#import "EXTLocation.h"
#import "EXTMatrix.h"

// forward prototypes for classes in other headers.
@class EXTGrid;

// this class models a cell in the spectral sequence.  it needs to keep track of
// many things, including not just its position but also its cycle/boundary
// filtration, any multiplicative structures present, ...
//
// TODO: for the moment, i'm only even trying to make F2-vector-spaces work. any
// more sophisticated variant of modules is going to take a substantial rewrite.
@interface EXTTerm : NSObject <NSCoding>

    @property(retain) EXTLocation* location; // position on grid
    @property(retain) NSMutableArray* names; // NSObjects with -description
                                             // responders. basis element names.
    @property(retain) NSMutableArray* cycles; // NSArrays of cycle group bases
    @property(retain) NSMutableArray* boundaries; // ...  of bdry group bases
    @property(retain) EXTMatrix *displayBasis; // change of basis matrix, used
                                               // to display in a nonstd basis
    @property(retain) NSMutableArray* displayNames; // labels for display

    // a constructor
    +(instancetype) term:(EXTLocation*)whichLocation
                andNames:(NSMutableArray*)whichNames;
    // and an in-place initializer
    -(instancetype) setTerm:(EXTLocation*)whichLocation
                   andNames:(NSMutableArray*)whichNames;
    // TODO: a direct sum constructor might be nice?

    -(int) size;
    -(int) dimension:(int)whichPage; // useful for drawing
    -(void) computeCycles:(int)whichPage sSeq:(EXTSpectralSequence*)sSeq;
    -(void) computeBoundaries:(int)whichPage sSeq:(EXTSpectralSequence*)sSeq;

    // TODO: here are some other routines that i haven't investigated yet.
    - (void)addSelfToSS:(EXTDocument*)theDocument;
@end