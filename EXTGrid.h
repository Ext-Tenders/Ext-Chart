//
//  EXTGrid.h
//  Ext Chart
//
//  Created by Michael Hopkins on 7/20/11.
//  Copyright 2011 LH Productions. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#define GRID_LINE_WIDTH 0.25

extern NSString *EXTGridAnyKey;

@interface EXTGrid : NSObject {

	NSColor *gridColor, *emphasisGridColor, *axisColor;
	CGFloat gridSpacing;
	NSUInteger emphasisSpacing;
	NSRect boundsRect;
	
	NSBezierPath *gridPath;
	NSBezierPath *emphasisGridPath;
}

@property(retain) NSColor *gridColor, *emphasisGridColor, *axisColor;
@property(assign) CGFloat gridSpacing;
@property(assign) NSUInteger emphasisSpacing;
@property(assign) NSRect boundsRect;
@property(retain) NSBezierPath *gridPath, *emphasisGridPath;

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
