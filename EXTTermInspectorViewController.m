//
//  EXTTermInspectorViewController.m
//  Ext Chart
//
//  Created by Eric Peterson on 6/15/14.
//  Copyright (c) 2014 Harvard University. All rights reserved.
//

#import "EXTTermInspectorViewController.h"
#import "EXTMatrixEditor.h"

@interface EXTTermInspectorViewController ()

@property (strong) IBOutlet EXTMatrixEditor *zMatrixEditor;
@property (strong) IBOutlet EXTMatrixEditor *bMatrixEditor;
@property (strong) IBOutlet NSTableView *hTableView;

@end

@implementation EXTTermInspectorViewController

- (instancetype)init {
    return [self initWithNibName:@"EXTTermInspector" bundle:nil];
}

@end
