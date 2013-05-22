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
        [minimalVectors addObject:enormousMat.presentation[i]];
        [minimalParents addObject:imageParents[i]];
        [minimalIndices addObject:imageIndices[i]];
    }
    
    // TODO: maybe we should extend by 0 in some underdetermined way?  this
    // might be mildly more preferable to just failing outright.
    if (minimalVectors.count != [start.cycles[page] count]) { // if too few...
        wellDefined = false; // ... mark that we failed
        return;              //     and then jump back.
    }
    
    // construct a matrix presenting the differential in this basis
    
    // construct a matrix inverting this basis matrix
    
    // multiply to get a matrix presenting the differential in the std basis.
    
    // store it and set the wellDefined flag to true.
    
    NSLog(@"XXX: Not yet implemented.");
    
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
