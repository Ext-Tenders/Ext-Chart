//
//  EXTDifferentialLayer.h
//  Ext Chart
//
//  Created by Bavarious on 04/07/2014.
//  Copyright (c) 2014 Harvard University. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

@class EXTChartViewDifferentialData;

@interface EXTDifferentialLayer : CAShapeLayer
@property (nonatomic, strong) EXTChartViewDifferentialData *differentialData;
@property (nonatomic, assign, getter = isHighlighted) bool highlighted;
@property (nonatomic, assign) CGColorRef highlightColor;
@end
