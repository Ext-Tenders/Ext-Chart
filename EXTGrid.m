//
//  EXTGrid.m
//  Ext Chart
//
//  Created by Michael Hopkins on 7/20/11.
//  Copyright 2011 Harvard University. All rights reserved.
//

#import "EXTGrid.h"

// I guess a string constant is an exposed binding.  

NSString * const EXTGridAnyKey = @"anyGridKey";


@implementation EXTGrid

@synthesize gridColor, emphasisGridColor, axisColor, gridSpacing, emphasisSpacing, boundsRect;
@synthesize gridPath, emphasisGridPath;

#pragma mark *** initializers ***

- (id)init{
    self = [super init];
    if (self) {
		if (!(self = [self initWithRect:NSZeroRect])) return nil;
	}
    return self;
}


// initWithRect: is the designated initializer

// let's get rid of it.   Use a small default rect in the init method, and then use a setter method to set it.

-(id) initWithRect:(NSRect) rect{
	self = [super init];
	if (self) {

		// use the property setters here?  I think it's OK to write self.gridspacing = 9.0 instead of [self gridSpacing:9.0]
		boundsRect = rect;
		
		gridSpacing = 9.0;
		emphasisSpacing = 8;
		
		// here's a problem.   to deal with KVO stuff we need to call the setter for gridSpacing (or remove the observer from the scrollview).   But we can't initialize with them because they rebuild the grid paths, and call undefined functions at this point.   Ugh.  I either need to check for null values into the grid path building function, and offer defaults, or..something.   see the error log
		
		// OK.  I've resolved this.   It was  a problem with the order in which files were loading.   I put a grid object in the nib file and put a default rectangle in the init method.   We probably want to remove the "emphasisGridSpacing" text field from the main view, in which case there is no real compelling reason to have the grid in the nib, except perhaps, to make it easier to bind some of the document ivars to ones in the grid.  tbc...		


		gridColor = [NSColor lightGrayColor];
		emphasisGridColor = [NSColor darkGrayColor];
		axisColor = [NSColor blueColor];
		
		gridPath = [self makeGridInRect:boundsRect withFactor:1];
		
		emphasisGridPath = [self makeGridInRect:boundsRect withFactor:emphasisSpacing];

	}
	return self;
}

-(void) awakeFromNib{
	boundsRect = NSMakeRect(0, 0, 1, 1);
	
	gridSpacing = 9.0;
	emphasisSpacing = 8;
		
	gridColor = [NSColor lightGrayColor];
	emphasisGridColor = [NSColor darkGrayColor];
	axisColor = [NSColor blueColor];
	
	gridPath = [self makeGridInRect:boundsRect withFactor:1];
	
	emphasisGridPath = [self makeGridInRect:boundsRect withFactor:emphasisSpacing];
}

- (void)resetToDefaults{
	self.gridSpacing = 9.0;
	self.emphasisSpacing = 8;
	
	self.gridColor = [NSColor lightGrayColor];
	self.emphasisGridColor = [NSColor darkGrayColor];
	self.axisColor = [NSColor blueColor];
	
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
	[path setLineWidth:GRID_LINE_WIDTH];
	
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
	[gridColor set];
	[gridPath stroke];
	[emphasisGridColor set];
	[emphasisGridPath stroke];
}

-(void) drawGridInRect:(NSRect)rect{
	[gridColor set];
	NSBezierPath *localGridPath;
	localGridPath = [self makeGridInRect:rect withFactor:1];
	[localGridPath stroke];
	[emphasisGridColor set];
	localGridPath = [self makeGridInRect:rect withFactor:emphasisSpacing];
	[localGridPath stroke];
}


-(void)drawAxes{
	NSBezierPath *path = [NSBezierPath bezierPath];
	[path setLineWidth:1.0];
	[axisColor set];
	[path moveToPoint:NSMakePoint(NSMidX(boundsRect), NSMinY(boundsRect))];
	[path relativeLineToPoint:NSMakePoint(0.0, NSHeight(boundsRect))];
	[path moveToPoint:NSMakePoint(NSMinX(boundsRect), NSMidY(boundsRect))];
	[path relativeLineToPoint:NSMakePoint(NSWidth(boundsRect), 0.0)];
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
	gridSpacing = spacing;
	// regenerate the gridPath and the emphasisGridPath
	self.gridPath = [self makeGridInRect:boundsRect withFactor:1];
	self.emphasisGridPath = [self makeGridInRect:boundsRect withFactor:emphasisSpacing];

}

- (void) setEmphasisSpacing:(NSUInteger) spacing{
	emphasisSpacing = spacing;	
	// regenerate the emphasisGridPath
	self.emphasisGridPath = [self makeGridInRect:boundsRect withFactor:emphasisSpacing];
}

- (void) setBoundsRect:(NSRect) rect{
	boundsRect = rect;
	// regenerate the gridPath and the emphasisGridPath
	self.gridPath = [self makeGridInRect:boundsRect withFactor:1];
	self.emphasisGridPath = [self makeGridInRect:boundsRect withFactor:emphasisSpacing];

}

#pragma mark *** grid points ***

//stolen from SKTGrid

- (NSPoint)nearestGridPoint:(NSPoint)point {
	NSPoint newPoint;
	newPoint.x = floor((point.x / gridSpacing) + 0.5) * gridSpacing;
	newPoint.y = floor((point.y / gridSpacing) + 0.5) * gridSpacing;
//	newPoint.x = ceil((point.x / gridSpacing)) * gridSpacing;
//	newPoint.y = ceil((point.y / gridSpacing)) * gridSpacing;

    return newPoint;
}

- (NSPoint)convertToGridCoordinates:(NSPoint)point{
	NSPoint newPoint;
	newPoint.x = floor(point.x/gridSpacing);
	newPoint.y = floor(point.y/gridSpacing);
	return newPoint;
}

- (NSPoint) lowerLeftGridPoint:(NSPoint)point{
	NSPoint newPoint;
	newPoint.x = floor(point.x/gridSpacing)*gridSpacing;
	newPoint.y = floor(point.y/gridSpacing)*gridSpacing;
	return newPoint;
}

- (NSRect)enclosingGridRect:(NSPoint)point {
	NSRect enclosingRect;
	enclosingRect.origin.x = floor(point.x/gridSpacing)*gridSpacing;
	enclosingRect.origin.y = floor(point.y/gridSpacing)*gridSpacing;
	enclosingRect.size.width = gridSpacing;
	enclosingRect.size.height = gridSpacing;
	
	return enclosingRect;	
}

#pragma mark *** KVO stuff ***

+(NSSet *)keyPathsForValuesAffectingAnyGridKey{
	return [NSSet setWithObjects:@"gridColor", @"emphasisGridColor", @"gridSpacing", @"emphasisSpacing", nil];
}

@end
