//
//  EXTDocumentWindowController.m
//  Ext Chart
//
//  Created by Bavarious on 31/05/2013.
//  Copyright (c) 2013 Harvard University. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "EXTDocumentWindowController.h"
#import "EXTDocument.h"
#import "EXTTerm.h"
#import "EXTDifferential.h"
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

#pragma mark -

-(NSArray*) dotPositions:(int)count
                       x:(CGFloat)x
                       y:(CGFloat)y
                 spacing:(CGFloat)spacing {
    
    switch (count) {
        case 1:
            return @[[NSValue valueWithRect:
                      NSMakeRect(x*spacing + 2.0/6.0*spacing,
                                 y*spacing + 2.0/6.0*spacing,
                                 2.0*spacing/6.0,
                                 2.0*spacing/6.0)]];
            
        case 2:
            return @[[NSValue valueWithRect:
                      NSMakeRect(x*spacing + 1.0/6.0*spacing,
                                 y*spacing + 1.0/6.0*spacing,
                                 2.0*spacing/6.0,
                                 2.0*spacing/6.0)],
                     [NSValue valueWithRect:
                      NSMakeRect(x*spacing + 3.0/6.0*spacing,
                                 y*spacing + 3.0/6.0*spacing,
                                 2.0*spacing/6.0,
                                 2.0*spacing/6.0)]];
            
        case 3:
            return @[[NSValue valueWithRect:
                      NSMakeRect(x*spacing + 0.66/6.0*spacing,
                                 y*spacing + 1.0/6.0*spacing,
                                 2.0*spacing/6.0,
                                 2.0*spacing/6.0)],
                     [NSValue valueWithRect:
                      NSMakeRect(x*spacing + 2.0/6.0*spacing,
                                 y*spacing + 3.0/6.0*spacing,
                                 2.0*spacing/6.0,
                                 2.0*spacing/6.0)],
                     [NSValue valueWithRect:
                      NSMakeRect(x*spacing + 3.33/6.0*spacing,
                                 y*spacing + 1.0/6.0*spacing,
                                 2.0*spacing/6.0,
                                 2.0*spacing/6.0)]];
            
        default:
            return @[[NSValue valueWithRect:
                      NSMakeRect(x*spacing+0.15*spacing,
                                 y*spacing+0.15*spacing,
                                 0.7*spacing,
                                 0.7*spacing)]];
    }
}

// this performs the culling and delegation calls for drawing a page of the SS
// TODO: does this need spacing to be passed in?  probably a lot of data passing
// needs to be investigated and untangled... :(
-(void) drawPageNumber:(NSUInteger)pageNumber ll:(NSPoint)lowerLeft
                    ur:(NSPoint)upperRight withSpacing:(CGFloat)spacing {
    // start by initializing the array of counts.  each element is a pair, the
    // first of which is the total number of dots in the grid, and the second of
    // which is the number which have been 'used' by differentials on this page.
    int width = (int)(upperRight.x - lowerLeft.x + 1),
        height = (int)(upperRight.y - lowerLeft.y + 1);
    NSMutableArray *counts = [NSMutableArray arrayWithCapacity:width];
    for (int i = 0; i < width; i++) {
        NSMutableArray *row = [NSMutableArray arrayWithCapacity:height];
        for (int j = 0; j < height; j++)
            [row setObject:[NSMutableArray arrayWithArray:@[@0, @0]] atIndexedSubscript:j];
        [counts setObject:row atIndexedSubscript:i];
    }
    
    // iterate through the available EXTTerms and count up how many project onto
    // a given grid location.  (this is a necessary step for, e.g., EXTTriple-
    // graded spectral sequences, where many EXTLocations might end up in the
    // same place.)
    //
    // TODO: the way this is set up does not allow EXTTerms to determine how
    // they get drawn.  this will probably need to be changed when we move to
    // Z-mods, since those have lots of interesting quotients which need to
    // represented visually.
    for (EXTTerm *term in self.extDocument.sseq.terms.allValues) {
        NSPoint point = [[term location] makePoint];
        
        if (point.x >= lowerLeft.x && point.x <= upperRight.x &&
            point.y >= lowerLeft.y && point.y <= upperRight.y) {
            NSMutableArray *column = (NSMutableArray*)counts[(int)(point.x-lowerLeft.x)];
            NSMutableArray *tuple = column[(int)(point.y-lowerLeft.y)];
            int offset = [tuple[0] intValue];
            tuple[0] = @(offset + [term dimension:pageNumber]);
        }
    }
    
    // actually loop through the available positions and perform the draw.
    [[NSColor blackColor] set];
    for (int i = (int)lowerLeft.x; i <= upperRight.x; i++) {
        NSArray *column = (NSArray*)counts[i - (int)lowerLeft.x];
        for (int j = (int)lowerLeft.y; j <= upperRight.y; j++) {
            NSArray *tuple = column[j - (int)lowerLeft.y];
            int count = [tuple[0] intValue];
            
            if (count == 0)
                continue;
            
            NSArray *dotPositions = [self dotPositions:count
                                                     x:(float)i
                                                     y:(float)j
                                               spacing:spacing];
            
            NSBezierPath* path = [NSBezierPath new];
            
            if (count <= 3) {
                for (int i = 0; i < count; i++)
                    [path appendBezierPathWithOvalInRect:
                                                [dotPositions[i] rectValue]];
                
                [path fill];
            } else {
                NSFont *font = [NSFont fontWithName:@"Palatino-Roman"
                                               size:5.0];
                NSDictionary *attrsDictionary = [NSDictionary dictionaryWithObject:font forKey:NSFontAttributeName];
                NSAttributedString *output = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%d",count] attributes:attrsDictionary];
            
                // XXX: this probably breaks for multidigit numbers.
                [output drawAtPoint:NSMakePoint(spacing*(float)i+2.3/6.0*spacing,
                                                spacing*(float)j+0.6/6.0*spacing)];
            
                [[NSColor blackColor] set];
                [path appendBezierPathWithOvalInRect:[dotPositions[0] rectValue]];
                [path stroke];
            }
        }
    }

    // iterate also through the available differentials
    if (pageNumber >= self.extDocument.sseq.differentials.count)
        return;
    
    [[NSColor blackColor] set];
    for (NSArray* key in self.extDocument.sseq.differentials[pageNumber]) {
        EXTDifferential *differential = [self.extDocument.sseq.differentials[pageNumber] objectForKey:key];
        // some sanity checks to make sure this differential is worth drawing
        if ([differential page] != pageNumber)
            continue;
        
        int imageSize = [differential.presentation image].count;
        if ((imageSize == 0) ||
            ([differential.start dimension:differential.page] == 0) ||
            ([differential.end dimension:differential.page] == 0))
            continue;
        
        // figure out the various parameters needed to build the draw commands:
        // where the dots are, how many there are, and so on.
        NSMutableArray
            *startPosition = [NSMutableArray arrayWithArray:@[@0, @0]],
            *endPosition = [NSMutableArray arrayWithArray:@[@0, @0]];
        NSPoint start = [differential.start.location makePoint],
                end = [differential.end.location makePoint];
        
        if (start.x >= lowerLeft.x && start.x <= upperRight.x &&
            start.y >= lowerLeft.y && start.y <= upperRight.y) {
            NSMutableArray *column = (NSMutableArray*)counts[(int)(start.x-lowerLeft.x)];
            if ((int)(start.y-lowerLeft.y) < height)
                startPosition = column[(int)(start.y-lowerLeft.y)];
        }
        
        if (end.x >= lowerLeft.x && end.x <= upperRight.x &&
            end.y >= lowerLeft.y && end.y <= upperRight.y) {
            NSMutableArray *column = (NSMutableArray*)counts[(int)(end.x-lowerLeft.x)];
            if ((int)(end.y-lowerLeft.y) < height)
                endPosition = column[(int)(end.y-lowerLeft.y)];
        }
        
        NSPoint pointStart = [differential.start.location makePoint],
                  pointEnd = [differential.end.location makePoint];
        
        NSArray *startRects = [self dotPositions:[startPosition[0] intValue]
                                               x:pointStart.x
                                               y:pointStart.y
                                         spacing:spacing],
                *endRects = [self dotPositions:[endPosition[0] intValue]
                                             x:pointEnd.x
                                             y:pointEnd.y
                                       spacing:spacing];
        
        for (int i = 0; i < imageSize; i++) {
            // get and update the offsets
            int startOffset = [startPosition[1] intValue],
                endOffset = [endPosition[1] intValue];
            startPosition[1] = @(startOffset+1);
            endPosition[1] = @(endOffset+1);
            
            // if they're out of bounds, which will happen in the >= 4 case,
            // just use the bottom one.
            if (startOffset >= startRects.count)
                startOffset = 0;
            if (endOffset >= endRects.count)
                endOffset = 0;
            
            NSRect startRect = [startRects[startOffset] rectValue],
                   endRect = [endRects[endOffset] rectValue];
            
            NSBezierPath *line = [NSBezierPath bezierPath];
            [line moveToPoint:
                NSMakePoint(startRect.origin.x,
                            startRect.origin.y + startRect.size.height/2)];
            [line lineToPoint:
                NSMakePoint(endRect.origin.x + endRect.size.width,
                            endRect.origin.y + endRect.size.height/2)];
            [line setLineWidth:0.25];
            [line stroke];
        }
    }
    
    // TODO: draw certain multiplicative structures?
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
