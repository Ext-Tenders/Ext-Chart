//
//  EXTGrid.h
//  Ext Chart
//
//  Created by Michael Hopkins on 7/20/11.
//  Copyright 2011 Harvard University. All rights reserved.
//

#import <Cocoa/Cocoa.h>

extern NSString * const EXTGridAnyKey;

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
- (void) resetToDefaults;

- (NSPoint)nearestGridPoint:(NSPoint)point; // used for snapping to grid
- (NSPoint)convertToGridCoordinates:(NSPoint)point;

- (NSRect)enclosingGridRect:(NSPoint)point;
- (void) drawEnclosingRectAtPoint: (NSPoint)point;

@end
