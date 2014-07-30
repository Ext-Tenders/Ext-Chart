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


static inline bool isRunningTests(void) {
    return [[[NSProcessInfo processInfo] arguments] containsObject:@"-XCTest"];
}


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
    if (isRunningTests()) return NO;

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
