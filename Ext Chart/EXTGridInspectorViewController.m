//
//  EXTGridInspectorViewController.m
//  Ext Chart
//
//  Created by Bavarious on 17/08/2013.
//  Copyright (c) 2013 Harvard University. All rights reserved.
//

#import "EXTGridInspectorViewController.h"
#import "EXTDocumentWindowController.h"
#import "EXTDocument.h"
#import "EXTSpectralSequence.h"
#import "EXTMatrixEditor.h"
#import "EXTChartViewController.h"

@interface EXTGridInspectorViewController () <EXTDocumentInspectorViewDelegate, EXTMatrixEditorDelegate>
    @property(nonatomic, weak) IBOutlet NSButton *showGridButton;
    @property(nonatomic, weak) IBOutlet NSColorWell *gridColorWell;
    @property(nonatomic, weak) IBOutlet NSTextField *gridSpacingField;
    @property(nonatomic, weak) IBOutlet NSColorWell *gridEmphasisColorWell;
    @property(nonatomic, weak) IBOutlet NSTextField *gridEmphasisSpacingField;
    @property(nonatomic, weak) IBOutlet NSColorWell *axisColorWell;
    @property(nonatomic, weak) IBOutlet NSColorWell *highlightColorWell;
    @property(nonatomic, weak) IBOutlet NSColorWell *selectionColorWell;
    @property(nonatomic, weak) IBOutlet NSButton *modifyGradingButton;

    @property (nonatomic, weak) IBOutlet NSPopover *gradingModifyPopover;
    @property (nonatomic, weak) IBOutlet NSButton *okButton;
    @property (nonatomic, weak) IBOutlet EXTMatrixEditor *internalMatrixEditor;
    @property (nonatomic, weak) IBOutlet EXTMatrixEditor *screenProjectionMatrixEditor;
    @property (nonatomic, weak) IBOutlet NSPopUpButton *gradingModifyPopupButton;
    @property (nonatomic, weak) IBOutlet NSMenu *gradingModifyDropdown;
@end


@implementation EXTGridInspectorViewController
{
    EXTDocumentWindowController * __weak _documentWindowController;
}

- (instancetype)init {
    return [self initWithNibName:@"EXTGridInspectorView" bundle:nil];
}

- (void)documentWindowController:(EXTDocumentWindowController *)windowController didAddInspectorView:(NSView *)inspectorView {
    // store the window controller for later calls.
    _documentWindowController = windowController;
    
    EXTDocument *doc = [windowController extDocument];
    NSAssert(doc, @"The window controller must have a corresponding document");

    [_showGridButton bind:NSValueBinding toObject:windowController.chartView withKeyPath:@"showsGrid" options:nil];
    [_gridColorWell bind:NSValueBinding toObject:doc withKeyPath:@"gridColor" options:nil];
    [_gridSpacingField bind:NSValueBinding toObject:doc withKeyPath:@"gridSpacing" options:nil];
    [_gridEmphasisColorWell bind:NSValueBinding toObject:doc withKeyPath:@"gridEmphasisColor" options:nil];
    [_gridEmphasisSpacingField bind:NSValueBinding toObject:doc withKeyPath:@"gridEmphasisSpacing" options:nil];
    [_axisColorWell bind:NSValueBinding toObject:doc withKeyPath:@"axisColor" options:nil];
    [_highlightColorWell bind:NSValueBinding toObject:doc withKeyPath:@"highlightColor" options:nil];
    [_selectionColorWell bind:NSValueBinding toObject:doc withKeyPath:@"selectionColor" options:nil];
}

- (void)documentWindowController:(EXTDocumentWindowController *)windowController willRemoveInspectorView:(NSView *)inspectorView {
    _documentWindowController = nil;
    
    [_showGridButton unbind:NSValueBinding];
    [_gridColorWell unbind:NSValueBinding];
    [_gridSpacingField unbind:NSValueBinding];
    [_gridEmphasisColorWell unbind:NSValueBinding];
    [_gridEmphasisSpacingField unbind:NSValueBinding];
    [_axisColorWell unbind:NSValueBinding];
    [_highlightColorWell unbind:NSValueBinding];
    [_selectionColorWell unbind:NSValueBinding];
}

-(IBAction)changeGradingButtonPressed:(id)sender {
    EXTLocationToPoint *locConvertor = ((EXTSpectralSequence*)((EXTDocument*)_documentWindowController.document).sseq).locConvertor;
    Class locConvertorClass = [locConvertor class];
    
    if ([locConvertorClass isSubclassOfClass:[EXTPairToPoint class]]) {
        EXTPairToPoint *pairConvertor = (EXTPairToPoint*)locConvertor;
        
        // hook the matrices up to the EXTMatrixEditors
        self.internalMatrixEditor.representedObject = [[pairConvertor internalToUser] copy];
        self.screenProjectionMatrixEditor.representedObject = [[pairConvertor userToScreen] copy];
        
        // launch the popover
        [_gradingModifyPopover showRelativeToRect:self.modifyGradingButton.frame
                                           ofView:self.modifyGradingButton
                                    preferredEdge:NSMinXEdge];
        [self.internalMatrixEditor reloadData];
        [self.screenProjectionMatrixEditor reloadData];
        
        // set up the defaults dropdown
        [self.gradingModifyDropdown removeAllItems];
        [[_gradingModifyDropdown addItemWithTitle:@"Custom" action:nil keyEquivalent:@""] setTarget:self];
        [[_gradingModifyDropdown addItemWithTitle:@"Cohomological Serre" action:@selector(cohomologicalSerrePick:) keyEquivalent:@""] setTarget:self];
        [[_gradingModifyDropdown addItemWithTitle:@"Adams" action:@selector(adamsPick:) keyEquivalent:@""] setTarget:self];
        [[_gradingModifyDropdown addItemWithTitle:@"Homological Serre" action:@selector(homologicalSerrePick:) keyEquivalent:@""] setTarget:self];
    } else if ([locConvertorClass isSubclassOfClass:[EXTTripleToPoint class]]) {
        EXTTripleToPoint *tripleConvertor = (EXTTripleToPoint*)locConvertor;
        
        // hook the matrices up to the EXTMatrixEditors
        self.internalMatrixEditor.representedObject = [[tripleConvertor internalToUser] copy];
        self.screenProjectionMatrixEditor.representedObject = [[tripleConvertor userToScreen] copy];
        
        // launch the popover
        [_gradingModifyPopover showRelativeToRect:self.modifyGradingButton.frame
                                           ofView:self.modifyGradingButton
                                    preferredEdge:NSMinXEdge];
        [self.internalMatrixEditor reloadData];
        [self.screenProjectionMatrixEditor reloadData];
        
        // set up the defaults dropdown
        [self.gradingModifyDropdown removeAllItems];
        [[_gradingModifyDropdown addItemWithTitle:@"Custom" action:nil keyEquivalent:@""] setTarget:self];
    } else {
        NSLog(@"Regrading button pressed for unknown EXTPointToPair type.");
    }
    
    return;
}

-(IBAction)okButtonPressed:(id)sender {
    EXTLocationToPoint *locConvertor = ((EXTSpectralSequence*)((EXTDocument*)_documentWindowController.document).sseq).locConvertor;
    Class locConvertorClass = [locConvertor class];

    // save the gradingModifyPopover matrices to the sseq
    if ([locConvertorClass isSubclassOfClass:[EXTPairToPoint class]]) {
        EXTPairToPoint *pairConvertor = (EXTPairToPoint*)locConvertor;
        pairConvertor.internalToUser = self.internalMatrixEditor.representedObject;
        pairConvertor.userToScreen = self.screenProjectionMatrixEditor.representedObject;
    } else if ([locConvertorClass isSubclassOfClass:[EXTPairToPoint class]]) {
        EXTTripleToPoint *tripleConvertor = (EXTTripleToPoint*)locConvertor;
        tripleConvertor.internalToUser = self.internalMatrixEditor.representedObject;
        tripleConvertor.userToScreen = self.screenProjectionMatrixEditor.representedObject;
    } else {
        NSLog(@"closing grading modifier popover on unknown convertor class type.");
    }
    
    // refresh the sseq display
    [_documentWindowController.chartViewController reloadCurrentPage];
    
    // close the popover
    [self.gradingModifyPopover close];
    
    return;
}

- (void)popoverWillClose:(NSNotification *)notification {
    return;
}

-(void)matrixEditorDidUpdate {
    [_gradingModifyPopupButton selectItemAtIndex:0];
    return;
}

#pragma mark --- dropdown default grading selectors

-(IBAction)cohomologicalSerrePick:(id)sender {
    // differentials should go d_r: E_r^{s, t} --> E_r^{s+r, t-r+1}.
    int *internalToUserData = _internalMatrixEditor.representedObject.presentation.mutableBytes;
    internalToUserData[2*0 + 0] = 0;
    internalToUserData[2*0 + 1] = -1;
    internalToUserData[2*1 + 0] = 1;
    internalToUserData[2*1 + 1] = -1;
    
    // internal coordinates = visible coordinates.
    // perform a NOP to project to screen.
    _screenProjectionMatrixEditor.representedObject = [EXTMatrix identity:2];
    
    [self.internalMatrixEditor reloadData];
    [self.screenProjectionMatrixEditor reloadData];
    return;
}

-(IBAction)homologicalSerrePick:(id)sender {
    // differentials should go d_r: E_r^{s, t} --> E_r^{s-r, t+r-1}.
    int *internalToUserData = _internalMatrixEditor.representedObject.presentation.mutableBytes;
    internalToUserData[2*0 + 0] = 0;
    internalToUserData[2*0 + 1] = 1;
    internalToUserData[2*1 + 0] = -1;
    internalToUserData[2*1 + 1] = 1;
    
    // internal coordinates = visible coordinates.
    // perform a NOP to project to screen.
    _screenProjectionMatrixEditor.representedObject = [EXTMatrix identity:2];
    
    [self.internalMatrixEditor reloadData];
    [self.screenProjectionMatrixEditor reloadData];
    return;
}

// the standard Z^2 coordinate system is graded so that setting both projection
// matrices to the identity produces the Adams grading on display. however, this
// is not what topologists are used to thinking of as the 'internal' grading to
// an Adams spectral sequence: they want the axes to be labeled (t-s, s) for
// internal coordinates (s, t). these matrices set up this yoga.
-(IBAction)adamsPick:(id)sender {
    // (a, b) |-> (b, a+b)
    int *internalToUserData = _internalMatrixEditor.representedObject.presentation.mutableBytes;
    internalToUserData[0*2 + 0] = 0;
    internalToUserData[0*2 + 1] = 1;
    internalToUserData[1*2 + 0] = 1;
    internalToUserData[1*2 + 1] = 1;
    
    // (s, t) |-> (t-s, s)
    int *userToScreenData = _screenProjectionMatrixEditor.representedObject.presentation.mutableBytes;
    userToScreenData[0*2 + 0] = -1;
    userToScreenData[0*2 + 1] = 1;
    userToScreenData[1*2 + 0] = 1;
    userToScreenData[1*2 + 1] = 0;
    
    [self.internalMatrixEditor reloadData];
    [self.screenProjectionMatrixEditor reloadData];
    return;
}

@end
