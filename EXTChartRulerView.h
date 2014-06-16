//
//  EXTChartRulerView.h
//  Ext Chart
//
//  Created by Bavarious on 15/06/2014.
//  Copyright (c) 2014 Harvard University. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface EXTChartRulerView : NSRulerView
@property (nonatomic, assign) CGFloat unitToPointsConversionFactor;
@property (nonatomic, assign) NSInteger emphasisSpacing; // in units

+ (void)registerUnitWithName:(NSString *)unitName abbreviation:(NSString *)abbreviation unitToPointsConversionFactor:(CGFloat)conversionFactor stepUpCycle:(NSArray *)stepUpCycle stepDownCycle:(NSArray *)stepDownCycle UNAVAILABLE_ATTRIBUTE;
- (void)setMeasurementUnits:(NSString *)unitName UNAVAILABLE_ATTRIBUTE;
@end
