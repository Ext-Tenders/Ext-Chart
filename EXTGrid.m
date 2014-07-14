//
//  EXTGrid.m
//  Ext Chart
//
//  Created by Michael Hopkins on 7/20/11.
//  Copyright 2011 Harvard University. All rights reserved.
//

#import "EXTGrid.h"
#import "NSUserDefaults+EXTAdditions.h"


#pragma mark - Public variables

NSString * const EXTGridAnyKey = @"anyGridKey";

NSString * const EXTGridColorPreferenceKey = @"EXTGridColor";
NSString * const EXTGridSpacingPreferenceKey = @"EXTGridSpacing";
NSString * const EXTGridEmphasisColorPreferenceKey = @"EXTGridEmphasisColor";
NSString * const EXTGridEmphasisSpacingPreferenceKey = @"EXTGridEmphasisSpacing";
NSString * const EXTGridAxisColorPreferenceKey = @"EXTGridAxisColor";

@implementation EXTGrid

#pragma mark - Life cycle

+ (void)load {
    NSDictionary *defaults = @{
                               EXTGridColorPreferenceKey : [NSArchiver archivedDataWithRootObject:[NSColor lightGrayColor]],
                               EXTGridSpacingPreferenceKey : @(9.0),
                               EXTGridEmphasisColorPreferenceKey : [NSArchiver archivedDataWithRootObject:[NSColor darkGrayColor]],
                               EXTGridEmphasisSpacingPreferenceKey : @(8),
                               EXTGridAxisColorPreferenceKey : [NSArchiver archivedDataWithRootObject:[NSColor blueColor]],
                               };
    [[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
}

- (instancetype)init {
    self = [super init];
    if (!self)
        return nil;

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

	_gridSpacing = [defaults doubleForKey:EXTGridSpacingPreferenceKey];
	_emphasisSpacing = [defaults integerForKey:EXTGridEmphasisSpacingPreferenceKey];

	_gridColor = [defaults extColorForKey:EXTGridColorPreferenceKey];
	_emphasisGridColor = [defaults extColorForKey:EXTGridEmphasisColorPreferenceKey];
	_axisColor = [defaults extColorForKey:EXTGridAxisColorPreferenceKey];

    return self;
}

#pragma mark - Conversion between grid & view coordinate spaces

- (EXTIntPoint)convertPointFromView:(NSPoint)viewPoint {
    return (EXTIntPoint){
        .x = (NSInteger)floor(viewPoint.x / _gridSpacing),
        .y = (NSInteger)floor(viewPoint.y / _gridSpacing)
    };
}

- (EXTIntRect)convertRectFromView:(NSRect)viewRect {
    const EXTIntPoint originInGrid = [self convertPointFromView:viewRect.origin];
    const NSPoint upperRightInView = {NSMaxX(viewRect), NSMaxY(viewRect)};

    // We can’t simply use -convertPointFromView: with upperRightInView since that method
    // returns the origin (i.e., lower left) of the grid square containing the point
    EXTIntPoint upperRightInGrid = {
        .x = (NSInteger)ceil(upperRightInView.x / _gridSpacing),
        .y = (NSInteger)ceil(upperRightInView.y / _gridSpacing)
    };

    return (EXTIntRect){
        .origin = originInGrid,
        .size.width = upperRightInGrid.x - originInGrid.x,
        .size.height = upperRightInGrid.y - originInGrid.y
    };
}

- (EXTIntPoint)nearestGridPoint:(NSPoint)viewPoint {
    return (EXTIntPoint){
        .x = (NSInteger)floor((viewPoint.x / _gridSpacing) + 0.5),
        .y = (NSInteger)floor((viewPoint.y / _gridSpacing) + 0.5)
    };
}

- (NSPoint)convertPointToView:(EXTIntPoint)gridPoint {
    return (NSPoint){
        .x = gridPoint.x * _gridSpacing,
        .y = gridPoint.y * _gridSpacing
    };
}

- (NSRect)convertRectToView:(EXTIntRect)gridRect {
    const NSPoint lowerLeftInView = [self convertPointToView:gridRect.origin];
    const EXTIntPoint upperRightInGrid = {
        .x = gridRect.origin.x + gridRect.size.width,
        .y = gridRect.origin.y + gridRect.size.height
    };
    const NSPoint upperRightInView = [self convertPointToView:upperRightInGrid];

    return (NSRect){
        .origin = lowerLeftInView,
        .size.width = upperRightInView.x - lowerLeftInView.x,
        .size.height = upperRightInView.y - lowerLeftInView.y
    };
}

- (NSRect)viewBoundingRectForGridPoint:(EXTIntPoint)gridSquareOrigin {
    return (NSRect){
        .origin = [self convertPointToView:gridSquareOrigin],
        .size.width = _gridSpacing,
        .size.height = _gridSpacing
    };
}

#pragma mark NSKeyValueObserving

+ (NSSet *)keyPathsForValuesAffectingAnyGridKey {
	return [NSSet setWithObjects:@"gridColor", @"emphasisGridColor", @"gridSpacing", @"emphasisSpacing", @"axisColor", nil];
}

@end
