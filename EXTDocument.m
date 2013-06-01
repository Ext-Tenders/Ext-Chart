//
//  EXTDocument.m
//  Ext Chart
//
//  Created by Michael Hopkins on 7/20/11.
//  Copyright 2011 Harvard University. All rights reserved.
//

#import "EXTDocument.h"
#import "EXTView.h"
#import "EXTGrid.h"
#import "EXTArtBoard.h"
#import "EXTterm.h"
#import "EXTPair.h"
#import "EXTdifferential.h"
#import "EXTMultiplicationTables.h"
#import "EXTDocumentWindowController.h"


@interface EXTDocument ()
    {
        // view configuration
        CGFloat gridSpacing;
        CGFloat gridScalingFactor;
        NSSize extDocumentSize;
        NSPoint extDocumentOrigin;
        //	extern CGFloat gridSpacing;
        //	extern NSRect canvasRect;
        NSColor *gridLineColor;
        NSColor *emphasGridLineColor;
    }

    @property(nonatomic, weak) EXTDocumentWindowController *windowController;
@end

@implementation EXTDocument

#pragma mark - Lifecycle

- (id)init {
    // upcall.
    self = [super init];
    
    // if we succeeded...
    if (self) {
        // allocate the display parts of things
        
        _sseq = [EXTSpectralSequence spectralSequence];
    }

    return self;
}

// if requested, we can initialize the terms array with some test garbage
-(void) randomize {
    // remove all the old garbage
    [self.sseq setTerms:[NSMutableArray array]];
    [self.sseq setDifferentials:[NSMutableArray array]];
    [self.sseq setIndexClass:[EXTPair class]];

    // this old test code initializes the grid with some random stuff.  that's
    // neat, but it's not organized enough to test the multiplicative structure,
    // so i'm going to skip it for now.

    
    // add some new garbage.
    // TODO: this ought to randomize the dimension too.
    // XXX: this doesn't catch collisions.
    for(int i = 0; i < 40; i++) {
        EXTPair *location = [EXTPair pairWithA:(arc4random()%30)
                                             B:(arc4random()%30)];
        NSArray *names = nil;
        
        if ((location.a < 2) || (location.b < 5))
            continue;
        
        switch ((arc4random()%7)+1) {
            case 1:
                names = @[@"x"];
                break;
            case 2:
                names = @[@"x", @"y"];
                break;
            case 3:
                names = @[@"x", @"y", @"z"];
                break;
            case 4:
                names = @[@"x", @"y", @"z", @"s"];
                break;
            case 5:
                names = @[@"x", @"y", @"z", @"s", @"t"];
                break;
            case 6:
                names = @[@"x", @"y", @"z", @"s", @"t", @"u"];
                break;
            case 7:
            default:
                names = @[@"x", @"y", @"z", @"s", @"t", @"u", @"v"];
                break;
        }
        
        EXTTerm *term = [EXTTerm term:location andNames:[NSMutableArray arrayWithArray:names]];
                         
        [self.sseq.terms addObject:term];
    }
    
    // add the terms in the SSS for S^1 --> S^5 --> CP^2
    EXTTerm *e   = [EXTTerm term:[EXTPair pairWithA:1 B:0]
                        andNames:[NSMutableArray arrayWithArray:@[@"e"]]],
            *x   = [EXTTerm term:[EXTPair pairWithA:0 B:2]
                        andNames:[NSMutableArray arrayWithArray:@[@"x"]]],
            *ex  = [EXTTerm term:[EXTPair pairWithA:1 B:2]
                        andNames:[NSMutableArray arrayWithArray:@[@"ex"]]],
            *x2  = [EXTTerm term:[EXTPair pairWithA:0 B:4]
                        andNames:[NSMutableArray arrayWithArray:@[@"x2"]]],
            *ex2 = [EXTTerm term:[EXTPair pairWithA:1 B:4]
                        andNames:[NSMutableArray arrayWithArray:@[@"ex2"]]],
            *one = [EXTTerm term:[EXTPair pairWithA:0 B:0]
                        andNames:[NSMutableArray arrayWithArray:@[@"1"]]];
    
    [self.sseq.terms addObjectsFromArray:@[one,e,x,ex,x2,ex2]];
    
    // TODO: review why this is necessary
    [self.windowController setPageInView:1];
    [self.windowController setPageInView:2];
    [self.windowController setPageInView:0];
    
    // add a single differential
    EXTDifferential *firstdiff = [EXTDifferential differential:e end:x page:2];
    EXTPartialDefinition *firstpartial = [EXTPartialDefinition new];
    EXTMatrix *inclusion = [EXTMatrix matrixWidth:1 height:1];
    EXTMatrix *differential = [EXTMatrix matrixWidth:1 height:1];
    [[inclusion.presentation objectAtIndex:0] setObject:@1 atIndex:0];
    [[differential.presentation objectAtIndex:0] setObject:@1 atIndex:0];
    firstpartial.inclusion = inclusion;
    firstpartial.differential = differential;
    firstdiff.partialDefinitions[0] = firstpartial;
    [self.sseq.differentials addObject:firstdiff];
    
    // TODO: need to assemble the cycle groups for lower pages first...
    [firstdiff assemblePresentation]; // test!
    
    // specify the multiplicative structure
    EXTMatrix *matrix = [EXTMatrix matrixWidth:1 height:1];
    [matrix.presentation[0] setObject:@1 atIndex:0];
    EXTPartialDefinition *partialDefinition = [[EXTPartialDefinition alloc] init];
    partialDefinition.inclusion = matrix;
    partialDefinition.differential = matrix;
    [self.sseq.multTables addPartialDefinition:partialDefinition to:[e location] with:[x location]];
    [self.sseq.multTables addPartialDefinition:partialDefinition to:[ex location] with:[x location]];
    [self.sseq.multTables addPartialDefinition:partialDefinition to:[e location] with:[x2 location]];
    [self.sseq.multTables addPartialDefinition:partialDefinition to:[x location] with:[e location]];
    [self.sseq.multTables addPartialDefinition:partialDefinition to:[x location] with:[ex location]];
    [self.sseq.multTables addPartialDefinition:partialDefinition to:[x2 location] with:[e location]];
    [self.sseq.multTables addPartialDefinition:partialDefinition to:[x location] with:[x location]];
    
    [self.sseq.multTables computeLeibniz:[e location] with:[x location] onPage:2];
    
    return;
}

#pragma mark - Window controllers

- (void)makeWindowControllers
{
    [self addWindowController:[EXTDocumentWindowController new]];
}

- (EXTDocumentWindowController *)windowController
{
    return (self.windowControllers.count == 1 ? self.windowControllers[0] : nil);
}

#pragma mark - Document saving and loading / TODO: THESE ARE DISABLED ***

- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError
{
    if ( outError != NULL ) {
		*outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:unimpErr userInfo:NULL];
	}
//	return[NSKeyedArchiver archivedDataWithRootObject:[self pages]];
    return nil;
}

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError
{
	if ( outError != NULL ) {
		*outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:unimpErr userInfo:NULL];
	}

	// TODO: review this
//	NSArray* arr = [NSKeyedUnarchiver unarchiveObjectWithData:data];
//	NSMutableArray* marr = [arr mutableCopy];
//	
//	[self setPages:marr];
    return YES;
}

@end
