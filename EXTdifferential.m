//
//  EXTDifferential.m
//  Ext Chart
//
//  Created by Michael Hopkins on 7/22/11.
//  Copyright 2011 Harvard. All rights reserved.
//

#import "EXTDifferential.h"
#import "EXTPair.h"
#import "EXTGrid.h"
#import "EXTTerm.h"

// little class to keep track of partial subdefinitions of a parent differential
@implementation EXTPartialDifferential

@synthesize inclusion;
@synthesize differential;
@synthesize automaticallyGenerated;

-(EXTPartialDifferential*) init {
    [super init];
    
    // we don't keep track of enough information about dimensions to make the
    // appropriate initialization calls to EXTMatrix factories.
    inclusion = nil;
    differential = nil;
    
    return self;
}

// TODO: make the boolean flag into (change to true)-only, like a dirty flag.
// use this to decide whether to prompt the user when deleting partial
// definitions, or generally when performing any other destructive operation.

@end


// redeclare part of the EXTDifferential interface so that we synthesize both
// getters *and* setters for the publicly read-only properties.
@interface EXTDifferential ()

@property(retain) NSMutableArray *partialDefinitions;
@property(retain) EXTMatrix *presentation;

@end


// actual class housing the differential information
@implementation EXTDifferential

@synthesize page;
@synthesize start, end;
@synthesize partialDefinitions;
@synthesize presentation;
@synthesize wellDefined;

+(id) newDifferential:(EXTTerm *)start end:(EXTTerm *)end page:(int)page {
    EXTDifferential *object = [EXTDifferential alloc];
    
    object.start = start;
    object.end = end;
    object.page = page;
    
    // XXX: this requires that we ONLY add differentials to the next page. this
    // is probably NOT the behavior that we want.  i've changed this to use
    // page 0 instead, but that is probably ALSO not what we want.  this needs
    // to be thought through.
    [object setPresentation:[EXTMatrix matrixWidth:[start dimension:0] height:[end dimension:0]]];
    object.wellDefined = false;
    object.partialDefinitions = [NSMutableArray array];
    
    return object;
}

+(id) differential:(EXTTerm *)start end:(EXTTerm *)end page:(int)page {
    EXTDifferential *differential =
        [EXTDifferential newDifferential:start end:end page:page];
    
    return [differential autorelease];
}

// this routine assembles from the available partial definitions of the
// differential a single definition on the cycle group.  it's a bit convoluted.
-(void) assemblePresentation {
    NSMutableArray *imageVectors = [NSMutableArray array], // array of vectors
        *imageParents = [NSMutableArray array], // def'n indices they belong to
        *imageIndices = [NSMutableArray array]; // column indices they belong to
    
    // assemble all the inclusion image vectors into one massive array.
    for (int i = 0; i < self.partialDefinitions.count; i++) {
        EXTPartialDifferential *workingPartial = self.partialDefinitions[i];
        NSMutableArray *workingVectors = workingPartial.inclusion.presentation;
        for (int j = 0; j < workingVectors.count; j++) {
            [imageVectors addObject:workingVectors[j]];
            [imageParents addObject:@(i)];
            [imageIndices addObject:@(j)];
        }
    }
    
    // the point of doing that was to perform column reduction and find a
    // minimal spanning set for their image.
    EXTMatrix *enormousMat = [EXTMatrix matrixWidth:imageVectors.count
                                             height:[imageVectors[0] count]];
    enormousMat.presentation = imageVectors;
    enormousMat = [enormousMat columnReduce];
    
    // from this, let's extract a *minimal* generating set for the image.  if
    // the inclusions are jointly of full rank, we'll need this for later
    // calculations.  if they aren't of full rank, we can use this to see that
    // and bail if necessary.
    NSMutableArray *minimalVectors = [NSMutableArray array],
                   *minimalParents = [NSMutableArray array],
                   *minimalIndices = [NSMutableArray array];
    
    for (int i = 0; i < enormousMat.width; i++) {
        bool isEmpty = true;
        
        for (int j = 0; j < enormousMat.height; j++)
            if (enormousMat.presentation[i][j] != 0)
                isEmpty = false;
        
        // if this vector is inessential, it will have been eliminated by rcef.
        if (isEmpty)
            continue;
        
        // if it's essential, we should add it. :)
        [minimalVectors addObject:imageVectors[i]];
        [minimalParents addObject:imageParents[i]];
        [minimalIndices addObject:imageIndices[i]];
    }
    
    // then, if we have too few vectors left to be of full rank...
    if (minimalVectors.count != [start.cycles[page] count])
        wellDefined = false; // ... then mark that we failed
    else
        wellDefined = true;  // ... otherwise, mark that we're good to go.
    
    // we want to extend this basis of the cycle groups to a basis of the entire
    // E_1 term.  start by augmenting to a matrix containing a definite surplus
    // of basis vectors.
    NSMutableArray *augmentedVectors =
        [NSMutableArray arrayWithArray:minimalVectors];
    for (int i = 0; i < end.names.count; i++) {
        NSMutableArray *en = [NSMutableArray array];
        for (int j = 0; j < end.names.count; j++) {
            if (i == j) {
                [en addObject:@1];
            } else {
                [en addObject:@0];
            }
        }
        
        [augmentedVectors addObject:en];
    }
    
    // then, column reduce it.  the vectors that survive will be our full basis.
    EXTMatrix *augmentedMat =
        [EXTMatrix matrixWidth:augmentedVectors.count height:end.names.count];
    augmentedMat.presentation = augmentedVectors;
    EXTMatrix *reducedMat = [augmentedMat columnReduce];
    NSMutableArray *reducedVectors = reducedMat.presentation;
    
    // having reduced it, we pull out the basis vectors we needed for extension
    for (int i = minimalVectors.count; i < reducedVectors.count; i++) {
        bool needThisOne = true;
        for (int j = 0; j < [reducedVectors[i] count]; j++) {
            if ([reducedVectors[i] objectAtIndex:j] != 0)
                needThisOne = false;
        }
        
        if (needThisOne)
            [minimalVectors addObject:augmentedVectors[i]];
    }
    
    // and so here's our basis matrix.
    EXTMatrix *basisMatrix =
        [EXTMatrix matrixWidth:minimalVectors.count
                        height:[minimalVectors[0] count]];
    basisMatrix.presentation = minimalVectors;

    // now, we construct a matrix presenting the differential in this basis.
    // this is where the partial definitions actually get used.
    EXTMatrix *differentialInCoordinates =
        [EXTMatrix matrixWidth:basisMatrix.width height:basisMatrix.height];
    for (int i = 0; i < basisMatrix.width; i++) {
        // if we're in the range of partially determined stuff, use the def'ns
        if (i < minimalParents.count) {
            EXTPartialDifferential *pdiffl =
                [partialDefinitions
                    objectAtIndex:[[minimalParents objectAtIndex:i] intValue]];
            EXTMatrix *diffl = [pdiffl differential];
            differentialInCoordinates.presentation[i] =
                [[diffl presentation]
                    objectAtIndex:[[minimalIndices objectAtIndex:i] intValue]];
        } else {
            // otherwise, extend by zero.
            NSMutableArray *workingColumn = [NSMutableArray array];
            
            for (int j = 0; j < basisMatrix.height; j++)
                [workingColumn setObject:@0 atIndexedSubscript:j];
            
            differentialInCoordinates.presentation[i] = workingColumn;
        }
    }
    
    // finally, we need to put these matrices together to build a presentation
    // of the differential in the standard basis.  this is simple: just invert
    // and multiply. :)
    EXTMatrix *basisConversion = [basisMatrix invert];
    EXTMatrix *stdDifferential =
        [EXTMatrix newMultiply:differentialInCoordinates by:basisConversion];
    
    // finally, all our hard work done, we store and jump back.
    presentation = stdDifferential;
    
    return;
}

+(id) dealWithClick:(NSPoint)location document:(EXTDocument *)document {
    return nil;
}

- (id) initWithCoder: (NSCoder*) coder {
	if (self = [super init])
	{
		[self setStart:[coder decodeObjectForKey:@"start"]];
		[self setEnd:[coder decodeObjectForKey:@"end"]];
		[self setPage:[coder decodeIntForKey:@"page"]];
	}
	return self;
}

- (void) encodeWithCoder:(NSCoder*) coder {
	[coder encodeObject: start forKey:@"start"];
	[coder encodeObject: end forKey:@"end"];
	[coder encodeInt:page forKey:@"page"];
}

+ (EXTPair*) getEndFrom:(EXTPair*)start OnPage:(int)page {
	int a = [start a], b = [start b];
	a -= 1;
	b += page;
	return [EXTPair pairWithA:a B:b];
}

+ (EXTPair*) getStartFrom:(EXTPair*)end OnPage:(int)page {
	int a = [end a], b = [end b];
	a += 1;
	b -= page;
	return [EXTPair pairWithA:a B:b];
}

// TODO: fix these magic numbers.
// XXX: the differentials always attach themselves to the bottom class.  really,
// it looks better if they always attach themselves to the *last* class.
// *really* really, they should attach themselves intelligently to the class
// that makes most sense.  :)
- (void) drawWithSpacing:(CGFloat)spacing{
	CGFloat x1 = ([start.location a]+0.25)*spacing,
			y1 = ([start.location b]+0.25)*spacing,
			x2 = ([end.location a]+0.25)*spacing,
			y2 = ([end.location b]+0.25)*spacing;
	[[NSColor blackColor] set];
	NSBezierPath *line = [NSBezierPath bezierPath];
	[line moveToPoint:NSMakePoint(x1, y1)];
	[line lineToPoint:NSMakePoint(x2, y2)];
	[line setLineWidth:.25];
	[line stroke];
}

#pragma mark *** overridden EXTTool methods***

+ (NSBezierPath *) makeHighlightPathAtPoint:(NSPoint)point onGrid:(EXTGrid *)theGrid onPage:(NSInteger)page{
// until I do something better...namely getting the bidegree of the differential from the page
	
	NSRect baseRect = [theGrid enclosingGridRect:point];
	NSRect targetRect = NSOffsetRect(baseRect, -1*[theGrid gridSpacing], (page)*[theGrid gridSpacing]);
	NSBezierPath *newPath = [NSBezierPath bezierPathWithRect:baseRect];
	[newPath appendBezierPathWithRect:targetRect];
	
	[newPath retain];
	return newPath;
}

+ (void)addSelfToSequence:(NSMutableArray *)pageSequence
             onPageNumber:(NSUInteger)pageNo atPoint:(NSPoint)point {
	
//	EXTPage *extPage = [pageSequence objectAtIndex:pageNo];
//	EXTPair	*sourcePosition = [EXTPair pairWithA:point.x AndB:point.y];
//	EXTPair	*targetPosition = [EXTPair pairWithA:(point.x-1) AndB:(point.y+pageNo)];
//	EXTTerm *source = [[extPage termsArray] objectForKey:sourcePosition];
//	EXTTerm *target = [[extPage termsArray] objectForKey:targetPosition];
//	if (source && target) {
//		EXTDifferential* differential = [[EXTDifferential alloc] initWithPage:pageNo Start:sourcePosition AndEnd:targetPosition];
//		[[extPage differentialsArray] setObject:differential forKey:sourcePosition];
// 		[extPage setModified:YES];
//	}
}

@end
