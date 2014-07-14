//
//  EXTGrid.h
//  Ext Chart
//
//  Created by Michael Hopkins on 7/20/11.
//  Copyright 2011 Harvard University. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface EXTGrid : NSObject

@property (nonatomic, strong) NSColor *gridColor, *emphasisGridColor, *axisColor;
@property (nonatomic, assign) NSInteger gridSpacing;
@property (nonatomic, assign) NSInteger emphasisSpacing;
@property (nonatomic, assign, getter=isVisible) bool visible;

/// Given a view point, returns the grid point representing the origin of the grid square containing that view point.
- (EXTIntPoint)convertPointFromView:(NSPoint)viewPoint;

/// Given a view rectangle, returns the corresponding rectangle in grid coordinate space.
- (EXTIntRect)convertRectFromView:(NSRect)viewRect;

/// Given a view point, returns the grid point nearest to that view point.
- (EXTIntPoint)nearestGridPoint:(NSPoint)viewPoint;

/// Given a grid point, returns the corresponding point in view coordinate space.
- (NSPoint)convertPointToView:(EXTIntPoint)gridPoint;

/// Given a grid rectangle, returns the corresponding rectangle in view coordinate space.
- (NSRect)convertRectToView:(EXTIntRect)gridRect;
@end

#pragma mark - Public variables

extern NSString * const EXTGridColorPreferenceKey;
extern NSString * const EXTGridSpacingPreferenceKey;
extern NSString * const EXTGridEmphasisColorPreferenceKey;
extern NSString * const EXTGridEmphasisSpacingPreferenceKey;
extern NSString * const EXTGridAxisColorPreferenceKey;
