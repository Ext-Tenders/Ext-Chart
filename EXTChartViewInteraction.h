//
//  EXTChartViewInteraction.h
//  Ext Chart
//
//  Created by Bavarious on 04/07/2014.
//  Copyright (c) 2014 Harvard University. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol EXTChartViewInteraction <NSObject>
@required
@property (nonatomic, assign, getter = isHighlighted) bool highlighted;
@property (nonatomic, assign) CGColorRef highlightColor;

// Note: AQuartz/ImageKit currently (OS X v10.9) defines -[CALayer(LayerExtra) setSelected:], which in turn interferes
// with surrogate forwarding if we name the property `selected`. To avoid this problem, the property name is `selectedObject`.
@property (nonatomic, assign, getter = isSelectedObject) bool selectedObject;
@property (nonatomic, assign) CGColorRef selectionColor;
@end
