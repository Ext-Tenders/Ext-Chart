//
//  EXTTerm.h
//  Ext Chart
//
//  Created by Michael Hopkins on 7/22/11.
//  Copyright 2011 Harvard University. All rights reserved.
//

@import Foundation;

#import "EXTDocument.h"
#import "EXTLocation.h"
#import "EXTMatrix.h"

// this class models a cell in the spectral sequence.  it needs to keep track of
// many things, including not just its position but also its cycle/boundary
// filtration, any multiplicative structures present, ...
@interface EXTTerm : NSObject <NSCoding>

    @property(retain) EXTLocation* location; // position on grid
    @property(retain) NSMutableArray* names; // NSObjects with -description
                                             // responders. basis element names.
    @property(retain) NSMutableArray* cycles; // EXTMatrixs of cycle group bases
    @property(retain) NSMutableArray* boundaries; // ...  of bdry group bases
    @property(retain) NSMutableArray* homologyReps; // of homology dicts.
    @property(retain) EXTMatrix *displayBasis; // change of basis matrix, used
                                               // to display in a nonstd basis
    @property(retain) NSMutableArray* displayNames; // labels for display

    // a constructor
    +(instancetype) term:(EXTLocation*)whichLocation
                andNames:(NSMutableArray*)whichNames;
    // and an in-place initializer
    -(instancetype) setTerm:(EXTLocation*)whichLocation
                   andNames:(NSMutableArray*)whichNames;

    // useful for drawing
    -(int) size;
    -(int) dimension:(int)whichPage;
    -(void) updateDataForPage:(int)whichPage
                       inSSeq:(EXTSpectralSequence*)sSeq
             inCharacteristic:(int)characteristic;

    // TODO: here are some other routines that i haven't investigated yet.
    - (void)addSelfToSS:(EXTDocument*)theDocument;

    -(NSString*) nameForVector:(NSArray*)vector;
@end