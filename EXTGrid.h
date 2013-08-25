//
//  EXTGrid.h
//  Ext Chart
//
//  Created by Michael Hopkins on 7/20/11.
//  Copyright 2011 Harvard University. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface EXTGrid : NSObject

@property(nonatomic, strong) NSColor *gridColor, *emphasisGridColor, *axisColor;
@property(nonatomic, assign) CGFloat gridSpacing;
@property(nonatomic, assign) NSInteger emphasisSpacing;
@property(nonatomic, assign) NSRect boundsRect;
@property(nonatomic, strong) NSBezierPath *gridPath, *emphasisGridPath;

-(NSBezierPath *) makeGridInRect: (NSRect) rect withFactor:(NSUInteger) factor;

- (void) drawGridInRect:(NSRect)rect;
- (void) drawGrid;
- (void) drawAxes;

- (NSPoint)nearestGridPoint:(NSPoint)point; // used for snapping to grid
- (EXTIntPoint)convertPointToGrid:(NSPoint)point;
- (NSPoint)lowerLeftGridPoint:(NSPoint)point;

- (NSRect)enclosingGridRect:(NSPoint)point;
- (void) drawEnclosingRectAtPoint: (NSPoint)point;

@end

#pragma mark - Public variables

extern NSString * const EXTGridAnyKey;

extern NSString * const EXTGridColorPreferenceKey;
extern NSString * const EXTGridSpacingPreferenceKey;
extern NSString * const EXTGridEmphasisColorPreferenceKey;
extern NSString * const EXTGridEmphasisSpacingPreferenceKey;
extern NSString * const EXTGridAxisColorPreferenceKey;
