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
#import "EXTdifferential.h"
#import "EXTMatrix.h"
#import "EXTPair.h"
#import "EXTSpectralSequence.h"

@implementation EXTTerm

@synthesize location;
@synthesize names;
@synthesize cycles;
@synthesize boundaries;

#pragma mark *** initialization ***

// setTerm re/initializes an EXTTerm with the desired values.
-(id) setTerm:(EXTLocation*)whichLocation andNames:(NSMutableArray*)whichNames {
    // first try to initialize the memory for the object which we don't control

    // if it succeeds, then initialize the members
    [self setLocation:whichLocation];
    [self setBoundaries:[NSMutableArray array]];
    [self setCycles:[NSMutableArray array]];

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
		[self setLocation:[coder decodeObjectForKey:@"location"]];
        //		[self setPage:[coder decodeIntForKey:@"page"]];
	}
	return self;
}

- (void) encodeWithCoder:(NSCoder*) coder {
	[coder encodeObject: location forKey:@"location"];
//	[coder encodeInt:page forKey:@"page"];
}

#pragma mark *** drawing; TODO: SEPARATE THIS OUT ***

// TODO: separate out these magic constants
- (void) drawWithSpacing:(CGFloat)spacing page:(int)page offset:(int)offset {
    NSBezierPath* path = [NSBezierPath new];
    NSPoint point = [[self location] makePoint];
    CGFloat x = (point.x)*spacing,
            y = (point.y)*spacing;
    
    for (int i = 0; i < [self dimension:page]; i++) {
        int j = i + offset;
        
        NSRect dotPosition =
            NSMakeRect(x + 3.5/9*spacing + ((CGFloat)((j%3)-1)*2)/9*spacing,
                       y+3.5/9*spacing + ((CGFloat)(((1+j)%4)-2)*2)/9*spacing,
                       2.0*spacing/9,
                       2.0*spacing/9);
        
        [path appendBezierPathWithOvalInRect:dotPosition];
    }
    
    [[NSColor blackColor] set];
	[path fill];
}



#pragma mark ***EXTTool class methods***

- (void)addSelfToSS:(EXTDocument *)theDocument {
    NSMutableArray *terms = [theDocument.sseq terms];
    
    // if we're not already added, add us.
    if (![terms containsObject:self])
        [[theDocument.sseq terms] addObject:self];
}

+ (NSBezierPath *) makeHighlightPathAtPoint: (NSPoint)point onGrid:(EXTGrid *)theGrid onPage:(NSInteger)thePage {
	return [NSBezierPath bezierPathWithRect:[theGrid enclosingGridRect:point]];
}

#pragma mark *** not yet sure how to classify this (it's an init, in some sense) ***

// TODO: this requires sophisticated logic now that terms understand where they
// live in the spectral sequence.  summation is more appropriate an operation on
// modules, rather than on EXTTerms...
+ (id) sumOfTerms:(EXTTerm *)termOne and:(EXTTerm *)termTwo {
	return nil; // allowed?
}

// this assumes that the cycles from the page before have already been computed.
// this may or may not be a desirable trait, but for the moment, that's the way
// things are.
//
// XXX: something about this logic is wrong; it should be, like, taking inter-
// sections of cycle groups across pages or something... or right-multiplying
// in the old cycle group and interpreting the results... or something.
-(void) computeCycles:(int)whichPage // (the page we're moving *to*)
                 sSeq:(EXTSpectralSequence*)sSeq {
    // if we're at the bottom page, then there are no differentials to test.
    if (whichPage == 0) {
        [cycles setObject:[EXTMatrix identity:self.names.count].presentation atIndexedSubscript:0];
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
    
    // ask for the kernel of this differential
    EXTMatrix *cycleMatrix = [EXTMatrix matrixWidth:oldCycles.count height:names.count];
    [cycleMatrix setPresentation:oldCycles];
    
    // postcompose with the differential
    EXTMatrix *restricted = [EXTMatrix newMultiply:differential.presentation by:cycleMatrix];
    
    // extract the kernel of the composition
    NSMutableArray *kernel = [restricted kernel];
    EXTMatrix *kernelMatrix = [EXTMatrix matrixWidth:[kernel count] height:[oldCycles count]];
    [kernelMatrix setPresentation:kernel];
    EXTMatrix *newCycleMatrix = [EXTMatrix newMultiply:cycleMatrix by:kernelMatrix];
    
    // store it to the cycles list
    [cycles setObject:newCycleMatrix.presentation atIndexedSubscript:whichPage];
        
    return;
}

-(void) computeBoundaries:(int)whichPage sSeq:(EXTSpectralSequence*)sSeq {
    // if this is page 0, we have a default value to start with.
    if (whichPage == 0) {
        [boundaries setObject:@[] atIndexedSubscript:0];
        return;
    }
    
    NSMutableArray *newBoundaries = [NSMutableArray arrayWithArray:self.boundaries[whichPage-1]];
    
    // try to get a differential on this page.
    EXTDifferential *differential = [sSeq findDifflWithTarget:self.location onPage:whichPage-1];
    
    // if we couldn't find a differential, just keep the old boundaries.
    if (!differential) {
        self.boundaries[whichPage] = newBoundaries;
        return;
    }
    
    // clean up the differential's presentation before touching it
    [differential assemblePresentation];
    
    // and add it to the new boundaries
    [newBoundaries addObjectsFromArray:differential.presentation.presentation];
    
    // remove duplicate boundaries by getting a minimum spanning set, then store
    EXTMatrix *boundaryMat = [EXTMatrix matrixWidth:newBoundaries.count height:self.names.count];
    [boundaries setObject:[boundaryMat image] atIndexedSubscript:whichPage];
    
    return;
}

-(int) dimension:(int)whichPage {
    return [[cycles objectAtIndex:whichPage] count] -
           [[boundaries objectAtIndex:whichPage] count];
}

// XXX: this should deal with EXTLocation in a sane way.
+(id) dealWithClick:(NSPoint)location document:(EXTDocument*)document {
    EXTPair	*pointPair = [EXTPair pairWithA:(int)(location.x)
                                          B:(int)(location.y)];
    EXTTerm *term = [EXTTerm term:pointPair andNames:[NSMutableArray array]];

    [[document.sseq terms] addObject:term];
    
    return term;
}

@end
