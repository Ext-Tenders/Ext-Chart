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
    if (presentationNeedsAssembly) {
        [self assemblePresentation];
        presentationNeedsAssembly = false;
    }

    return _presentation;
}

-(void) setPresentation:(EXTMatrix*)presentation {
    _presentation = presentation;
}

// this routine assembles from the available partial definitions of the
// differential a single definition on the cycle group.  it's a bit convoluted.
-(void) assemblePresentation {
    _presentation = [EXTMatrix assemblePresentation:partialDefinitions sourceDimension:start.size targetDimension:end.size];
    
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
        
        // discard this if it's the empty differential
        if (partial1.inclusion.width == 0)
            continue;
        
        for (EXTPartialDefinition *partial2 in reducedPartials) {
            if ([partial2 isEqual:partial1]) {
                discardThis = true;
                break;
            }
        }
        
        if (discardThis)
            continue;
        
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
