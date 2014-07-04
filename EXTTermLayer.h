//
//  EXTTermLayer.h
//  Ext Chart
//
//  Created by Bavarious on 04/07/2014.
//  Copyright (c) 2014 Harvard University. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

@class EXTChartViewTermCountData;

@interface EXTTermLayer : CAShapeLayer
@property (nonatomic, strong) EXTChartViewTermCountData *termData;
@property (nonatomic, assign, getter = isHighlighted) bool highlighted;
@property (nonatomic, assign) CGColorRef highlightColor;

+ (instancetype)termLayerWithCount:(NSInteger)count length:(CGFloat)length;
@end
