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

-(void) assemblePresentation {
    // create a list of all the image vectors in all the partial definitions
    
    // put them together and find their collective image.
    
    // if it has rank less than the rank of the cycle groups, then set the
    // wellDefined flag to false and quit.
    
    // otherwise, pick off a minimal set of vectors which contribute to the
    // image, remembering which definition they came from and which column
    // vector they were in there.
    
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
