//
//  EXTTermLayer.h
//  Ext Chart
//
//  Created by Bavarious on 04/07/2014.
//  Copyright (c) 2014 Harvard University. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "EXTChartViewInteraction.h"

@class EXTChartViewModelTermCell;

@interface EXTTermLayer : CALayer <EXTChartViewInteraction>
@property (nonatomic, strong) EXTChartViewModelTermCell *termCell;

+ (instancetype)termLayerWithTotalRank:(NSInteger)totalRank length:(NSInteger)length;
- (void)resetContents;
@end
