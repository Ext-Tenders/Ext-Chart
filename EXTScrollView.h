//
//  EXTScrollView.m
//  Ext Chart
//
//  Created by Michael Hopkins on 7/24/11.
//  Copyright 2011 Harvard University. All rights reserved.
//

@import Cocoa;

@interface EXTScrollView : NSScrollView

- (IBAction)scrollOriginToCenter:(id)sender;
- (IBAction)scrollOriginToLowerLeft:(id)sender;

/* 10.8 introduced magnification support for NSScrollView, including NSScrollView.magnification
   and -[NSScrollView setMagnification:centeredAtPoint:]; the latter is similar to the method
   below. However, magnification with a fixed reference point does not work correctly if scroll view
   rulers are visible. Whilst this bug is not fixed, we keep around the method below and some
   methods do manual adjustments when needed. */
- (void)zoomToPoint:(NSPoint) point withScaling:(CGFloat)scale;

@end
