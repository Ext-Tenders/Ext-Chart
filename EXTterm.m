//
//  EXTTerm.m
//  Ext Chart
//
//  Created by Michael Hopkins on 7/22/11.
//  Copyright 2011 Harvard. All rights reserved.
//

#import "EXTTerm.h"
#import "EXTPair.h"
#import "EXTGrid.h"
#import "EXTDocument.h"
#import "EXTdifferential.h"
#import "EXTMatrix.h"

@implementation EXTTerm

@synthesize location;
@synthesize names;
@synthesize cycles;
@synthesize boundaries;

#pragma mark *** initialization ***

// setTerm re/initializes an EXTTerm with the desired values.
-(id) setTerm:(EXTPair*)whichLocation andNames:(NSMutableArray*)whichNames {
    // first try to initialize the memory for the object which we don't control
    if (self = [super init]) {
        // if it succeeds, then initialize the members
        [self setLocation:whichLocation];
        [self setBoundaries:[NSMutableArray arrayWithObjects: nil]];
        [self setCycles:[NSMutableArray arrayWithObjects: nil]];
        
        [self setNames:whichNames];
        
        // initialize the cycles to contain everything.
        // XXX: change the array upper bound when we stop randomizing.
        NSMutableArray *initialCycles = [NSMutableArray
                                         arrayWithCapacity:[whichNames count]];
        for (int j = 0; j < whichNames.count; j++) {
            NSMutableArray *column = [NSMutableArray array];
            for (int i = 0; i < whichNames.count; i++) {
                if (i == j)
                    [column setObject:@(1) atIndexedSubscript:i];
                else
                    [column setObject:@(0) atIndexedSubscript:i];
            }

            [initialCycles addObject:column];
        }
        [cycles addObject:initialCycles];
        
        // and we start with no boundaries.
        [boundaries addObject:@[]];
    }
    
    // regardless, return the object as best we've initialized it.
    return self;
}

// build a new EXTTerm object and initialize it
+(id) newTerm:(EXTPair*)whichLocation andNames:(NSMutableArray*)whichNames {
    EXTTerm* term = [[EXTTerm alloc] setTerm:whichLocation andNames:whichNames];
    
    return term;
}

+(EXTTerm*) term:(EXTPair*)whichLocation andNames:(NSMutableArray*)whichNames {
    EXTTerm* term = [EXTTerm newTerm:whichLocation andNames:whichNames];
    
    [term autorelease];
    
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
- (void) drawWithSpacing:(CGFloat)spacing page:(int)page {
    NSBezierPath* path = [[NSBezierPath alloc] init];
    CGFloat x = [[self location] a]*spacing,
            y = [[self location] b]*spacing;
    
    for (int j = 0; j < [self dimension:page]; j++) {
        NSRect dotPosition =
            NSMakeRect(x + 3.5/9*spacing + ((CGFloat)((j%3)-1)*2)/9*spacing,
                       y+3.5/9*spacing + ((CGFloat)((1+j%4)-2)*2)/9*spacing,
                       2.0*spacing/9,
                       2.0*spacing/9);
        
        [path appendBezierPathWithOvalInRect:dotPosition];
    }
    
    [[NSColor blackColor] set];
	[path fill];
}



#pragma mark ***EXTTool class methods***

- (void)addSelfToSS:(EXTDocument *)theDocument {
    NSMutableArray *terms = [theDocument terms];
    
    // if we're not already added, add us.
    if (![terms containsObject:self])
        [[theDocument terms] addObject:self];
}

+ (NSBezierPath *) makeHighlightPathAtPoint: (NSPoint)point onGrid:(EXTGrid *)theGrid onPage:(NSInteger)thePage {
	return [[NSBezierPath bezierPathWithRect:[theGrid enclosingGridRect:point]] retain];
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
-(void) computeCycles:(int)whichPage
    differentialArray:(NSMutableArray*)differentials {
    
    // if we're at the bottom page, then do nothing --- there are no
    // differentials available to study, and we don't want to fuck up our copies.
    if (whichPage == 0)
        return;
    
    NSMutableArray *newCycles = [NSMutableArray array];
    NSMutableArray *oldCycles = [cycles objectAtIndex:(whichPage-1)];

    // if the EXTTerm has already been emptied, don't even bother computing any
    // new differentials.
    if ([oldCycles count] == 0) {
        [cycles setObject:@[] atIndexedSubscript:whichPage];
        return;
    }
    
    // iterate through the differentials, looking for more cycles
    for (EXTDifferential *differential in differentials) {
        if (([differential start] != self) ||     // if we're not the source...
            ([differential page]+1 != whichPage)) // ...or this isn't the page...
            continue;                             // then skip this differential.
        
        // ask for the kernel of this differential
        EXTMatrix *cycleMatrix = [EXTMatrix matrixWidth:oldCycles.count height:names.count];
        [cycleMatrix setPresentation:oldCycles];
        
        EXTMatrix *restricted = [EXTMatrix newMultiply:differential.presentation by:cycleMatrix];
        
        NSMutableArray *kernel = [restricted kernel];
        EXTMatrix *kernelMatrix = [EXTMatrix matrixWidth:[kernel count] height:[oldCycles count]];
        [kernelMatrix setPresentation:kernel];
        
        EXTMatrix *newCycleMatrix = [EXTMatrix newMultiply:cycleMatrix by:kernelMatrix];
        
        // and add it to the cycles
        [newCycles addObjectsFromArray:newCycleMatrix.presentation];
        
        // release all this ridiculous stuff we've allocated
        [restricted release];
        [newCycleMatrix release];
        
        // there should really only be one differential attached to a given
        // EXTTerm on a given page.  so, at this point we should return.
        //
        // XXX: if this were smarter, it would continue thumbing through the
        // differentials and throw an error if there were more than one.
        [cycles setObject:newCycles atIndexedSubscript:whichPage];
        
        return;
    }
    
    // if there weren't any differentials acting, then really the zero
    // differential acted, and we should carry over the same cycles as from
    // last time.
    newCycles = [[cycles objectAtIndex:(whichPage-1)] copy];
    
    [cycles setObject:newCycles atIndexedSubscript:whichPage];
}

// TODO: this is a duplicate of the code above. it would be nice to fix that.
-(void) computeBoundaries:(int)whichPage
        differentialArray:(NSMutableArray*)differentials {
    
    if (whichPage == 0)
        return;
    
    NSMutableArray *newBoundaries = [NSMutableArray array];
    
    for (EXTDifferential *differential in differentials) {
        if (([differential end] != self) ||
            ([differential page]+1 != whichPage))
            continue;
        
        // XXX: maybe we should right-multiply by the cycle matrix first?
        NSMutableArray *image = [[differential presentation] image];
        
        // and add it to the new boundaries
        [newBoundaries addObjectsFromArray:image];
        
        break;
    }
    
    if (newBoundaries.count == 0)
        [newBoundaries addObjectsFromArray:
            [boundaries objectAtIndex:(whichPage-1)]];
    
    [boundaries setObject:newBoundaries atIndexedSubscript:whichPage];
}

-(int) dimension:(int)whichPage {
    return [[cycles objectAtIndex:whichPage] count] -
           [[boundaries objectAtIndex:whichPage] count];
}

+(id) dealWithClick:(NSPoint)location document:(EXTDocument*)document {
    EXTPair	*pointPair = [EXTPair pairWithA:location.x B:location.y];
    EXTTerm *term = [EXTTerm term:pointPair andNames:[NSMutableArray array]];

    [[document terms] addObject:term];
    
    return term;
}

@end
