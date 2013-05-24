//
//  EXTArtBoard.m
//  Ext Chart
//
//  Created by Michael Hopkins on 8/13/11.
//  Copyright 2011 HLProducts. All rights reserved.
//

#import "EXTArtBoard.h"

NSString *EXTArtBoardBoundsKey = @"bounds";
NSString *EXTArtBoardDrawingRectKey = @"drawingRect";

@implementation EXTArtBoard

//@synthesize xPosition, yPosition, width, height;
@synthesize bounds;
@synthesize editing, moving;

#pragma mark ** initialization ***

-(id) init{
	if (!(self = [self initWithRect:NSMakeRect(0, 0, 792, 612)])) return nil;
	return self;
}

-(id) initWithRect:(NSRect) rect{
	if (self = [super init]) {
		// not supposed to used these setters in init.   But I'm not sure if the object synced to them work.
		bounds = rect;		
		anchor =  NSZeroPoint;
	}
	return self;
}

#pragma mark *** drawing ***

-(void) fillRect{
	NSBezierPath *documentRectanglePath = [NSBezierPath bezierPathWithRect:bounds];
	[[NSColor whiteColor] set];
	[documentRectanglePath fill];
}

-(void) strokeRect{
	NSBezierPath *documentRectanglePath = [NSBezierPath bezierPathWithRect:bounds];

	[NSGraphicsContext saveGraphicsState];
	
	[documentRectanglePath setLineWidth:1.0];
	[[NSColor blackColor] set];
	
	NSShadow *theShadow = [[NSShadow alloc] init];
	[theShadow setShadowOffset:NSMakeSize(-1.0, -2.0)];
	[theShadow setShadowBlurRadius:2.0];
	[theShadow setShadowColor:[[NSColor blackColor]
							   colorWithAlphaComponent:0.3]];
	[theShadow set];
	
	[documentRectanglePath stroke];
	[NSGraphicsContext restoreGraphicsState];
}

#pragma mark *** the setters and getters for the components of bounds, and the drawingRect ***

- (CGFloat)xPosition{
	return [self bounds].origin.x;
}

- (CGFloat)yPosition{
	return [self bounds].origin.y;
}

- (CGFloat)width{
	return [self bounds].size.width;	
}

- (CGFloat)height{
	return [self bounds].size.height;	
}
		

// I'm not sure if the [self setBounds:bounds] is really necessary.   Above we say that xPosition, yPosition, width, and height are keys affecting the bounds key, so they should trigger a change, I think.   Unless they aren't "exposed bindings."

 

// also, SKTGraphic.m defines these setters by     
//NSRect bounds = [self bounds]; 
//bounds.origin.x = xPosition; 
//[self setBounds:bounds];
// my method looks kind of kludgy, but it seems to work.  I'll probably change it. 

// followup:  as you can see below, the setXPosition method doesn't call setBounds, and it seems to work.  
			
- (void)setXPosition:(CGFloat)x{
	bounds.origin.x = x;
//	[self setBounds:bounds];
}
- (void)setYPosition:(CGFloat)y{
	bounds.origin.y = y;
	[self setBounds:bounds];
}
- (void)setWidth:(CGFloat)w{
	bounds.size.width = w;
	[self setBounds:bounds];
}

- (void)setHeight:(CGFloat)h{
	bounds.size.height = h;
	[self setBounds:bounds];	
}
			
						
- (NSRect)drawingRect{
	return NSInsetRect(bounds, -4, -4);
}

#pragma mark *** KVO stuff ***

+(NSSet *)keyPathsForValuesAffectingBounds{
	return [NSSet setWithObjects:@"xPosition", @"yPosition", @"width", @"height", nil];
}

+(NSSet *)keyPathsForValuesAffectingDrawingRect{
	return [NSSet setWithObjects:@"xPosition", @"yPosition", @"width", @"height", nil];
}

#pragma mark *** cursor rectangles ***

-(void) buildCursorRects:(NSView *)sender{
	
// the 4 little squares
	
	short halfWidth = 4.0;
	
	NSRect bottomLeftSquare = NSMakeRect(bounds.origin.x-halfWidth, bounds.origin.y-halfWidth, 2*halfWidth, 2*halfWidth);
	NSRect bottomRightSquare = NSMakeRect(bounds.origin.x+bounds.size.width-halfWidth, bounds.origin.y-halfWidth, 2*halfWidth, 2*halfWidth);
	NSRect upperLeftSquare = NSMakeRect(bounds.origin.x-halfWidth, bounds.origin.y+bounds.size.height-halfWidth, 2*halfWidth, 2*halfWidth);
	NSRect upperRightSquare = NSMakeRect(bounds.origin.x+bounds.size.width-halfWidth, bounds.origin.y+bounds.size.height-halfWidth, 2*halfWidth, 2*halfWidth);
	
	
	[sender addCursorRect:bottomLeftSquare cursor:[NSCursor crosshairCursor]];
	[sender addCursorRect:bottomRightSquare cursor:[NSCursor crosshairCursor]];
	[sender addCursorRect:upperLeftSquare cursor:[NSCursor crosshairCursor]];
	[sender addCursorRect:upperRightSquare cursor:[NSCursor crosshairCursor]];
	
// the 4 long rectangles, and the inner rectangle
	
	NSRect leftSide = NSMakeRect(bounds.origin.x - halfWidth, bounds.origin.y + halfWidth, 2*halfWidth, bounds.size.height - 2*halfWidth);
	NSRect bottom = NSMakeRect(bounds.origin.x + halfWidth, bounds.origin.y - halfWidth, bounds.size.width -  2*halfWidth , 2*halfWidth);
	NSRect rightSide = NSMakeRect(bounds.origin.x + bounds.size.width - halfWidth, bounds.origin.y + halfWidth, 2*halfWidth, bounds.size.height - 2*halfWidth);
	NSRect	top = NSMakeRect(bounds.origin.x+halfWidth, bounds.origin.y+bounds.size.height-halfWidth, bounds.size.width-2*halfWidth, 2*halfWidth);
//	NSRect innerRect = NSInsetRect(bounds, halfWidth, halfWidth);
	
	[sender addCursorRect:leftSide cursor:[NSCursor resizeLeftRightCursor]];
	[sender addCursorRect:bottom cursor:[NSCursor resizeUpDownCursor]];
	[sender addCursorRect:rightSide cursor:[NSCursor resizeLeftRightCursor]];
	[sender addCursorRect:top cursor:[NSCursor resizeUpDownCursor]];

//	[sender addCursorRect:innerRect cursor:[NSCursor openHandCursor]];

	
}

#pragma mark *** mouse handling ***

	
@end
