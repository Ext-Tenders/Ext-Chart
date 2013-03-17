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

@implementation EXTDifferential

@synthesize page;
@synthesize start, end;
@synthesize presentation;

-(id) set:(EXTTerm *)start end:(EXTTerm *)end page:(int)page {
    [self setStart:start];
    [self setEnd:end];
    [self setPage:page];
    
    return self;
}

+(id) newDifferential:(EXTTerm *)start end:(EXTTerm *)end page:(int)page {
    EXTDifferential *object = [EXTDifferential alloc];
    
    [object set:start end:end page:page];
    
    [object setPresentation:[EXTMatrix initWithWidth:[start dimension:page] andHeight:[end dimension:page]]];
    
    return object;
}

+(id) dealWithClick:(NSPoint)location document:(EXTDocument *)document {
    return nil;
}

+ (id) differentialWithPage:(int)whichPage AndStart:(EXTPair*) startLocation {
	EXTDifferential* differential = [[EXTDifferential alloc] initWithPage:whichPage AndStart:startLocation];
	return [differential autorelease];
}

- (void) dealloc {
	[start release];
	[end release];
	[super dealloc];
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

- (void) drawWithSpacing:(CGFloat)spacing{
	CGFloat x1 = ([start a]+0.5)*spacing,
			y1 = ([start b]+0.5)*spacing,
			x2 = ([end a]+0.5)*spacing,
			y2 = ([end b]+0.5)*spacing;
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

#pragma mark *** tools for calculation homology (must be overridden in subclasses) ***

- (id) kernel{
	return nil;	
}
- (id) cokernel{
	return nil;
}

- (void) replaceSourceByKernel{
// override in subclasses.   For our "boolean" version, every non-zero map is an isomorphism, so

}

- (void) replaceTargetByCokernel{
	
}


@end
