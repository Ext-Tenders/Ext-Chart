//
//  EXTTerm.m
//  Ext Chart
//
//  Created by Michael Hopkins on 7/22/11.
//  Copyright 2011 Harvard University. All rights reserved.
//

#import "EXTTerm.h"
#import "EXTGrid.h"
#import "EXTDocument.h"
#import "EXTDifferential.h"
#import "EXTMatrix.h"
#import "EXTPair.h"
#import "EXTSpectralSequence.h"

@implementation EXTTerm

@synthesize location;
@synthesize names;
@synthesize cycles;
@synthesize boundaries;
@synthesize displayBasis;
@synthesize displayNames;
@synthesize homologyReps;

#pragma mark *** initialization ***

// setTerm re/initializes an EXTTerm with the desired values.
-(instancetype) setTerm:(EXTLocation*)whichLocation
              withNames:(NSMutableArray*)whichNames
      andCharacteristic:(int)characteristic {
    // first try to initialize the memory for the object which we don't control

    // if it succeeds, then initialize the members
    [self setLocation:whichLocation];
    [self setBoundaries:[NSMutableArray array]];
    [self setCycles:[NSMutableArray array]];
    [self setHomologyReps:[NSMutableArray array]];
    [self setDisplayBasis:nil];
    [self setDisplayNames:nil];

    [self setNames:whichNames];

    // initialize the cycles to contain everything.
    [cycles addObject:[EXTMatrix identity:whichNames.count]];
    ((EXTMatrix*)cycles[0]).characteristic = characteristic;

    // and we start with no boundaries.
    [boundaries addObject:[EXTMatrix matrixWidth:0 height:whichNames.count]];
    ((EXTMatrix*)boundaries[0]).characteristic = characteristic;

    // regardless, return the object as best we've initialized it.
    return self;
}

+(EXTTerm*)     term:(EXTLocation*)whichLocation
           withNames:(NSMutableArray*)whichNames
   andCharacteristic:(int)characteristic {
    EXTTerm *term = [EXTTerm new];
    [term setTerm:whichLocation withNames:whichNames andCharacteristic:characteristic];
    return term;
}

#pragma mark *** packing and unpacking ***

// TODO: update these to pull in the element names.  they should not bother
// writing the cycles and boundaries to disk; these are computable from scratch.

- (instancetype) initWithCoder: (NSCoder*) coder {
	if (self = [super init])
	{
        boundaries = [NSMutableArray array];
        cycles = [NSMutableArray array];
        
        names = [coder decodeObjectForKey:@"names"];
        location = [coder decodeObjectForKey:@"location"];
        displayBasis = [coder decodeObjectForKey:@"displayBasis"];
        displayNames = [coder decodeObjectForKey:@"displayNames"];
        
        // note: we're just initializing the first element of the array, not
        // the whole thing.
        boundaries[0] = [coder decodeObjectForKey:@"boundaries"];
        cycles[0] = [coder decodeObjectForKey:@"cycles"];
        
        homologyReps = [NSMutableArray array];
	}
    
	return self;
}

- (void) encodeWithCoder:(NSCoder*) coder {
    [coder encodeObject:names forKey:@"names"];
	[coder encodeObject:location forKey:@"location"];
    [coder encodeObject:displayBasis forKey:@"displayBasis"];
    [coder encodeObject:displayNames forKey:@"displayNames"];
    [coder encodeObject:boundaries[0] forKey:@"boundaries"];
    [coder encodeObject:cycles[0] forKey:@"cycles"];
}

#pragma mark *** not yet sure how to classify this (it's an init, in some sense) ***

// TODO: this requires sophisticated logic now that terms understand where they
// live in the spectral sequence.  summation is more appropriate an operation on
// modules, rather than on EXTTerms...
+ (instancetype) sumOfTerms:(EXTTerm *)termOne and:(EXTTerm *)termTwo {
    NSLog(@"+sumOfTerms is not yet implemented.");
	return nil; // allowed?
}

-(int) size {
    return names.count;
}

// this assumes that the cycles from the page before have already been computed.
// this may or may not be a desirable trait, but for the moment, that's the way
// things are.
-(void) computeCycles:(int)whichPage // (the page we're moving *to*)
                 sSeq:(EXTSpectralSequence*)sSeq {
    // if we're at the bottom page, then there are no differentials to test.
    if (whichPage == 0) {
        return;
    }

    // otherwise...
    EXTMatrix *oldCycles = [cycles objectAtIndex:(whichPage-1)];

    // if the EXTTerm has already been emptied, don't even bother computing any
    // new differentials.
    if ([oldCycles width] == 0) {
        cycles[whichPage] = [EXTMatrix matrixWidth:0 height:self.size];
        return;
    }
    
    // try to find a freshly acting differential
    EXTDifferential *differential = [sSeq findDifflWithSource:self.location onPage:(whichPage-1)];
    
    // if no differentials act, then copy the old cycles anew.
    if (!differential) {
        cycles[whichPage] = [cycles[whichPage-1] copy];
        return;
    }
    
    // before touching the differential, we need to get it up-to-date.
    [differential assemblePresentation];
    
    // we have the cospan B^{r-1}_{s,t} --> E^1_{s,t} <-d-- Z^{r-1}_{s+1,t-r+2}.
    // the pullback span encodes those elements of the right-hand source which
    // lie in B^{r-1}_{s,t} --- i.e., those elements which lie in the kernel of
    // the projection B^{r-1}_{s, t} --> Z^{r-1}_{s, t} --> E^r_{s, t}.  these
    // are the elements of Z^r_{s+1, t-r+2} which we want.  following the
    // composite Z^r_{s+1, t-r+2} --> Z^{r-1}_{s+1, t-r+2} --> E^1_{s+1, t-r+2}
    // gives the cycle matrix in the form we've been expecting it.
    EXTMatrix *left = differential.end.boundaries[(whichPage-1)];
    EXTMatrix *incomingCycles = cycles[whichPage-1];
    EXTMatrix *right = differential.presentation;
    
    // if there's something to match the characteristic by, then do it
    if (differential.partialDefinitions.count > 0) {
        EXTPartialDefinition *firstP = differential.partialDefinitions[0];
        left.characteristic = firstP.inclusion.characteristic;
    }
    
    // this is the span B^{r-1}_{s, t} <-- S --> Z^{r-1}_{s+1, t-r+2}.
    NSArray *span = [EXTMatrix formIntersection:left with:right];
    
    // the composition of the two inclusions S >-> Z^{r-1}_{s+1, t-r+2} >-> ...
    // ... >-> E^1_{s+1, t-r+2} has image the cycle group Z^r_{s+1,t-r+2}.
    EXTMatrix *cycleComposite = [EXTMatrix newMultiply:incomingCycles by:span[1]];
    
    // store it to the cycles list
    cycles[whichPage] = cycleComposite;
    
    return;
}

-(void) computeBoundaries:(int)whichPage sSeq:(EXTSpectralSequence*)sSeq {
    // if this is page 0, we have a default value to start with.
    if (whichPage == 0) {
        return;
    }
    
    // try to get a differential on this page.
    EXTDifferential *differential = [sSeq findDifflWithTarget:self.location onPage:whichPage-1];
    
    // if we couldn't find a differential, then pretend that the differential is
    // zero and just keep the old boundaries.
    if (!differential) {
        self.boundaries[whichPage] = self.boundaries[whichPage-1];
        return;
    }
    
    // clean up the differential's presentation before touching it
    [differential assemblePresentation];
    
    // add these to the old boundaries
    EXTMatrix *newBoundaries = [boundaries[whichPage - 1] copy];
    [newBoundaries.presentation appendData:differential.presentation.presentation];
    newBoundaries.width += differential.presentation.width;
    
    // find a minimum spanning set and store it
    boundaries[whichPage] = [newBoundaries image];

    return;
}

-(void) updateDataForPage:(int)whichPage
                   inSSeq:(EXTSpectralSequence*)sSeq
         inCharacteristic:(int)characteristic {
    [self computeCycles:whichPage sSeq:sSeq];
    [self computeBoundaries:whichPage sSeq:sSeq];
    
    EXTMatrix *cycleMat = self.cycles[whichPage],
              *boundaryMat = self.boundaries[whichPage];
    cycleMat.characteristic = sSeq.defaultCharacteristic;
    boundaryMat.characteristic = sSeq.defaultCharacteristic;
    
    homologyReps[whichPage] = [EXTMatrix findOrdersOf:boundaryMat in:cycleMat];
}

-(int) dimension:(int)whichPage {
    return ((NSDictionary*)homologyReps[whichPage]).count;
}

-(NSString*) nameForVector:(NSArray*)vector {
    NSString *ret = @"";
    
    for (int i = 0; i < vector.count; i++) {
        if ([ret isEqualToString:@""]) {
            if ([vector[i] intValue] == 1)
                ret = [NSString stringWithFormat:@"%@", self.names[i]];
            else if ([vector[i] intValue] != 0)
                ret = [NSString stringWithFormat:@"%@ %@", vector[i], self.names[i]];
            // if vector[i] is zero, don't do anything.
            continue;
        }
        
        if ([vector[i] intValue] > 1)
            ret = [NSString stringWithFormat:@"%@ + %@ %@",
                   ret, vector[i], self.names[i]];
        else if ([vector[i] intValue] == 1)
            ret = [NSString stringWithFormat:@"%@ + %@",
                   ret, self.names[i]];
        else if ([vector[i] intValue] < 0)
            ret = [NSString stringWithFormat:@"%@ - %@ %@",
                   ret, @(-[vector[i] intValue]), self.names[i]];
    }
    
    return ret;
}

@end
