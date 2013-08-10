//
//  EXTDifferentialPaneController.h
//  Ext Chart
//
//  Created by Eric Peterson on 8/8/13.
//  Copyright (c) 2013 Harvard University. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "EXTChartView.h"

@interface EXTDifferentialPaneController : NSViewController <NSTableViewDataSource, NSTableViewDelegate>

@property (nonatomic,weak) EXTChartView *chartView;

@end
