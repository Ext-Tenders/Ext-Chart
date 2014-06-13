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


@interface EXTGridInspectorViewController () <EXTDocumentInspectorViewDelegate>
    @property(nonatomic, weak) IBOutlet NSButton *showGridButton;
    @property(nonatomic, weak) IBOutlet NSColorWell *gridColorWell;
    @property(nonatomic, weak) IBOutlet NSTextField *gridSpacingField;
    @property(nonatomic, weak) IBOutlet NSColorWell *gridEmphasisColorWell;
    @property(nonatomic, weak) IBOutlet NSTextField *gridEmphasisSpacingField;
    @property(nonatomic, weak) IBOutlet NSColorWell *axisColorWell;
    @property(nonatomic, weak) IBOutlet NSColorWell *highlightColorWell;
@end


@implementation EXTGridInspectorViewController

- (instancetype)init {
    return [self initWithNibName:@"EXTGridInspectorView" bundle:nil];
}

- (void)documentWindowController:(EXTDocumentWindowController *)windowController didAddInspectorView:(NSView *)inspectorView {
    EXTDocument *doc = [windowController extDocument];
    NSAssert(doc, @"The window controller must have a corresponding document");

    [_showGridButton bind:NSValueBinding toObject:windowController.chartView withKeyPath:@"showsGrid" options:nil];
    [_gridColorWell bind:NSValueBinding toObject:doc withKeyPath:@"gridColor" options:nil];
    [_gridSpacingField bind:NSValueBinding toObject:doc withKeyPath:@"gridSpacing" options:nil];
    [_gridEmphasisColorWell bind:NSValueBinding toObject:doc withKeyPath:@"gridEmphasisColor" options:nil];
    [_gridEmphasisSpacingField bind:NSValueBinding toObject:doc withKeyPath:@"gridEmphasisSpacing" options:nil];
    [_axisColorWell bind:NSValueBinding toObject:doc withKeyPath:@"axisColor" options:nil];
    [_highlightColorWell bind:NSValueBinding toObject:doc withKeyPath:@"highlightColor" options:nil];
}

- (void)documentWindowController:(EXTDocumentWindowController *)windowController willRemoveInspectorView:(NSView *)inspectorView {
    [_showGridButton unbind:NSValueBinding];
    [_gridColorWell unbind:NSValueBinding];
    [_gridSpacingField unbind:NSValueBinding];
    [_gridEmphasisColorWell unbind:NSValueBinding];
    [_gridEmphasisSpacingField unbind:NSValueBinding];
    [_axisColorWell unbind:NSValueBinding];
    [_highlightColorWell unbind:NSValueBinding];
}

@end
