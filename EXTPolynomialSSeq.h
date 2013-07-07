//
//  EXTPolynomialSSeq.h
//  Ext Chart
//
//  Created by Eric Peterson on 7/6/13.
//  Copyright (c) 2013 Harvard University. All rights reserved.
//

#import "EXTSpectralSequence.h"

// sometimes (oftentimes, actually), we know that a spectral sequence has an E1-
// page which is presented by a polynomial algebra.  this allows us to make
// some dramatic simplifications to how things are stored and computed.
@interface EXTPolynomialSSeq : EXTSpectralSequence {
    NSMutableArray *names;
    NSMutableArray *locations;
    NSMutableArray *upperBounds;
}

-(EXTSpectralSequence*) unspecialize;

// add a polynomial class
// resize a polynomial class
// build the multiplication table for a pair of locations

@end

/*

 EXTTerms should have names which aren't strings but "tags".  each tag should be
 either a list or a dictionary or something of pairs of base class + exponent.
 multiplication should act by iterating through and adding these lists together.
 
 for robustness, a nil entry in a tag should be thought of as zero, so that when
 introducing a new class we don't have to go back and add a bunch of labels to
 the existing tags.

*/