//
//  EXTGrid.h
//  Ext Chart
//
//  Created by Michael Hopkins on 7/20/11.
//  Copyright 2011 Harvard University. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#define GRID_LINE_WIDTH 0.25

extern NSString * const EXTGridAnyKey;

@interface EXTGrid : NSObject {

	NSColor *gridColor, *emphasisGridColor, *axisColor;
	CGFloat gridSpacing;
	NSUInteger emphasisSpacing;
	NSRect boundsRect;
	
	NSBezierPath *gridPath;
	NSBezierPath *emphasisGridPath;
}

@property(strong) NSColor *gridColor, *emphasisGridColor, *axisColor;
@property(nonatomic, assign) CGFloat gridSpacing;
@property(nonatomic, assign) NSUInteger emphasisSpacing;
@property(nonatomic, assign) NSRect boundsRect;
@property(strong) NSBezierPath *gridPath, *emphasisGridPath;

-(id) initWithRect:(NSRect) rect;

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
