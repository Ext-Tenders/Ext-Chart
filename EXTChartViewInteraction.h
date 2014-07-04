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
@end
