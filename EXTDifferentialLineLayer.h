//
//  EXTDifferentialLineLayer.h
//  Ext Chart
//
//  Created by Bavarious on 04/07/2014.
//  Copyright (c) 2014 Harvard University. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "EXTChartViewInteraction.h"

@class EXTChartViewModelDifferential;
@class EXTChartViewModelDifferentialLine;


@interface EXTDifferentialLineLayer : CAShapeLayer <EXTChartViewInteraction>
@property (nonatomic, strong) EXTChartViewModelDifferential *differential;
@property (nonatomic, strong) EXTChartViewModelDifferentialLine *line;

@property (nonatomic, assign) CGFloat defaultZPosition;
@property (nonatomic, assign) CGFloat selectedZPosition;
@end
