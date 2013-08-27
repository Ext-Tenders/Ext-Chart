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
    NSArray *pair =
        [EXTMatrix assemblePresentationAndOptimize:partialDefinitions sourceDimension:start.size targetDimension:end.size];
    _presentation = pair[0];
    partialDefinitions = pair[1];
    
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
        [partial1.action modularReduction];
        
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
        if (partial.inclusion.width != partial.action.width)
            return false;
        if (partial.inclusion.height != start.size)
            return false;
        if (partial.action.height != end.size)
            return false;
    }
    
    return true;
}

// IMPORTANT NOTE: this DOESN'T actually return a properly initialized object.
// instead, the start and end pointers are set to the EXTLocation of the term
// they refer to.  this must be dereferenced before storing the differential.
- (id) initWithCoder: (NSCoder*) coder {
	if (self = [super init])
	{
        start = [coder decodeObjectForKey:@"start"];
		end = [coder decodeObjectForKey:@"end"];
		page = [coder decodeIntForKey:@"page"];
        partialDefinitions = [coder decodeObjectForKey:@"partialDefinitions"];
	}
	return self;
}

- (void) encodeWithCoder:(NSCoder*) coder {
	[coder encodeObject:start.location forKey:@"start"];
	[coder encodeObject:end.location forKey:@"end"];
	[coder encodeInt:page forKey:@"page"];
    [coder encodeObject:partialDefinitions forKey:@"partialDefinitions"];
}

#pragma mark *** overridden EXTTool methods***

+ (NSBezierPath *)makeHighlightPathAtPoint:(NSPoint)point onGrid:(EXTGrid *)grid onPage:(NSInteger)page locClass:(Class<EXTLocation>)locClass {
    // TODO: why does +followDifflForDisplay:page:spacing: needs grid spacing?
    const NSPoint targetPoint = [locClass followDifflForDisplay:point page:page spacing:[grid gridSpacing]];

    const NSRect baseGridSquareRect = [grid viewBoundingRectForGridPoint:[grid convertPointFromView:point]];
    const NSRect targetGridSquareRect = [grid viewBoundingRectForGridPoint:[grid convertPointFromView:targetPoint]];

	NSBezierPath *newPath = [NSBezierPath bezierPathWithRect:baseGridSquareRect];
	[newPath appendBezierPathWithRect:targetGridSquareRect];
	
	return newPath;
}

@end
