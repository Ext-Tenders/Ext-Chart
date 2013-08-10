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

@interface EXTDocumentWindowController : NSWindowController
    @property(nonatomic, readonly) EXTDocument *extDocument;
@end
