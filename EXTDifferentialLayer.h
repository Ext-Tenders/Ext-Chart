//
//  EXTDifferentialLayer.h
//  Ext Chart
//
//  Created by Bavarious on 04/07/2014.
//  Copyright (c) 2014 Harvard University. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "EXTChartViewInteraction.h"

@class EXTChartViewModelDifferential;

@interface EXTDifferentialLayer : CAShapeLayer <EXTChartViewInteraction>
@property (nonatomic, strong) EXTChartViewModelDifferential *differential;
@end
