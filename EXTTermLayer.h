//
//  EXTTermLayer.h
//  Ext Chart
//
//  Created by Bavarious on 04/07/2014.
//  Copyright (c) 2014 Harvard University. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "EXTChartViewInteraction.h"

@class EXTChartViewTermCountData;

@interface EXTTermLayer : CAShapeLayer <EXTChartViewInteraction>
@property (nonatomic, strong) EXTChartViewTermCountData *termData;

+ (instancetype)termLayerWithCount:(NSInteger)count length:(CGFloat)length;
@end
