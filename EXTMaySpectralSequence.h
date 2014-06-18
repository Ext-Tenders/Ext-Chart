//
//  EXTMaySpectralSequence.h
//  Ext Chart
//
//  Created by Eric Peterson on 7/9/13.
//  Copyright (c) 2013 Harvard University. All rights reserved.
//

#import "EXTPolynomialSSeq.h"

@interface EXTMaySpectralSequence : EXTPolynomialSSeq

+(EXTMaySpectralSequence*) fillToWidth:(int)width;
+(EXTMaySpectralSequence*) fillForAn:(int)n width:(int)width;

-(NSArray*) applySquare:(int)order
               toVector:(NSArray*)vector
             atLocation:(EXTTriple*)location;

@end
