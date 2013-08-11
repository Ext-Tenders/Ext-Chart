//
//  EXTPreferencesWindowController.m
//  Ext Chart
//
//  Created by Bavarious on 11/08/2013.
//  Copyright (c) 2013 Harvard University. All rights reserved.
//

#import "EXTPreferencesWindowController.h"


@interface EXTPreferencesWindowController ()
@property (nonatomic, weak) IBOutlet NSToolbar *toolbar;
@end


@implementation EXTPreferencesWindowController

- (id)init {
    return [self initWithWindowNibName:@"EXTPreferences"];
}

- (void)windowDidLoad {
    [super windowDidLoad];

    self.toolbar.selectedItemIdentifier = @"General";
    self.window.title = @"General";
}

- (IBAction)switchPane:(id)sender {
}

@end
