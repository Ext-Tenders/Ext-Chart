//
//  EXTDocument.m
//  Ext Chart
//
//  Created by Michael Hopkins on 7/20/11.
//  Copyright 2011 Harvard. All rights reserved.
//

#import "EXTDocument.h"
#import "EXTView.h"
#import "EXTGrid.h"
#import "EXTArtBoard.h"
#import "EXTterm.h"
#import "EXTPair.h"
#import "EXTdifferential.h"
#import "EXTMultiplicationTables.h"


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

        IBOutlet EXTView *extview;
    }
    
@end

@implementation EXTDocument

#pragma mark *** initialization and dealloc ***

- (id)init {
    // upcall.
    self = [super init];
    
    // if we succeeded...
    if (self) {
        // allocate the display parts of things
		_theArtBoard = [[EXTArtBoard alloc] initWithRect:NSMakeRect(0, 0, 792, 612)];
        
        // and allocate the internal parts of things
        [self setTerms:[NSMutableArray array]];
        [self setDifferentials:[NSMutableArray array]];
        [self setMultTables:[EXTMultiplicationTables multiplicationTables:self]];
    }

    return self;
}

// if requested, we can initialize the terms array with some test garbage
-(void) randomize {
    // remove all the old garbage
    [self setTerms:[NSMutableArray array]];
    [self setDifferentials:[NSMutableArray array]];

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
                         
        [self.terms addObject:term];
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
    
    [self.terms addObjectsFromArray:@[one,e,x,ex,x2,ex2]];
    
    [extview setPageInView:1];
    [extview setPageInView:2];
    [extview setPageInView:0];
    
    // add a single differential
    EXTDifferential *firstdiff = [EXTDifferential differential:e end:x page:2];
    EXTPartialDifferential *firstpartial = [EXTPartialDifferential new];
    EXTMatrix *inclusion = [EXTMatrix matrixWidth:1 height:1];
    EXTMatrix *differential = [EXTMatrix matrixWidth:1 height:1];
    [[inclusion.presentation objectAtIndex:0] setObject:@1 atIndex:0];
    [[differential.presentation objectAtIndex:0] setObject:@1 atIndex:0];
    firstpartial.inclusion = inclusion;
    firstpartial.differential = differential;
    firstdiff.partialDefinitions[0] = firstpartial;
    [self.differentials addObject:firstdiff];
    
    // TODO: need to assemble the cycle groups for lower pages first...
    [firstdiff assemblePresentation]; // test!
    
    // specify the multiplicative structure
    [[self.multTables getMatrixFor:[e location] with:[x location]].presentation setObject:@[@1] atIndexedSubscript:0];
    [[self.multTables getMatrixFor:[ex location] with:[x location]].presentation setObject:@[@1] atIndexedSubscript:0];
    [[self.multTables getMatrixFor:[e location] with:[x2 location]].presentation setObject:@[@1] atIndexedSubscript:0];
    [[self.multTables getMatrixFor:[x location] with:[e location]].presentation setObject:@[@1] atIndexedSubscript:0];
    [[self.multTables getMatrixFor:[x location] with:[ex location]].presentation setObject:@[@1] atIndexedSubscript:0];
    [[self.multTables getMatrixFor:[x2 location] with:[e location]].presentation setObject:@[@1] atIndexedSubscript:0];
    [[self.multTables getMatrixFor:[x location] with:[x location]].presentation setObject:@[@1] atIndexedSubscript:0];

    
    [self.multTables computeLeibniz:[e location] with:[x location] onPage:2];
    
    return;
}

-(EXTTerm*) findTerm:(EXTPair *)loc {
    for (EXTTerm *term in self.terms) {
        if ([loc isEqual:[term location]])
            return term;
    }
    
    return nil;
}

-(EXTDifferential*) findDifflWithSource:(EXTPair *)loc onPage:(int)page {
    for (EXTDifferential *diffl in self.differentials)
        if (([[diffl start] location] == loc) && ([diffl page] == page))
            return diffl;
    
    return nil;
}

-(EXTDifferential*) findDifflWithTarget:(EXTPair *)loc onPage:(int)page {
    for (EXTDifferential *diffl in self.differentials)
        if (([[diffl end] location] == loc) && ([diffl page] == page))
            return diffl;
    
    return nil;
}

#pragma mark *** windowController tasks ***

- (NSString *)windowNibName {
    return @"EXTDocument";
}

- (void)windowControllerDidLoadNib:(NSWindowController *) aController
{
    [super windowControllerDidLoadNib:aController];
	// the big board is the bounds rectangle of the EXTView object, and is set in the xib file, so we initialize theGrid in the windowControllerDidLoadNib function.   HOWEVER, it screws up the binding of the text cell on the main document.  see the console
	
//	theGrid = [EXTGrid alloc];
//	[theGrid initWithRect:[extview bounds]];
	
	[self.theGrid setBoundsRect:[extview bounds]];
	
// The analogue of these next settings 	 are done with bindings in Sketch.   I'm not sure what the difference is.
	[extview setDelegate:self];
	[extview setArtBoard:self.theArtBoard];
	[extview set_grid:self.theGrid];
	
// since the frame extends past the bounds rectangle, we need observe the drawingRect in order to know what to refresh when the artBoard changes
	
	[self.theArtBoard addObserver: extview forKeyPath:EXTArtBoardDrawingRectKey options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:nil];
	[self.theGrid addObserver:extview forKeyPath:EXTGridAnyKey options:0 context:nil];

//	[self setEmphasisGridSpacing:8];		
}

#pragma mark ***document saving and loading / TODO: THESE ARE DISABLED ***

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

#pragma mark ***Drawing***

// this performs the culling and delegation calls for drawing a page of the SS
// TODO: does this need spacing to be passed in?  probably a lot of data passing
// needs to be investigated and untangled... :(
-(void) drawPageNumber:(NSUInteger)pageNumber ll:(EXTPair*)lowerLeft
                    ur:(EXTPair*)upperRight withSpacing:(CGFloat)withSpacing {
    
    // iterate through the available terms
    for (EXTTerm *term in [self terms]) {
        // if we're out of the viewing rectangle, then skip it
        if (([[term location] a] <= [lowerLeft a])  ||
            ([[term location] b] <= [lowerLeft b])  ||
            ([[term location] a] >= [upperRight a]) ||
            ([[term location] b] >= [upperRight b]))
            continue;
        
        // otherwise, we're obligated to try to draw it
        // TODO: this still seems like it's put in the wrong place...
        [term drawWithSpacing:withSpacing page:pageNumber];
    }
    
    // iterate also through the available differentials
    for (EXTDifferential* differential in [self differentials]) {
        if ([differential page] == pageNumber)
            [differential drawWithSpacing:withSpacing];
    }
}

-(void)drawPagesUpTo: (NSUInteger) pageNumber {
	;
}

#pragma mark ***view customization***

-(NSUInteger) maxPage {
//	return [pages count] - 1;
    return 0; // XXX: what is this used for? fix it!
}

#pragma mark ***probably controller methods ****



@end
