//
//  EXTNewDocumentWindowController.m
//  Ext Chart
//
//  Created by Bavarious on 04/08/2013.
//  Copyright (c) 2013 Harvard University. All rights reserved.
//

#import "EXTNewDocumentWindowController.h"
#import "EXTDocument.h"
#import "EXTSpectralSequence.h"
#import "EXTPolynomialSSeq.h"
#import "EXTMaySpectralSequence.h"
#import "EXTDemos.h"

@interface EXTNewDocumentWindowController () <NSTableViewDataSource, NSTableViewDelegate, NSTextFieldDelegate>
    @property(nonatomic, weak) IBOutlet NSTableView *tableView;
    @property(nonatomic, weak) IBOutlet NSTextField *nameField;
    @property(nonatomic, weak) IBOutlet NSTextField *descriptionField;
    @property(nonatomic, weak) IBOutlet NSButton *createDocumentButton;
    @property(nonatomic, weak) IBOutlet NSView *detailsView;
    @property(nonatomic, strong) IBOutlet NSView *locationTypeView;
    @property(nonatomic, strong) IBOutlet NSView *mayView;
    @property(nonatomic, strong) IBOutlet NSImageView *exampleImageView;
    @property(nonatomic, weak) IBOutlet NSMatrix *locationTypeMatrix;
    @property(nonatomic, weak) IBOutlet NSTextField *mayWidthField;
    @property(nonatomic, weak) IBOutlet NSTextField *maySubalgebraField;
    @property(nonatomic, weak) IBOutlet NSButton *mayRestrictToSubalgebraButton;
@end


@interface EXTNewDocumentOption : NSObject
    @property(nonatomic, copy) NSString *name;
    @property(nonatomic, assign, getter = isGroup) bool group;
    @property(nonatomic, copy) NSString *description;
    @property(nonatomic, weak) NSView *detailsView;
    @property(nonatomic, copy) EXTSpectralSequence *(^spectralSequenceFactory)(void);
    - (instancetype)initGroupWithName:(NSString *)name;
    - (instancetype)initWithName:(NSString *)name
                     description:(NSString *)description
                     detailsView:(NSView *)detailsView
         spectralSequenceFactory:(EXTSpectralSequence *(^)(void))spectralSequenceFactory;
@end


@implementation EXTNewDocumentWindowController {
    NSArray *_options;
    NSArray *_exampleImageNames;
    NSInteger _firstExampleIndex;
}

- (id)init {
    return [self initWithWindowNibName:@"EXTNewDocument"];
}

- (void)windowDidLoad {
    [super windowDidLoad];

    [_mayWidthField setDelegate:self];
    [_maySubalgebraField setDelegate:self];

    // List of new document options
    {
        NSMutableArray *options = [NSMutableArray array];
        [options addObject:[[EXTNewDocumentOption alloc] initGroupWithName:@"Blank Document"]];
        [options addObject:[[EXTNewDocumentOption alloc] initWithName:@"Arbitrary Spectral Sequence"
                                                          description:@"Terms have no automatic multiplicative structure"
                                                          detailsView:_locationTypeView
                                              spectralSequenceFactory:^{return [EXTSpectralSequence new];}]];
        [options addObject:[[EXTNewDocumentOption alloc] initWithName:@"Polynomial Spectral Sequence"
                                                          description:@"Optimized to present E_1 as a polynomial algebra"
                                                          detailsView:_locationTypeView
                                              spectralSequenceFactory:^{
                                                  Class<EXTLocation> unit = ([_locationTypeMatrix selectedRow] == 0 ?
                                                                             [EXTPair class] :
                                                                             [EXTTriple class]);
                                                  return [EXTPolynomialSSeq sSeqWithUnit:unit];
                                              }
                            ]];
        [options addObject:[[EXTNewDocumentOption alloc] initWithName:@"May Spectral Sequence"
                                                          description:@"Computes the cohomology of the Steenrod algebra"
                                                          detailsView:_mayView
                                              spectralSequenceFactory:^{
                                                  const int width = [_mayWidthField intValue];
                                                  const int An = [_maySubalgebraField intValue];
                                                  return ([_mayRestrictToSubalgebraButton state] == NSOnState ?
                                                          [EXTMaySpectralSequence fillForAn:An width:width] :
                                                          [EXTMaySpectralSequence fillToWidth:width]);
                                              }
                            ]];
        [options addObject:[[EXTNewDocumentOption alloc] initGroupWithName:@"Examples"]];
        _firstExampleIndex = [options count];
        [options addObject:[[EXTNewDocumentOption alloc] initWithName:@"Random"
                                                          description:@"Random garbage"
                                                          detailsView:_exampleImageView
                                              spectralSequenceFactory:^{return [EXTDemos randomDemo];}]];
        [options addObject:[[EXTNewDocumentOption alloc] initWithName:@"Serre: S^1 -> CP^2 -> S^5"
                                                          description:@"Serre spectral sequence for the above fibration"
                                                          detailsView:_exampleImageView
                                              spectralSequenceFactory:^{return [EXTDemos S5Demo];}]];
        [options addObject:[[EXTNewDocumentOption alloc] initWithName:@"C_2-Homotopy Fixed Point SS for KU"
                                                          description:@"WARNING: Thrown off by the mod-2 coefficients"
                                                          detailsView:_exampleImageView
                                              spectralSequenceFactory:^{return [EXTDemos KUhC2Demo];}]];
        [options addObject:[[EXTNewDocumentOption alloc] initWithName:@"A(1) May Spectral Sequence"
                                                          description:@"A 25x25 range of the May SS computing pi_* ko"
                                                          detailsView:_exampleImageView
                                              spectralSequenceFactory:^{return [EXTDemos A1MSSDemo];}]];

        _exampleImageNames = @[@"Random Example", @"S5 Example", @"KUhC2 Example", @"A1MSS Example"];

        _options = [options copy];
    }
    
    [_tableView reloadData];
    [_tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:1] byExtendingSelection:NO];
}

#pragma mark - NSTableViewDataSource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return [_options count];
}

#pragma mark - NSTableViewDelegate

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    EXTNewDocumentOption *option = [_options objectAtIndex:row];
    NSString *cellIdentifier = [option isGroup] ? @"group" : @"option";
    NSTableCellView *view = [_tableView makeViewWithIdentifier:cellIdentifier owner:self];
    [[view textField] setStringValue:[option name]];
    return view;
}

- (BOOL)tableView:(NSTableView *)tableView isGroupRow:(NSInteger)row {
    EXTNewDocumentOption *option = [_options objectAtIndex:row];
    return [option isGroup];
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification {
    [_nameField setStringValue:@""];
    [_descriptionField setStringValue:@""];
    [[_detailsView subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];

    NSInteger selectedRow = [_tableView selectedRow];
    bool createButtonEnabled = false;

    if (selectedRow >= 0) {
        EXTNewDocumentOption *option = [_options objectAtIndex:selectedRow];
        [_nameField setStringValue:[option name]];
        [_descriptionField setStringValue:[option description]];

        if (![option isGroup]) {
            createButtonEnabled = true;

            NSView *currentOptionView = [option detailsView];
            if (currentOptionView) {
                [_detailsView addSubview:currentOptionView];

                NSDictionary *views = NSDictionaryOfVariableBindings(currentOptionView);
                [_detailsView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[currentOptionView]-0-|" options:0 metrics:nil views:views]];
                [_detailsView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[currentOptionView]-0-|" options:0 metrics:nil views:views]];
                
                if (currentOptionView == _mayView)
                    createButtonEnabled = [self validateMayView];
                else if (currentOptionView == _exampleImageView)
                    [_exampleImageView setImage:[NSImage imageNamed:_exampleImageNames[selectedRow - _firstExampleIndex]]];
            }
        }
    }

    [_createDocumentButton setEnabled:createButtonEnabled];
}

#pragma mark - NSControl delegate

- (void)controlTextDidChange:(NSNotification *)obj {
    // We care iff the May view is the current details subview
    NSArray *detailSubviews = [_detailsView subviews];
    if ([detailSubviews count] == 0 || [detailSubviews objectAtIndex:0] != _mayView)
        return;

    [_createDocumentButton setEnabled:[self validateMayView]];
}

#pragma mark - Actions

- (IBAction)createDocument:(id)sender {
    EXTNewDocumentOption *option = [_options objectAtIndex:[_tableView selectedRow]];

    NSDocumentController *docController = [NSDocumentController sharedDocumentController];
    EXTDocument *doc = [docController makeUntitledDocumentOfType:[docController defaultType] error:NULL];
    [doc setSseq:[option spectralSequenceFactory]()];
    [docController addDocument:doc];
    [doc makeWindowControllers];

    [self close];
    [doc showWindows];
}

- (IBAction)close:(id)sender {
    [self close];
}

- (IBAction)changeMayRestrictToSubalgebra:(id)sender {
    NSButton *button = sender;
    [_maySubalgebraField setEnabled:[button state] == NSOnState];
    [_createDocumentButton setEnabled:[self validateMayView]];
}

#pragma mark -

- (bool)validateMayView {
    const int width = [_mayWidthField intValue];
    const bool restrictSubalgebra = ([_mayRestrictToSubalgebraButton state] == NSOnState);
    const int An = [_maySubalgebraField intValue];

    return width >= 0 && !(restrictSubalgebra && An <= 0);
}

@end


@implementation EXTNewDocumentOption

- (instancetype)initGroupWithName:(NSString *)name {
    self = [super init];
    if (self) {
        _name = [name copy];
        _description = @"";
        _group = true;
    }
    return self;
}

- (instancetype)initWithName:(NSString *)name
                 description:(NSString *)description
                 detailsView:(NSView *)detailsView
     spectralSequenceFactory:(EXTSpectralSequence *(^)(void))spectralSequenceFactory {
    self = [super init];
    if (self) {
        _name = [name copy];
        _group = false;
        _description = [description copy];
        _detailsView = detailsView;
        _spectralSequenceFactory = [spectralSequenceFactory copy];
    }
    return self;
}

@end