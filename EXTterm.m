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
#import "EXTDOcument.h"

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
        [self setBoundaries:[[NSMutableArray alloc]initWithObjects: nil]];
        [self setCycles:[[NSMutableArray alloc]initWithObjects: nil]];
        
        // XXX: this is just being used for testing.
        int numberOfNames = arc4random() % 8;
        NSMutableArray *randomNames = [[NSMutableArray alloc] initWithCapacity:numberOfNames];
        for (int j = 0; j < numberOfNames; j++)
            [randomNames setObject:@"x" atIndexedSubscript:j];
        [self setNames:randomNames];
    }
    
    // regardless, return the object as best we've initialized it.
    return self;
}

// build a new EXTTerm object and initialize it
+(id) newTerm:(EXTPair*)whichLocation andNames:(NSMutableArray*)whichNames {
    EXTTerm* term = [[EXTTerm alloc]setTerm:whichLocation andNames:whichNames];
    
    return [term autorelease];
}

// decrement the reference counts for all the members we control
- (void) dealloc {
    [names release];      // NOTE: Cocoa containers are such that if the
    [boundaries release]; // container gets released, then a release message is
    [cycles release];     // sent to all its elements as well.  Useful!
    
    [location release];
    
    // lastly, up-call.
	[super dealloc];
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

+ (NSBezierPath *) makeHighlightPathAtPoint: (NSPoint)point onGrid:(EXTGrid *)theGrid onPage:(NSInteger)thePage{
	return [[NSBezierPath bezierPathWithRect:[theGrid enclosingGridRect:point]] retain];
}

#pragma mark *** not yet sure how to classify this (it's an init, in some sense) ***

+ (id) sumOfTerms:(EXTTerm *)termOne and:(EXTTerm *)termTwo{
	return nil; // allowed?
}

-(int) dimension:(int)whichPage {
    // XXX: this is just for testing!  it ought to be computing something.
    //return (arc4random() % 8);
    return [[self names] count];
}

+(id) dealWithClick:(NSPoint)location document:(EXTDocument*)document {
    EXTPair	*pointPair = [EXTPair pairWithA:location.x B:location.y];
    EXTTerm *term = [EXTTerm newTerm:pointPair
                            andNames:[[NSMutableArray alloc] init]];

    [[document terms] addObject:term];
    
    return term;
}

@end
