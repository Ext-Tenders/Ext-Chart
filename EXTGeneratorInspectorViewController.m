//
//  EXTGeneratorInspectorViewController.m
//  Ext Chart
//
//  Created by Eric Peterson on 8/1/13.
//  Copyright (c) 2013 Harvard University. All rights reserved.
//

#import "EXTGeneratorInspectorViewController.h"
#import "EXTPolynomialSSeq.h"

@interface EXTGeneratorInspectorViewController () <NSTableViewDelegate, NSTableViewDataSource>
{
    EXTSpectralSequence *_sseq;
}

@property(nonatomic, strong) IBOutlet NSTableView *tableView;
@property(nonatomic, strong) IBOutlet NSTextField *textField;
@property(nonatomic, strong) EXTSpectralSequence *sseq;

@end

@implementation EXTGeneratorInspectorViewController

@synthesize tableView, chartView;

-(EXTSpectralSequence*) sseq {
    return _sseq;
}

- (void)setSseq:(EXTSpectralSequence *)sseq {
    _sseq = sseq;
    
    if ([[sseq class] isSubclassOfClass:[EXTPolynomialSSeq class]]) {
        [self unbind:@"representedObject"];
        [self bind:@"representedObject" toObject:((EXTPolynomialSSeq*)sseq) withKeyPath:@"generators" options:nil];
    } else {
        [self unbind:@"representedObject"];
        [self setRepresentedObject:nil];
    }
    
    [[self tableView] reloadData];
}

- (id)init {
    return [self initWithNibName:@"EXTGeneratorInspectorViewController" bundle:nil];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    return [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
}

-(NSInteger) numberOfRowsInTableView:(NSTableView*)aTableView {
    if (![self representedObject] ||
        ![[self.representedObject class] isSubclassOfClass:[NSArray class]])
        return 0;
    
    return ((NSArray*)self.representedObject).count;
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    if (![self representedObject])
        return nil;
    if (((NSArray*)[self representedObject]).count <= row) {
        EXTLog(@"Bad row display");
        return nil;
    }
    
    return [[[(NSArray*)[self representedObject] objectAtIndex:row] objectForKey:[tableColumn identifier]] description];
}

-(void) tableView:(NSTableView*)aTableView
   setObjectValue:(id)object
   forTableColumn:(NSTableColumn *)tableColumn
              row:(NSInteger)row {
    if (![[_sseq class] isSubclassOfClass:[EXTPolynomialSSeq class]])
        return;
    EXTPolynomialSSeq *polySSeq = (EXTPolynomialSSeq*)_sseq;
    
    if ([[tableColumn identifier] isEqualToString:@"name"]) {
        [polySSeq changeName:[polySSeq.generators[row] objectForKey:@"name"]
                          to:object];
    } else if ([[tableColumn identifier] isEqualToString:@"upperBound"]) {
        [polySSeq resizePolyClass:[polySSeq.generators[row] objectForKey:@"name"] upTo:[object intValue]];
        [self causeRefresh];
    }
    
    return;
}

-(void) causeRefresh {
    if (chartView.selectedPageIndex > 0) {
        chartView.selectedPageIndex = 0;
    } else {
        [chartView displaySelectedPage];
    }
    
    return;
}

-(IBAction)addButtonPressed:(id)sender {
    if (![[_sseq class] isSubclassOfClass:[EXTPolynomialSSeq class]])
        return;
    
    EXTPolynomialSSeq *polySSeq = (EXTPolynomialSSeq*) _sseq;
    EXTLocation *loc = [[polySSeq indexClass] convertFromString:[self.textField stringValue]];
    
    if (!loc)
        return;
    
    // it liiiiives!
    [polySSeq addPolyClass:nil location:loc upTo:1];
    
    [tableView reloadData];
    [self causeRefresh];
}

-(IBAction)deleteButtonPressed:(id)sender {
    NSInteger row = [tableView selectedRow];
    
    if (![[_sseq class] isSubclassOfClass:[EXTPolynomialSSeq class]])
        return;
    
    EXTPolynomialSSeq *polySSeq = (EXTPolynomialSSeq*)_sseq;
    [polySSeq deleteClass:[polySSeq.generators[row] objectForKey:@"name"]];
    
    [tableView deselectAll:sender];
    [tableView reloadData];
    
    [self causeRefresh];
    
    return;
}

@end
