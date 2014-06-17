//
//  EXTNakamuraWindowController.m
//  Ext Chart
//
//  Created by Eric Peterson on 6/16/14.
//  Copyright (c) 2014 Harvard University. All rights reserved.
//

#import "EXTNakamuraWindowController.h"
#import "EXTMatrixEditor.h"
#import "EXTDocumentWindowController.h"
#import "EXTChartViewController.h"
#import "EXTDocument.h"

@interface EXTNakamuraWindowController ()

@property IBOutlet EXTMatrixEditor *editor;
@property IBOutlet NSTextField *field;
@property IBOutlet NSStepper *stepper;
@property IBOutlet NSButton *OKbutton;

@end

@implementation EXTNakamuraWindowController
{
    EXTDocumentWindowController *_documentWindowController;
}

@synthesize documentWindowController;

-(IBAction)OKPressed:(id)sender {
    //[_documentWindowController.extDocument.sseq propagateLeibniz:self.list page:self.documentWindowController.chartViewController.currentPage];
    [_documentWindowController.chartViewController reloadCurrentPage];
    
    [self close];
    return;
}

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        self.editor.representedObject = nil;
    }
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window
    // controller's window has been loaded from its nib file.
}

-(void)mouseDownAtGridLocation:(EXTIntPoint)gridLocation {
    return;
}

@end
