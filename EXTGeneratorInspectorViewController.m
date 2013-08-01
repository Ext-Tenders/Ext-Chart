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
@property(nonatomic, strong) EXTSpectralSequence *sseq;

@end

@implementation EXTGeneratorInspectorViewController

@synthesize tableView;

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
    
    return [[[(NSArray*)[self representedObject] objectAtIndex:row] objectForKey:[tableColumn identifier]] description];
}

/*-(NSView *)tableView:(NSTableView *)tableView
  viewForTableColumn:(NSTableColumn *)tableColumn
                 row:(NSInteger)row {
    if (![[self.representedObject class] isSubclassOfClass:[EXTPolynomialSSeq class]])
        return nil;
    
    NSMutableDictionary *entry = ((EXTPolynomialSSeq*)self.representedObject).generators[row];
    
    NSTextField *textField = [tableView makeViewWithIdentifier:tableColumn.identifier owner:self];
    textField.objectValue = [NSString stringWithFormat:@"%@", [[entry objectForKey:tableColumn.identifier] description]];
    
    return textField;
}*/

-(void) tableView:(NSTableView*)aTableView
   setObjectValue:(id)object
   forTableColumn:(NSTableColumn *)tableColumn
              row:(NSInteger)row {
    return;
}

-(void) viewDidLoad {
    [tableView reloadData];
}

@end
