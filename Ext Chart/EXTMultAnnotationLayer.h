//
//  EXTMultAnnotationLayer.h
//  Ext Chart
//
//  Created by Eric Peterson on 7/11/14.
//  Copyright (c) 2014 Harvard University. All rights reserved.
//

@import QuartzCore;

#import "EXTChartViewInteraction.h"

@class EXTChartViewModelMultAnnotation;
@class EXTChartViewModelMultAnnoLine;


@interface EXTMultAnnotationLineLayer : CAShapeLayer
@property (nonatomic, strong) EXTChartViewModelMultAnnotation *annotation;
@property (nonatomic, strong) EXTChartViewModelMultAnnoLine *line;

@property (nonatomic, assign) CGFloat defaultZPosition;
@property (nonatomic, assign) CGFloat defaultLineWidth;
@end
