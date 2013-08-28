//
//  EXTLeibnizWindowController.m
//  Ext Chart
//
//  Created by Eric Peterson on 8/27/13.
//  Copyright (c) 2013 Harvard University. All rights reserved.
//

#import "EXTLeibnizWindowController.h"

@interface EXTLeibnizWindowController ()

@property IBOutlet NSTableView *tableView;
@property IBOutlet NSButton *deleteButton;
@property IBOutlet NSButton *OKButton;

@end

@implementation EXTLeibnizWindowController

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
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

-(IBAction)OKPressed:(id)sender {
    return;
}

-(IBAction)deletePressed:(id)sender {
    return;
}

-(NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return 0;
}

@end
