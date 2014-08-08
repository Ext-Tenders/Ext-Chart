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

#pragma mark - Private variables

static void *_EXTPresentationParametersContext = &_EXTPresentationParametersContext;

// redeclare part of the EXTDifferential interface so that we synthesize both
// getters *and* setters for the publicly read-only properties.
@interface EXTDifferential () {
    EXTMatrix *_presentation;
}

@property(strong) NSMutableArray *partialDefinitions;
@property(strong) EXTMatrix *presentation;

@end


// actual class housing the differential information
@implementation EXTDifferential {
    bool presentationNeedsAssembly;
}

@synthesize page;
@synthesize start, end;
@synthesize partialDefinitions;
@synthesize wellDefined;

- (instancetype)init {
    self = [super init];

    if (self) {
        presentationNeedsAssembly = true;
        [self addObserver:self forKeyPath:@"presentationParameters" options:0 context:_EXTPresentationParametersContext];
    }

    return self;
}

- (void)dealloc {
    [self removeObserver:self forKeyPath:@"presentationParameters" context:_EXTPresentationParametersContext];
}

- (instancetype)copyWithZone:(NSZone *)zone {
    EXTDifferential *ret = [EXTDifferential newDifferential:self.start end:self.end page:self.page];
    
    for (EXTPartialDefinition *p in self.partialDefinitions)
        [ret.partialDefinitions addObject:[p copy]];
    
    return ret;
}

+(instancetype) newDifferential:(EXTTerm *)start
                            end:(EXTTerm *)end
                           page:(int)page {
    EXTDifferential *object = [EXTDifferential new];
    
    object.start = start;
    object.end = end;
    object.page = page;
    
    [object setPresentation:[EXTMatrix matrixWidth:start.size height:end.size]];
    object.wellDefined = false;
    object.partialDefinitions = [NSMutableArray array];
    
    return object;
}

+(instancetype) differential:(EXTTerm *)start
                         end:(EXTTerm *)end
                        page:(int)page {
    EXTDifferential *differential =
        [EXTDifferential newDifferential:start end:end page:page];
    
    return differential;
}

// quietly assemble the presentation when asked for it :)
-(EXTMatrix*) presentation {
    //if (presentationNeedsAssembly) {
        [self assemblePresentation];
    //    presentationNeedsAssembly = false;
    //}

    return _presentation;
}

-(void) setPresentation:(EXTMatrix*)presentation {
    _presentation = presentation;
}

// this routine assembles from the available partial definitions of the
// differential a single definition on the cycle group.  it's a bit convoluted.
-(void) assemblePresentation {
    EXTMatrix *cycles, *boundaries;
    NSMutableArray *newPartials = [NSMutableArray array];
    int characteristic = 0;
    
    if (start.cycles.count > page)
        cycles = start.cycles[page];
    else
        cycles = [EXTMatrix identity:start.size];
    
    if (start.boundaries.count > page)
        boundaries = start.boundaries[page];
    else
        boundaries = [EXTMatrix matrixWidth:0 height:start.size];
    
    for (EXTPartialDefinition *partial in partialDefinitions) {
        characteristic = partial.inclusion.characteristic;
        NSArray *pair = [EXTMatrix formIntersection:cycles
                                               with:partial.inclusion];
        EXTPartialDefinition *newPartial = [EXTPartialDefinition new];
        newPartial.inclusion = pair[0];
        newPartial.inclusion.characteristic = partial.inclusion.characteristic;
        newPartial.action = [EXTMatrix newMultiply:partial.action by:pair[1]];
        newPartial.action.characteristic = partial.action.characteristic;
        newPartial.description = partial.description;
        [newPartials addObject:newPartial];
    }
    
    EXTPartialDefinition *boundaryPartial = [EXTPartialDefinition new];
    EXTMatrix *boundariesInCycleCoords =
                [EXTMatrix formIntersection:boundaries with:cycles][1];
    boundaryPartial.inclusion = boundariesInCycleCoords;
    boundaryPartial.action = [EXTMatrix matrixWidth:boundaries.width
                                             height:end.size];
    boundaryPartial.inclusion.characteristic = characteristic;
    boundaryPartial.action.characteristic = characteristic;
    boundaryPartial.description = @"differential is null on boundaries";
    [newPartials addObject:boundaryPartial];
    
    _presentation = [EXTMatrix assemblePresentation:newPartials
                                    sourceDimension:cycles.width
                                    targetDimension:end.size];
    
    if (_presentation.height != end.size ||
        _presentation.width != cycles.width)
        NSLog(@"strange assembly dimensions.");
    
    return;
}

// TODO: ideally, this would check for definitional overlap, rather than literal
// partial-by-partial equality.  it would also ideally be moved into a place
// where it can also act on EXTMultiplicationEntry; there's nothing specific
// about this routine to EXTDifferential.
-(void) stripDuplicates {
    NSMutableArray *reducedPartials = [NSMutableArray array];
    EXTMatrix *inclusionSum = [EXTMatrix matrixWidth:0 height:self.start.size];
    EXTMatrix *workingImage = [EXTMatrix matrixWidth:0 height:self.start.size];
    
    for (EXTPartialDefinition *partial1 in self.partialDefinitions) {
        EXTMatrix *testMatrix = [inclusionSum copy];
        testMatrix.characteristic = partial1.inclusion.characteristic;
        
        [partial1.inclusion modularReduction];
        [partial1.action modularReduction];
        
        [testMatrix.presentation appendData:partial1.inclusion.presentation];
        testMatrix.width += partial1.inclusion.width;
        EXTMatrix *image = [testMatrix image];
        
        if ([image isEqualTo:workingImage])
            continue;
        
        inclusionSum = testMatrix;
        workingImage = image;
        [reducedPartials addObject:partial1];
    }
    
    self.partialDefinitions = reducedPartials;
}

// TODO: the real goal for this guy was to check whether the partialDefinitions
// were ever in conflict.  this means computing pullbacks along common inclusion
// subspaces and then checking that the restriction of the action matrix to
// the common space agrees for every pair of EXTPartialDefinitions.
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
- (instancetype) initWithCoder: (NSCoder*) coder {
	if (self = [super init])
	{
        start = [coder decodeObjectForKey:@"start"];
		end = [coder decodeObjectForKey:@"end"];
		page = [coder decodeIntForKey:@"page"];
        partialDefinitions = [coder decodeObjectForKey:@"partialDefinitions"];

        presentationNeedsAssembly = true;
        [self addObserver:self forKeyPath:@"presentationParameters" options:0 context:_EXTPresentationParametersContext];
	}
	return self;
}

- (void) encodeWithCoder:(NSCoder*) coder {
	[coder encodeObject:start.location forKey:@"start"];
	[coder encodeObject:end.location forKey:@"end"];
	[coder encodeInt:page forKey:@"page"];
    [coder encodeObject:partialDefinitions forKey:@"partialDefinitions"];
}

#pragma mark - Key-Value Observing

+ (NSSet *)keyPathsForValuesAffectingPresentationParameters {
    return [NSSet setWithObjects:@"start", @"end", @"partialDefinitions", nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (context == _EXTPresentationParametersContext)
        presentationNeedsAssembly = true;
    else
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

@end
