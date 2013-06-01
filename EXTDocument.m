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
    }

    @property(nonatomic, weak) IBOutlet EXTView *extview;
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
    
    [self.extview setPageInView:1];
    [self.extview setPageInView:2];
    [self.extview setPageInView:0];
    
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
	
	[self.theGrid setBoundsRect:[self.extview bounds]];
	
// The analogue of these next settings 	 are done with bindings in Sketch.   I'm not sure what the difference is.
	[self.extview setDelegate:self];
	[self.extview setArtBoard:self.theArtBoard];
	[self.extview set_grid:self.theGrid];
	
// since the frame extends past the bounds rectangle, we need observe the drawingRect in order to know what to refresh when the artBoard changes
	
	[self.theArtBoard addObserver: self.extview forKeyPath:EXTArtBoardDrawingRectKey options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:nil];
	[self.theGrid addObserver:self.extview forKeyPath:EXTGridAnyKey options:0 context:nil];

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
-(void) drawPageNumber:(NSUInteger)pageNumber ll:(NSPoint)lowerLeft
                    ur:(NSPoint)upperRight withSpacing:(CGFloat)withSpacing {
    
    // iterate through the available terms
    for (EXTTerm *term in [self.sseq terms]) {
        // if we're out of the viewing rectangle, then skip it
        NSPoint point = [[term location] makePoint];
        if ((point.x <= lowerLeft.x)  ||
            (point.y <= lowerLeft.y)  ||
            (point.x >= upperRight.x) ||
            (point.y >= upperRight.y))
            continue;
        
        // otherwise, we're obligated to try to draw it
        // TODO: this still seems like it's put in the wrong place...
        [term drawWithSpacing:withSpacing page:pageNumber];
    }
    
    // iterate also through the available differentials
    for (EXTDifferential* differential in [self.sseq differentials]) {
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
