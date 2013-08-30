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


    // Designated initialiser
    - (id)initWithDocument:(EXTDocument *)document;

    // Deprecate other initialisers
    + (id)new __attribute__((deprecated("Use -initWithDocument: instead")));
    - (id)init __attribute__((deprecated("Use -initWithDocument: instead")));
    - (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil __attribute__((deprecated("Use -initWithDocument: instead")));
@end
