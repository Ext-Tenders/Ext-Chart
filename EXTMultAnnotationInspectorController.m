//
//  EXTMultAnnotationInspectorController.m
//  Ext Chart
//
//  Created by Eric Peterson on 6/29/14.
//  Copyright (c) 2014 Harvard University. All rights reserved.
//

#import "EXTMultAnnotationInspectorController.h"
#import "EXTMatrixEditor.h"

@interface EXTMultAnnotationInspectorController () <NSTableViewDataSource, NSTableViewDelegate>

@property IBOutlet NSTableView *table;
@property IBOutlet NSButton *addButton;
@property IBOutlet NSButton *deleteButton;

@property IBOutlet EXTMatrixEditor *matrixEditor;
@property IBOutlet NSPopover *popover;

@end

@implementation EXTMultAnnotationInspectorController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
    }
    return self;
}

@end
