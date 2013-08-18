//
//  EXTDifferentialPaneController.m
//  Ext Chart
//
//  Created by Eric Peterson on 8/8/13.
//  Copyright (c) 2013 Harvard University. All rights reserved.
//

#import "EXTDifferentialPaneController.h"
#import "EXTDifferential.h"

@interface EXTDifferentialPaneController ()

@property IBOutlet NSTableView *tableView;
@property IBOutlet NSButton *addButton;
@property IBOutlet NSButton *deleteButton;

@property IBOutlet NSPopover *popover;
@property IBOutlet NSTextField *descriptionField;
@property IBOutlet NSButton *automaticallyGeneratedCB;

@end

@implementation EXTDifferentialPaneController
{
    EXTPartialDefinition *_partial;
}

@synthesize chartView;

#pragma mark differential inspector pane

- (id)init {
    return [self initWithNibName:@"EXTDifferentialPane" bundle:nil];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    return [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
}

- (void)awakeFromNib {
    [self.tableView setTarget:self];
    [self.tableView setDoubleAction:@selector(doubleClick:)];
}

-(NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    if (![[self.representedObject class] isSubclassOfClass:[EXTDifferential class]])
        return 0;
    
    EXTDifferential *diff = self.representedObject;
    
    return diff.partialDefinitions.count;
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    if (![[self.representedObject class] isSubclassOfClass:[EXTDifferential class]])
        return nil;
    
    EXTDifferential *diff = self.representedObject;
    EXTPartialDefinition *partial = diff.partialDefinitions[row];
    
    if ([tableColumn.identifier isEqualToString:@"dimension"]) {
        return @(partial.inclusion.width);
    } else if ([tableColumn.identifier isEqualToString:@"description"]) {
        return partial.description;
    }
    
    return nil;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"selectedObject"]) {
        self.representedObject = change[NSKeyValueChangeNewKey];
        [self.tableView reloadData];
    }
    
    return;
}

-(IBAction)deleteButtonPressed:(id)sender {
    NSInteger row = [self.tableView selectedRow];
    
    if (![[self.representedObject class] isSubclassOfClass:[EXTDifferential class]])
        return;
    
    EXTDifferential *diffl = self.representedObject;
    
    [diffl.partialDefinitions removeObjectAtIndex:row];
    
    [self.tableView deselectAll:sender];
    [self.tableView reloadData];
    [self.chartView displaySelectedPage];
    
    return;
}

- (void)doubleClick:(id)sender {
    if (![[self.representedObject class] isSubclassOfClass:[EXTDifferential class]])
        return;
    EXTDifferential *diff = self.representedObject;
    
    if ((self.tableView.selectedRow < 0) || (self.tableView.selectedRow >= diff.partialDefinitions.count))
        return;
    _partial = diff.partialDefinitions[self.tableView.selectedRow];
    
    // initialize the pieces of the sheet.
    self.descriptionField.stringValue = [_partial.description copy];
    self.automaticallyGeneratedCB.state = _partial.automaticallyGenerated;
    // XXX: make this update when we edit the EXTMatrix's data.
    
    // and display
    [self.popover showRelativeToRect:[self.tableView rectOfRow:self.tableView.selectedRow] ofView:self.tableView preferredEdge:NSMinXEdge];
    
    return;
}

#pragma mark differential editor popover

- (void)popoverWillClose:(NSNotification *)notification {
    _partial.description = self.descriptionField.stringValue;
    
    [_tableView reloadData];
    
    return;
}

@end
