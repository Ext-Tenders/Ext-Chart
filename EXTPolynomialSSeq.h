//
//  EXTPolynomialSSeq.h
//  Ext Chart
//
//  Created by Eric Peterson on 7/6/13.
//  Copyright (c) 2013 Harvard University. All rights reserved.
//

#import "EXTSpectralSequence.h"
#import "EXTMultiplicationTables.h"

// sometimes (oftentimes, actually), we know that a spectral sequence has an E1-
// page which is presented by a polynomial algebra.  this allows us to make
// some dramatic simplifications to how things are stored and computed.
@interface EXTPolynomialSSeq : EXTSpectralSequence

@property(strong,readonly) NSMutableArray* names;
@property(strong,readonly) NSMutableArray* locations;
@property(strong,readonly) NSMutableArray* upperBounds;

+(EXTPolynomialSSeq*) sSeqWithUnit:(Class<EXTLocation>)locClass;

-(void) addPolyClass:(NSString*)name location:(EXTLocation*)loc upTo:(int)bound;
-(void) resizePolyClass:(NSString*)name upTo:(int)newBound;

-(EXTMatrix*) productWithLeft:(EXTLocation*)left right:(EXTLocation*)right;

// performs an irreversible upcast to EXTSpectralSequence
-(EXTSpectralSequence*) unspecialize;

@end
