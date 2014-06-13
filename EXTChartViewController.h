//
//  EXTChartViewController.h
//  Ext Chart
//
//  Created by Bavarious on 10/08/2013.
//  Copyright (c) 2013 Harvard University. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "EXTLeibnizWindowController.h"


@class EXTChartView;
@class EXTDocument;


@interface EXTChartViewController : NSViewController
@property(nonatomic, readonly) EXTChartView *chartView;
@property(nonatomic, weak) id selectedObject;
@property(nonatomic, weak) EXTLeibnizWindowController *leibnizWindowController;
@property(nonatomic, assign) int currentPage;

// Designated initialiser
- (instancetype)initWithDocument:(EXTDocument *)document;

// Deprecate other initialisers
+ (instancetype)new UNAVAILABLE_ATTRIBUTE;
- (instancetype)init UNAVAILABLE_ATTRIBUTE;
- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil UNAVAILABLE_ATTRIBUTE;

- (void)reloadCurrentPage;
@end
