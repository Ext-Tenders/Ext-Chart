//
//  EXTImageTermLayer.h
//  Ext Chart
//
//  Created by Bavarious on 23/07/2014.
//  Copyright (c) 2014 Harvard University. All rights reserved.
//

@import QuartzCore;

#import "EXTTermLayer.h"

@interface EXTImageTermLayer : CALayer <EXTTermLayerBase, EXTChartViewInteraction>
- (void)reloadContents;
@end
