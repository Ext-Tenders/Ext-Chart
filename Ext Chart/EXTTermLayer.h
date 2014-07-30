//
//  EXTTermLayer.h
//  Ext Chart
//
//  Created by Bavarious on 04/07/2014.
//  Copyright (c) 2014 Harvard University. All rights reserved.
//

@import QuartzCore;

#import "EXTChartViewInteraction.h"

@class EXTChartViewModelTermCell;

/// Defines properties and methods that every term layer class must implement so that a chart view can
/// create term layers based off an EXTChartViewModelTermCell instance.
@protocol EXTTermLayerBase
@property (nonatomic, readonly, strong) EXTChartViewModelTermCell *termCell;

+ (instancetype)termLayerWithTermCell:(EXTChartViewModelTermCell *)termCell length:(NSInteger)length;
@end


// FIXME: Move to EXTTermLayerPrivate.h
extern NSString * const EXTTermLayerFontName;
