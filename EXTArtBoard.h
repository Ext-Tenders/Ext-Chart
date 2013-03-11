//
//  EXTArtBoard.h
//  Ext Chart
//
//  Created by Michael Hopkins on 8/13/11.
//  Copyright 2011 HLProducts. All rights reserved.
//

#import <Cocoa/Cocoa.h>


// i'm running into a dumb KVO complication having to do with declaring which rectangle is dirty after updating the artBoard.  The issues make it clear that the ivar to keep track of is the rectangle of the artboard, and not the xPosition, yPosition, etc.   So the way to do this is to make "bounds" an ivar, and have the view observe it.   Changes to "bounds" will give both the old and new bounds retangles, and we can just tell the view that those two rects are dirty.   I still need to have setters and getters for xPosition, yPostion, width, and height, so that the bounds can also be set by the panel.  But these "setters" will just be methods, which call [self setBounds].

extern NSString *EXTArtBoardBoundsKey;
extern NSString *EXTArtBoardDrawingRectKey;

@interface EXTArtBoard : NSObject {
	NSRect bounds;
	NSPoint anchor;
	BOOL editing, moving;
}

//@property(assign) CGFloat xPosition, yPosition, width, height;
@property(assign) NSRect bounds;
@property(assign) BOOL editing, moving;



-(void) fillRect;
-(void) strokeRect;
-(id) init;
-(id) initWithRect:(NSRect) rect;
-(void) buildCursorRects:(NSView *)sender;

- (NSRect) drawingRect;

- (CGFloat)xPosition;
- (CGFloat)yPosition;
- (CGFloat)width;
- (CGFloat)height;

- (void)setXPosition:(CGFloat)x;
- (void)setYPosition:(CGFloat)y;
- (void)setWidth:(CGFloat)w;
- (void)setHeight:(CGFloat)h;


@end
