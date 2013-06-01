//
//  EXTDocumentWindowController.m
//  Ext Chart
//
//  Created by Bavarious on 31/05/2013.
//  Copyright (c) 2013 HLProducts. All rights reserved.
//

#import "EXTDocumentWindowController.h"
#import "EXTDocument.h"
#import "EXTterm.h"
#import "EXTdifferential.h"
#import "EXTView.h"
#import "EXTArtBoard.h"
#import "EXTGrid.h"

@interface EXTDocumentWindowController ()
@property(nonatomic, weak) IBOutlet EXTView *extView;
@property(nonatomic, strong) IBOutlet EXTGrid *grid;
@property(nonatomic, strong) EXTArtBoard *artBoard;

@property(nonatomic, assign) CGFloat artboardRectX;
@property(nonatomic, assign) NSUInteger maxPage;

@property(nonatomic, readonly) EXTDocument *extDocument;
@end

@implementation EXTDocumentWindowController

- (id)init
{
    return [super initWithWindowNibName:@"EXTDocument"];
}

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];

    self.artBoard = [[EXTArtBoard alloc] initWithRect:NSMakeRect(0, 0, 792, 612)];
    
	// the big board is the bounds rectangle of the EXTView object, and is set in the xib file, so we initialize theGrid in the windowControllerDidLoadNib function.   HOWEVER, it screws up the binding of the text cell on the main document.  see the console

    //	theGrid = [EXTGrid alloc];
    //	[theGrid initWithRect:[extview bounds]];

    self.grid.boundsRect = self.extView.bounds;

    // The analogue of these next settings 	 are done with bindings in Sketch.   I'm not sure what the difference is.
    self.extView.dataSource = self.document;
    self.extView.delegate = self;
    self.extView.artBoard = self.artBoard;
    self.extView._grid = self.grid;

    // since the frame extends past the bounds rectangle, we need observe the drawingRect in order to know what to refresh when the artBoard changes

	[self.artBoard addObserver:self.extView forKeyPath:EXTArtBoardDrawingRectKey options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:nil];
	[self.grid addObserver:self.extView forKeyPath:EXTGridAnyKey options:0 context:nil];

    //	[self setEmphasisGridSpacing:8];
}

- (EXTDocument *)extDocument
{
    return self.document;
}

- (void)setPageInView:(int)newPage
{
    self.extView.pageInView = newPage;
}

// this performs the culling and delegation calls for drawing a page of the SS
// TODO: does this need spacing to be passed in?  probably a lot of data passing
// needs to be investigated and untangled... :(
-(void) drawPageNumber:(NSUInteger)pageNumber ll:(NSPoint)lowerLeft
                    ur:(NSPoint)upperRight withSpacing:(CGFloat)withSpacing {

    // iterate through the available terms
    for (EXTTerm *term in self.extDocument.sseq.terms) {
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
    for (EXTDifferential* differential in self.extDocument.sseq.differentials) {
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

- (IBAction) randomGroups:(id)sender{
    [[self document] randomize];
	[_extView setNeedsDisplay:YES];
}

@end
