//
//  EXTAppController.m
//  Ext Chart
//
//  Created by Michael Hopkins on 7/31/11.
//  Copyright 2011 Harvard University. All rights reserved.
//

#import "EXTAppController.h"
#import "EXTNewDocumentWindowController.h"
#import "EXTPreferencesWindowController.h"


@implementation EXTAppController {
    EXTNewDocumentWindowController *_newDocumentWindowController;
    EXTPreferencesWindowController *_preferencesWindowController;
}

- (void)newDocument:(id)sender {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _newDocumentWindowController = [EXTNewDocumentWindowController new];
    });

    [_newDocumentWindowController showWindow:self];
}

- (BOOL)applicationOpenUntitledFile:(NSApplication *)sender {
    [self newDocument:nil];
    return YES;
}

- (IBAction)showPreferences:(id)sender {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _preferencesWindowController = [EXTPreferencesWindowController new];
    });

    [_preferencesWindowController showWindow:nil];
}

@end
