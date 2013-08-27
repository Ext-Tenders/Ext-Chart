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

#pragma mark *** initialization ***

// setTerm re/initializes an EXTTerm with the desired values.
-(id) setTerm:(EXTLocation*)whichLocation andNames:(NSMutableArray*)whichNames {
    // first try to initialize the memory for the object which we don't control

    // if it succeeds, then initialize the members
    [self setLocation:whichLocation];
    [self setBoundaries:[NSMutableArray array]];
    [self setCycles:[NSMutableArray array]];
    [self setDisplayBasis:nil];
    [self setDisplayNames:nil];

    [self setNames:whichNames];

    // initialize the cycles to contain everything.
    [cycles addObject:[EXTMatrix identity:whichNames.count].presentation];

    // and we start with no boundaries.
    [boundaries addObject:@[]];

    // regardless, return the object as best we've initialized it.
    return self;
}

+(EXTTerm*) term:(EXTLocation*)whichLocation andNames:(NSMutableArray*)whichNames {
    EXTTerm *term = [EXTTerm new];
    [term setTerm:whichLocation andNames:whichNames];
    return term;
}

#pragma mark *** packing and unpacking ***

// TODO: update these to pull in the element names.  they should not bother
// writing the cycles and boundaries to disk; these are computable from scratch.

- (id) initWithCoder: (NSCoder*) coder {
	if (self = [super init])
	{
        names = [coder decodeObjectForKey:@"names"];
        location = [coder decodeObjectForKey:@"location"];
        displayBasis = [coder decodeObjectForKey:@"displayBasis"];
        displayNames = [coder decodeObjectForKey:@"displayNames"];
        
        // start off with the default cycles and boundaries
        boundaries = [NSMutableArray array];
        cycles = [NSMutableArray array];
        [cycles addObject:[EXTMatrix identity:names.count].presentation];
        [boundaries addObject:@[]];
	}
    
	return self;
}

- (void) encodeWithCoder:(NSCoder*) coder {
    [coder encodeObject:names forKey:@"names"];
	[coder encodeObject:location forKey:@"location"];
    [coder encodeObject:displayBasis forKey:@"displayBasis"];
    [coder encodeObject:displayNames forKey:@"displayNames"];
}

#pragma mark ***EXTTool class methods***

- (void)addSelfToSS:(EXTDocument *)theDocument {
    NSMutableDictionary *terms = [theDocument.sseq terms];
    
    // if we're not already added, add us.
    if (![[terms objectForKey:self.location] isEqual:self])
        [terms setObject:self forKey:self.location];
}

#pragma mark *** not yet sure how to classify this (it's an init, in some sense) ***

// TODO: this requires sophisticated logic now that terms understand where they
// live in the spectral sequence.  summation is more appropriate an operation on
// modules, rather than on EXTTerms...
+ (id) sumOfTerms:(EXTTerm *)termOne and:(EXTTerm *)termTwo {
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
        [cycles setObject:[EXTMatrix identity:self.size].presentation atIndexedSubscript:0];
        return;
    }

    // otherwise...
    NSMutableArray *oldCycles = [cycles objectAtIndex:(whichPage-1)];

    // if the EXTTerm has already been emptied, don't even bother computing any
    // new differentials.
    if ([oldCycles count] == 0) {
        [cycles setObject:@[] atIndexedSubscript:whichPage];
        return;
    }
    
    // try to find a freshly acting differential
    EXTDifferential *differential = [sSeq findDifflWithSource:self.location onPage:(whichPage-1)];
    
    // if no differentials act, then copy the old cycles anew.
    if (!differential) {
        [cycles setObject:[[cycles objectAtIndex:(whichPage-1)] copy] atIndexedSubscript:whichPage];
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
    EXTMatrix *left = [EXTMatrix matrixWidth:[[differential.end.boundaries objectAtIndex:(whichPage-1)] count] height:differential.end.size];
    left.presentation = [differential.end.boundaries objectAtIndex:(whichPage-1)];
    EXTMatrix *incomingCycles = [EXTMatrix matrixWidth:[cycles[whichPage-1] count] height:self.size];
    incomingCycles.presentation = cycles[whichPage-1];
    EXTMatrix *right = [EXTMatrix newMultiply:differential.presentation by:incomingCycles];
    
    // this is the span B^{r-1}_{s, t} <-- S --> Z^{r-1}_{s+1, t-r+2}.
    NSArray *span = [EXTMatrix formIntersection:left with:right];
    
    // the composition of the two inclusions S >-> Z^{r-1}_{s+1, t-r+2} >-> ...
    // ... >-> E^1_{s+1, t-r+2} has image the cycle group Z^r_{s+1,t-r+2}.
    EXTMatrix *cycleComposite = [EXTMatrix newMultiply:incomingCycles by:span[1]];
    
    // store it to the cycles list
    [cycles setObject:cycleComposite.presentation atIndexedSubscript:whichPage];
        
    return;
}

-(void) computeBoundaries:(int)whichPage sSeq:(EXTSpectralSequence*)sSeq {
    // if this is page 0, we have a default value to start with.
    if (whichPage == 0) {
        [boundaries setObject:@[] atIndexedSubscript:0];
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
    
    // restrict its action to the previous cycle group
    EXTMatrix *restriction = [EXTMatrix matrixWidth:((NSMutableArray*)differential.start.cycles[whichPage-1]).count height:differential.start.size];
    restriction.presentation = differential.start.cycles[whichPage-1];
    EXTMatrix *restrictedDiff = [EXTMatrix newMultiply:differential.presentation by:restriction];
    
    // add these to the old boundaries
    NSMutableArray *newImage = [restrictedDiff image];
    EXTMatrix *boundaryInclusion = [EXTMatrix matrixWidth:(newImage.count+((NSMutableArray*)boundaries[whichPage-1]).count) height:differential.end.size];
    [newImage addObjectsFromArray:boundaries[whichPage-1]];
    boundaryInclusion.presentation = [NSMutableArray arrayWithArray:newImage];
    
    // find a minimum spanning set and store it
    [boundaries setObject:[boundaryInclusion image] atIndexedSubscript:whichPage];

    return;
}

-(int) dimension:(int)whichPage {
    int cycleCount = [[cycles objectAtIndex:whichPage] count],
        boundaryCount = [[boundaries objectAtIndex:whichPage] count],
        dim = cycleCount - boundaryCount;
    
    if (dim < 0) {
        DLog("term with name %@ has negative dimension on page %d", self.names[0], whichPage);
        return 0;
    }
    
    return dim;
}

@end
