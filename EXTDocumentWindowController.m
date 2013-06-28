//
//  EXTDocumentWindowController.m
//  Ext Chart
//
//  Created by Bavarious on 31/05/2013.
//  Copyright (c) 2013 Harvard University. All rights reserved.
//

#import "EXTDocumentWindowController.h"
#import "EXTDocument.h"
#import "EXTterm.h"
#import "EXTdifferential.h"
#import "EXTChartView.h"
#import "EXTArtBoard.h"
#import "EXTScrollView.h"
#import "EXTSpectralSequence.h"

@interface EXTDocumentWindowController ()
    @property(nonatomic, weak) IBOutlet EXTChartView *chartView;
    @property(nonatomic, assign) NSUInteger maxPage;
    @property(nonatomic, readonly) EXTDocument *extDocument;
@end

@implementation EXTDocumentWindowController

#pragma mark - Life cycle

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

	// the big board is the bounds rectangle of the EXTChartView object, and is set in the xib file, so we initialize theGrid in the windowControllerDidLoadNib function.   HOWEVER, it screws up the binding of the text cell on the main document.  see the console

    // The analogue of these next settings 	 are done with bindings in Sketch.   I'm not sure what the difference is.
    self.chartView.sseq = [self.document sseq];
    self.chartView.delegate = self;

    [[self chartView] bind:EXTChartViewSseqBindingName toObject:[self document] withKeyPath:@"sseq" options:nil];

    // Offset the clip view a bit to the left and bottom so that the origin does not coincide with the window’s bottom-left corner,
    // making the art board border more noticeable.
    // Also, increase the initial scale factor
    EXTScrollView *scrollView = (EXTScrollView *)[_chartView enclosingScrollView];
    NSPoint clipViewOrigin = [[scrollView contentView] bounds].origin;
    clipViewOrigin.x -= 50.0;
    clipViewOrigin.y -= 50.0;
    [scrollView zoomToPoint:clipViewOrigin withScaling:2.0];
}

#pragma mark - Properties

- (void)setDocument:(NSDocument *)document
{
    NSAssert(!document || [document isKindOfClass:[EXTDocument class]], @"This window controller accepts EXTDocument documents only");

    if (document != [self document]) {
        if ([self document])
            [[self chartView] unbind:EXTChartViewSseqBindingName];
        
        [super setDocument:document];

        if (document)
            [[self chartView] bind:EXTChartViewSseqBindingName toObject:document withKeyPath:@"sseq" options:nil];
    }
}

- (EXTDocument *)extDocument
{
    return self.document;
}

#pragma  mark -

// this performs the culling and delegation calls for drawing a page of the SS
// TODO: does this need spacing to be passed in?  probably a lot of data passing
// needs to be investigated and untangled... :(
-(void) drawPageNumber:(NSUInteger)pageNumber ll:(NSPoint)lowerLeft
                    ur:(NSPoint)upperRight withSpacing:(CGFloat)withSpacing {
    // start by initializing the array of counts
    int width = (int)(upperRight.x - lowerLeft.x + 1),
        height = (int)(upperRight.y - lowerLeft.y + 1);
    NSMutableArray *counts = [NSMutableArray arrayWithCapacity:width];
    for (int i = 0; i < width; i++) {
        NSMutableArray *row = [NSMutableArray arrayWithCapacity:height];
        for (int j = 0; j < height; j++)
            [row setObject:@0 atIndexedSubscript:j];
        [counts setObject:row atIndexedSubscript:i];
    }
    
    // iterate through the available grid locations in the view. it's too bad
    // that this is slow.
    for (EXTTerm *term in self.extDocument.sseq.terms.allValues) {
        NSPoint point = [[term location] makePoint];
        
        if (point.x >= lowerLeft.x && point.x <= upperRight.x &&
            point.y >= lowerLeft.y && point.y <= upperRight.y) {
            NSMutableArray *column = (NSMutableArray*)counts[(int)(point.x-lowerLeft.x)];
            int offset = [column[(int)(point.y-lowerLeft.y)] intValue];
        
            [term drawWithSpacing:withSpacing page:pageNumber offset:offset];
        
            column[(int)(point.y-lowerLeft.y)] = @(offset + [term dimension:pageNumber]);
        }
    }

    // iterate also through the available differentials
    for (EXTDifferential* differential in self.extDocument.sseq.differentials) {
        if ([differential page] != pageNumber)
            continue;
        
        int targetPosition = 0;
        NSPoint target = [differential.end.location makePoint];
        
        if (target.x >= lowerLeft.x && target.x <= upperRight.x &&
            target.y >= lowerLeft.y && target.y <= upperRight.y) {
            NSMutableArray *column = (NSMutableArray*)counts[(int)(target.x-lowerLeft.x)];
            if ((int)(target.y-lowerLeft.y) < height)
                targetPosition = [column[(int)(target.y-lowerLeft.y)] intValue];
        }
        
        [differential drawWithSpacing:withSpacing targetPosition:targetPosition-1];
    }
}

-(void)drawPagesUpTo: (NSUInteger) pageNumber {
	;
}

#pragma mark - Actions

- (IBAction)exportArtBoard:(id)sender {
    NSData *artBoardPDFData = [_chartView dataWithPDFInsideRect:[[_chartView artBoard] frame]];

    NSSavePanel *savePanel = [NSSavePanel savePanel];
    [savePanel setNameFieldStringValue:[NSString stringWithFormat:@"page_%lu", [_chartView selectedPageIndex]]];
    [savePanel setAllowedFileTypes:@[@"pdf"]];
    [savePanel setAllowsOtherFileTypes:NO];

    [savePanel beginSheetModalForWindow:[self window] completionHandler:^(NSInteger result) {
        // TODO: error handling
        if (result == NSFileHandlingPanelOKButton)
            [artBoardPDFData writeToURL:[savePanel URL] atomically:YES];
    }];
}

#pragma mark ***view customization***

-(NSUInteger) maxPage {
    //	return [pages count] - 1;
    return 0; // XXX: what is this used for? fix it!
}

- (IBAction)demoGroups:(id)sender {
    [[self document] runDemo];
    [[self chartView] setSelectedPageIndex:0];
}

@end
