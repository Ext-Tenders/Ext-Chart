//
//  EXTDifferential.m
//  Ext Chart
//
//  Created by Michael Hopkins on 7/22/11.
//  Copyright 2011 Harvard University. All rights reserved.
//

#import "EXTDifferential.h"
#import "EXTGrid.h"
#import "EXTTerm.h"

// redeclare part of the EXTDifferential interface so that we synthesize both
// getters *and* setters for the publicly read-only properties.
@interface EXTDifferential () {
    EXTMatrix *_presentation;
}

@property(strong) NSMutableArray *partialDefinitions;
@property(strong) EXTMatrix *presentation;

-(BOOL) isEqual:(id)object;

@end


// actual class housing the differential information
@implementation EXTDifferential

@synthesize page;
@synthesize start, end;
@synthesize partialDefinitions;
@synthesize wellDefined;

+(id) newDifferential:(EXTTerm *)start end:(EXTTerm *)end page:(int)page {
    EXTDifferential *object = [EXTDifferential new];
    
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
    
    return differential;
}

// quietly assemble the presentation when asked for it :)
-(EXTMatrix*) presentation {
    [self assemblePresentation];
    
    return _presentation;
}

-(void) setPresentation:(EXTMatrix*)presentation {
    _presentation = presentation;
}

// this routine assembles from the available partial definitions of the
// differential a single definition on the cycle group.  it's a bit convoluted.
-(void) assemblePresentation {
    _presentation =
        [EXTMatrix assemblePresentation:self.partialDefinitions
                        sourceDimension:self.start.size
                        targetDimension:self.end.size];
    return;
}

// TODO: ideally, this would check for definitional overlap, rather than literal
// partial-by-partial equality.  it would also ideally be moved into a place
// where it can also act on EXTMultiplicationEntry; there's nothing specific
// about this routine to EXTDifferential.
-(void) stripDuplicates {
    NSMutableArray *reducedPartials = [NSMutableArray array];
    
    for (EXTPartialDefinition *partial1 in self.partialDefinitions) {
        bool discardThis = false;
        
        [partial1.inclusion modularReduction];
        [partial1.differential modularReduction];
        
        for (EXTPartialDefinition *partial2 in reducedPartials) {
            if ([partial2 isEqual:partial1])
                discardThis = true;
            break;
        }
        
        if (discardThis)
            continue;
        
        [reducedPartials addObject:partial1];
    }
    
    self.partialDefinitions = reducedPartials;
}

-(BOOL) checkForSanity {
    for (EXTPartialDefinition *partial in partialDefinitions) {
        if (partial.inclusion.width != partial.differential.width)
            return false;
        if (partial.inclusion.height != start.size)
            return false;
        if (partial.differential.height != end.size)
            return false;
    }
    
    return true;
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
	[coder encodeObject:start forKey:@"start"];
	[coder encodeObject:end forKey:@"end"];
	[coder encodeInt:page forKey:@"page"];
}

#pragma mark *** overridden EXTTool methods***

+ (NSBezierPath *) makeHighlightPathAtPoint:(NSPoint)point onGrid:(EXTGrid *)theGrid onPage:(NSInteger)page{
// until I do something better...namely getting the bidegree of the differential from the page
	
	NSRect baseRect = [theGrid enclosingGridRect:point];
    // XXX: this doesn't work for the May grading.  there should be some kind
    // of call the EXTLocation or something to make this work out.
	NSRect targetRect = NSOffsetRect(baseRect, -1*[theGrid gridSpacing], (page)*[theGrid gridSpacing]);
	NSBezierPath *newPath = [NSBezierPath bezierPathWithRect:baseRect];
	[newPath appendBezierPathWithRect:targetRect];
	
	return newPath;
}

@end
