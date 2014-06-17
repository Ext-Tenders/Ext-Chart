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

@interface EXTNakamuraWindowController () <NSTextFieldDelegate>

@property IBOutlet EXTMatrixEditor *editor;
@property IBOutlet NSTextField *field;
@property IBOutlet NSStepper *stepper;
@property IBOutlet NSButton *OKbutton;

@property (assign) int degree;

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

-(IBAction)changeDegreeValue:(id)sender {
    self.degree = [sender intValue];
    [self.field setIntegerValue:self.degree];
    [self.stepper setIntegerValue:self.degree];
}

-(void)controlTextDidChange:(NSNotification *)obj {
    int value = [((NSTextView*)obj.userInfo[@"NSFieldEditor"]).textStorage.string integerValue];
    
    [self changeDegreeValue:@(value)];
}

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        self.editor.representedObject = nil;
        self.degree = 0;
    }
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window
    // controller's window has been loaded from its nib file.
    [self.stepper bind:@"integerValue" toObject:self withKeyPath:@"degree" options:nil];
    [self.field bind:@"integerValue" toObject:self withKeyPath:@"degree" options:nil];
}

-(void)mouseDownAtGridLocation:(EXTIntPoint)gridLocation {
    return;
}

@end
