//
//  EXTArtBoard.m
//  Ext Chart
//
//  Created by Michael Hopkins on 8/13/11.
//  Copyright 2011 Harvard University. All rights reserved.
//

#import "EXTArtBoard.h"
#import "NSCursor+EXTApplePrivate.h"


#pragma mark - Private variables

static const NSSize _EXTArtBoardDefaultSize = {792, 612};
static NSColor *_EXTArtBoardBackgroundColour = nil;
static NSColor *_EXTArtBoardBorderColour = nil;
static const CGFloat _EXTArtBoardBorderWidth = 1.0;

static NSShadow *_EXTArtBoardShadow = nil;
static NSColor *_EXTArtBoardShadowColour = nil;
static const NSSize _EXTArtBoardShadowOffset = {-1.0, -2.0};
static const CGFloat _EXTArtBoardShadowBlurRadius = 2.0;

static const CGFloat _EXTArtBoardResizeCursorLength = 8.0;
static const NSSize _EXTArtBoardDrawingInset = {-4.0, -4.0};


@implementation EXTArtBoard

#pragma mark - Life cycle

+ (void)initialize {
    if (self == [EXTArtBoard class]) {
        _EXTArtBoardBackgroundColour = [NSColor whiteColor];
        _EXTArtBoardBorderColour = [NSColor blackColor];
        _EXTArtBoardShadowColour = [[NSColor blackColor] colorWithAlphaComponent:0.3];

        _EXTArtBoardShadow = [NSShadow new];
        [_EXTArtBoardShadow setShadowColor:_EXTArtBoardShadowColour];
        [_EXTArtBoardShadow setShadowOffset:_EXTArtBoardShadowOffset];
        [_EXTArtBoardShadow setShadowBlurRadius:_EXTArtBoardShadowBlurRadius];
    }
}

- (id)init {
    return [self initWithFrame:(NSRect){NSZeroPoint, _EXTArtBoardDefaultSize}];
}

- (id)initWithFrame:(NSRect)frame {
    self = [super init];
    if (self) {
        _frame = frame;
    }
    return self;
}

#pragma mark - Drawing

- (void)fillRect {
	NSBezierPath *documentRectanglePath = [NSBezierPath bezierPathWithRect:_frame];
    [_EXTArtBoardBackgroundColour set];
	[documentRectanglePath fill];
}

- (void)strokeRect {
	NSBezierPath *documentRectanglePath = [NSBezierPath bezierPathWithRect:_frame];

	[NSGraphicsContext saveGraphicsState];
	{
        [documentRectanglePath setLineWidth:_EXTArtBoardBorderWidth];
        [_EXTArtBoardBorderColour set];
        [_EXTArtBoardShadow set];
        [documentRectanglePath stroke];
    }
	[NSGraphicsContext restoreGraphicsState];
}

#pragma mark - Properties

- (NSRect)drawingRect {
	return NSInsetRect(_frame, _EXTArtBoardDrawingInset.width, _EXTArtBoardDrawingInset.height);
}

#pragma mark - Key-value observing

+ (NSSet *)keyPathsForValuesAffectingDrawingRect {
    return [NSSet setWithObject:@"frame"];
}

#pragma mark - Cursors

- (void)buildCursorRectsInView:(NSView *)view {
    const CGFloat minX = NSMinX(_frame);
    const CGFloat maxX = NSMaxX(_frame);
    const CGFloat minY = NSMinY(_frame);
    const CGFloat maxY = NSMaxY(_frame);

    const CGFloat length = _EXTArtBoardResizeCursorLength;
    const CGFloat halfLength = length / 2;
    const NSSize cursorAreaSize = {length, length};

    // Corners

    const NSRect bottomLeftSquare = {{minX - halfLength, minY - halfLength}, cursorAreaSize};
    const NSRect bottomRightSquare = {{maxX - halfLength, minY - halfLength}, cursorAreaSize};
    const NSRect topLeftSquare = {{minX - halfLength, maxY - halfLength}, cursorAreaSize};
    const NSRect topRightSquare = {{maxX - halfLength, maxY - halfLength}, cursorAreaSize};

	[view addCursorRect:bottomLeftSquare cursor:[NSCursor _bottomLeftResizeCursor]];
	[view addCursorRect:bottomRightSquare cursor:[NSCursor _bottomRightResizeCursor]];
	[view addCursorRect:topLeftSquare cursor:[NSCursor _topLeftResizeCursor]];
	[view addCursorRect:topRightSquare cursor:[NSCursor _topRightResizeCursor]];

    // Borders

    const NSRect leftBorder = {{minX - halfLength, minY + halfLength}, {length, _frame.size.height - length}};
    const NSRect rightBorder = {{maxX - halfLength, minY + halfLength}, {length, _frame.size.height - length}};
    const NSRect bottomBorder = {{minX + halfLength, minY - halfLength}, {_frame.size.width - length, length}};
    const NSRect topBorder = {{minX + halfLength, maxY - halfLength}, {_frame.size.width - length, length}};

	[view addCursorRect:leftBorder cursor:[NSCursor resizeLeftRightCursor]];
	[view addCursorRect:rightBorder cursor:[NSCursor resizeLeftRightCursor]];
	[view addCursorRect:bottomBorder cursor:[NSCursor resizeUpDownCursor]];
	[view addCursorRect:topBorder cursor:[NSCursor resizeUpDownCursor]];

    // Inner rectangle

    [view addCursorRect:NSInsetRect(_frame, length, length) cursor:[NSCursor openHandCursor]];
}


@end
