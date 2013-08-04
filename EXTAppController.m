//
//  EXTAppController.m
//  Ext Chart
//
//  Created by Michael Hopkins on 7/31/11.
//  Copyright 2011 Harvard University. All rights reserved.
//

#import "EXTAppController.h"
#import "EXTNewDocumentWindowController.h"


@implementation EXTAppController {
    EXTNewDocumentWindowController *_newDocumentWindowController;
}

- (void)newDocument:(id)sender {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!_newDocumentWindowController)
            _newDocumentWindowController = [EXTNewDocumentWindowController new];

        [_newDocumentWindowController showWindow:self];
    });
}

- (BOOL)applicationOpenUntitledFile:(NSApplication *)sender {
    [self newDocument:nil];
    return YES;
}

@end
