//
//  EXTDocumentWindowController.h
//  Ext Chart
//
//  Created by Bavarious on 31/05/2013.
//  Copyright (c) 2013 Harvard University. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "EXTChartView.h"


@class EXTDocument;
@class EXTDocumentWindowController;
@class EXTChartViewController;


@protocol EXTDocumentInspectorViewDelegate <NSObject>
@optional
    - (void)documentWindowController:(EXTDocumentWindowController *)windowController didAddInspectorView:(NSView *)inspectorView;
    - (void)documentWindowController:(EXTDocumentWindowController *)windowController willRemoveInspectorView:(NSView *)inspectorView;
@end


@interface EXTDocumentWindowController : NSWindowController
    @property(nonatomic, weak) IBOutlet EXTChartView *chartView;
    @property(nonatomic, readonly) EXTDocument *extDocument;
    @property(nonatomic, readonly) EXTChartViewController *chartViewController;
    @property (nonatomic, assign, readonly) EXTToolboxTag selectedToolTag;
@end
