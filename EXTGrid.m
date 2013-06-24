//
//  EXTGrid.m
//  Ext Chart
//
//  Created by Michael Hopkins on 7/20/11.
//  Copyright 2011 Harvard University. All rights reserved.
//

#import "EXTGrid.h"


#pragma mark - Public variables

// I guess a string constant is an exposed binding.
NSString * const EXTGridAnyKey = @"anyGridKey";


#pragma mark - Private variables

static const CGFloat _EXTGridLineWidth = 0.25;
static const CGFloat _EXTDefaultGridSpacing = 9.0;
static const NSUInteger _EXTDefaultEmphasisSpacing = 8;
static NSColor *_EXTDefaultGridColor = nil;
static NSColor *_EXTDefaultEmphasisGridColor = nil;
static NSColor *_EXTDefaultAxisColor = nil;

@implementation EXTGrid

#pragma mark - Life cycle

+ (void)initialize {
    if (self == [EXTGrid class]) {
        _EXTDefaultGridColor = [NSColor lightGrayColor];
        _EXTDefaultEmphasisGridColor = [NSColor darkGrayColor];
        _EXTDefaultAxisColor = [NSColor blueColor];
    }
}

- (id)init {
    self = [super init];
    if (!self)
        return nil;

	_boundsRect = NSZeroRect;

	_gridSpacing = _EXTDefaultGridSpacing;
	_emphasisSpacing = _EXTDefaultEmphasisSpacing;

	_gridColor = _EXTDefaultGridColor;
	_emphasisGridColor = _EXTDefaultEmphasisGridColor;
	_axisColor = _EXTDefaultAxisColor;

	_gridPath = [self makeGridInRect:_boundsRect withFactor:1];
	_emphasisGridPath = [self makeGridInRect:_boundsRect withFactor:_emphasisSpacing];

    return self;
}

- (void)resetToDefaults{
	self.gridSpacing = _EXTDefaultGridSpacing;
	self.emphasisSpacing = _EXTDefaultEmphasisSpacing;
	
	self.gridColor = _EXTDefaultGridColor;
	self.emphasisGridColor = _EXTDefaultEmphasisGridColor;
	self.axisColor = _EXTDefaultAxisColor;
	
}

#pragma mark *** generating the gridPath ***

// makeGridInRect:withFactor:makes a grid in the rectangle with spacing self.gridSpacing*factor, with the origin of the coordinate system guaranteed to be on gridlines.

-(NSBezierPath *) makeGridInRect:(NSRect)rect withFactor:(NSUInteger) factor {
	CGFloat spacing = self.gridSpacing*factor;
	
	NSPoint verticalIncrement = NSMakePoint(spacing,-rect.size.height-spacing);
	NSPoint verticalTarget = NSMakePoint(0,rect.size.height+spacing);
	NSPoint horizontalIncrement	= NSMakePoint(-rect.size.width-spacing,spacing);
	NSPoint horizontalTarget = NSMakePoint(rect.size.width + spacing,0);

	
	NSBezierPath *path = [NSBezierPath bezierPath];
	[path setLineWidth:_EXTGridLineWidth];
	
	NSPoint startingPoint;
//	startingPoint.y =   rect.origin.y + fmod(rect.size.height/2, spacing);
//	startingPoint.x = rect.origin.x + fmod(rect.size.width/2, spacing);
	
	startingPoint.y =  floor(rect.origin.y/spacing)*spacing;
	startingPoint.x = floor(rect.origin.x/spacing)*spacing;
	
	[path moveToPoint:startingPoint];
	
	NSUInteger i = 0;
	do {
		[path relativeLineToPoint:verticalTarget];
		[path relativeMoveToPoint: verticalIncrement];
		i++;		
	} while (i <= ceil(rect.size.width/spacing));
	
	[path moveToPoint:startingPoint];
	i = 0;
	do {
		[path relativeLineToPoint:horizontalTarget];
		[path relativeMoveToPoint: horizontalIncrement];
		i++;		
	} while (i <= ceil(rect.size.height/spacing));
	return(path);
}


#pragma mark *** drawing ***

-(void) drawGrid{
	[_gridColor set];
	[_gridPath stroke];
	[_emphasisGridColor set];
	[_emphasisGridPath stroke];
}

-(void) drawGridInRect:(NSRect)rect{
	[_gridColor set];
	NSBezierPath *localGridPath;
	localGridPath = [self makeGridInRect:rect withFactor:1];
	[localGridPath stroke];
	[_emphasisGridColor set];
	localGridPath = [self makeGridInRect:rect withFactor:_emphasisSpacing];
	[localGridPath stroke];
}


-(void)drawAxes{
	NSBezierPath *path = [NSBezierPath bezierPath];
	[path setLineWidth:1.0];
	[_axisColor set];
	[path moveToPoint:NSMakePoint(NSMidX(_boundsRect), NSMinY(_boundsRect))];
	[path relativeLineToPoint:NSMakePoint(0.0, NSHeight(_boundsRect))];
	[path moveToPoint:NSMakePoint(NSMinX(_boundsRect), NSMidY(_boundsRect))];
	[path relativeLineToPoint:NSMakePoint(NSWidth(_boundsRect), 0.0)];
	[path stroke];
}

- (void) drawEnclosingRectAtPoint: (NSPoint)point{
	NSRect gridRect = [self enclosingGridRect:point];
	NSBezierPath *rectanglePath = [NSBezierPath bezierPathWithRect:gridRect];
	[rectanglePath setLineWidth:.5];
	[[NSColor blueColor] setStroke];
	[rectanglePath stroke];
}

#pragma mark *** setter methods ***

// because we need to regenerate the grid paths if these change.  An alternative would be to use KVO on self, but that seems kind of wrong to me.   Another methods would be to move the actual gridPath to the view, but then the drawing couldn't be done here, and I prefer that for reasons of better encapsulation.  

- (void) setGridSpacing:(CGFloat) spacing{
	_gridSpacing = spacing;
	// regenerate the gridPath and the emphasisGridPath
	self.gridPath = [self makeGridInRect:_boundsRect withFactor:1];
	self.emphasisGridPath = [self makeGridInRect:_boundsRect withFactor:_emphasisSpacing];

}

- (void) setEmphasisSpacing:(NSUInteger) spacing{
	_emphasisSpacing = spacing;	
	// regenerate the emphasisGridPath
	self.emphasisGridPath = [self makeGridInRect:_boundsRect withFactor:_emphasisSpacing];
}

- (void) setBoundsRect:(NSRect) rect{
	_boundsRect = rect;
	// regenerate the gridPath and the emphasisGridPath
	self.gridPath = [self makeGridInRect:_boundsRect withFactor:1];
	self.emphasisGridPath = [self makeGridInRect:_boundsRect withFactor:_emphasisSpacing];

}

#pragma mark *** grid points ***

//stolen from SKTGrid

- (NSPoint)nearestGridPoint:(NSPoint)point {
	NSPoint newPoint;
	newPoint.x = floor((point.x / _gridSpacing) + 0.5) * _gridSpacing;
	newPoint.y = floor((point.y / _gridSpacing) + 0.5) * _gridSpacing;
//	newPoint.x = ceil((point.x / gridSpacing)) * gridSpacing;
//	newPoint.y = ceil((point.y / gridSpacing)) * gridSpacing;

    return newPoint;
}

- (NSPoint)convertToGridCoordinates:(NSPoint)point{
	NSPoint newPoint;
	newPoint.x = floor(point.x/_gridSpacing);
	newPoint.y = floor(point.y/_gridSpacing);
	return newPoint;
}

- (NSPoint) lowerLeftGridPoint:(NSPoint)point{
	NSPoint newPoint;
	newPoint.x = floor(point.x/_gridSpacing)*_gridSpacing;
	newPoint.y = floor(point.y/_gridSpacing)*_gridSpacing;
	return newPoint;
}

- (NSRect)enclosingGridRect:(NSPoint)point {
	NSRect enclosingRect;
	enclosingRect.origin.x = floor(point.x/_gridSpacing)*_gridSpacing;
	enclosingRect.origin.y = floor(point.y/_gridSpacing)*_gridSpacing;
	enclosingRect.size.width = _gridSpacing;
	enclosingRect.size.height = _gridSpacing;
	
	return enclosingRect;	
}

#pragma mark *** KVO stuff ***

+(NSSet *)keyPathsForValuesAffectingAnyGridKey{
	return [NSSet setWithObjects:@"gridColor", @"emphasisGridColor", @"gridSpacing", @"emphasisSpacing", nil];
}

@end
