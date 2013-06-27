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

static const NSSize _EXTArtBoardDefaultSize = {360, 216};
static const NSSize _EXTArtBoardMinimumSize = {50, 50};
static NSColor *_EXTArtBoardBackgroundColour = nil;
static NSColor *_EXTArtBoardBorderColour = nil;
static const CGFloat _EXTArtBoardBorderWidth = 1.0;

static NSShadow *_EXTArtBoardShadow = nil;
static NSColor *_EXTArtBoardShadowColour = nil;
static const NSSize _EXTArtBoardShadowOffset = {-1.0, -2.0};
static const CGFloat _EXTArtBoardShadowBlurRadius = 2.0;

static const CGFloat _EXTArtBoardResizeCursorHotSpotLength = 8.0;
static const CGFloat _EXTArtBoardResizeCursorHotSpotHalfLength = 4.0;

static const NSSize _EXTArtBoardDrawingInset = {-4.0, -4.0};


NS_INLINE void EXTArtBoardComputeHotSpotFrames(const NSRect frame,
                                               NSRect *restrict innerFrame, // output parameters
                                               NSRect *restrict leftFrame,
                                               NSRect *restrict rightFrame,
                                               NSRect *restrict topFrame,
                                               NSRect *restrict bottomFrame)
{
    const CGFloat len = _EXTArtBoardResizeCursorHotSpotLength;
    const CGFloat halfLen = _EXTArtBoardResizeCursorHotSpotHalfLength;
    const NSRect hotSpotFrame = NSInsetRect(frame, -halfLen, -halfLen); // expands the frame to include extra hot spot borders
    const CGFloat minX = NSMinX(hotSpotFrame);
    const CGFloat maxX = NSMaxX(hotSpotFrame);
    const CGFloat minY = NSMinY(hotSpotFrame);
    const CGFloat maxY = NSMaxY(hotSpotFrame);
    

    if (innerFrame) *innerFrame = NSInsetRect(frame, halfLen, halfLen);

    if (leftFrame) *leftFrame = (NSRect){{minX, minY}, {len, hotSpotFrame.size.height}};
    if (rightFrame) *rightFrame = (NSRect){{maxX - len, minY}, {len, hotSpotFrame.size.height}};
    if (topFrame) *topFrame = (NSRect){{minX, maxY - len}, {hotSpotFrame.size.width, len}};
    if (bottomFrame) *bottomFrame = (NSRect){{minX, minY}, {hotSpotFrame.size.width, len}};
}

@implementation EXTArtBoard {
    EXTArtBoardMouseDragOperation _dragOperation;
    NSPoint _initialDragPoint;
    NSRect _initialDragFrame;
}

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

#pragma mark - Mouse dragging

- (EXTArtBoardMouseDragOperation)mouseDragOperationAtPoint:(NSPoint)point {
    if (! NSPointInRect(point, [self drawingRect]))
        return EXTArtBoardMouseDragOperationNone;

    NSRect innerFrame, topFrame, bottomFrame, leftFrame, rightFrame;
    EXTArtBoardComputeHotSpotFrames(_frame, &innerFrame, &leftFrame, &rightFrame, &topFrame, &bottomFrame);

    if (NSPointInRect(point, innerFrame))
        return EXTArtBoardMouseDragOperationMove;

    EXTArtBoardMouseDragOperation dragOperation = EXTArtBoardMouseDragOperationResize;

    if (NSPointInRect(point, leftFrame))
        dragOperation |= EXTArtBoardMouseDragOperationResizeLeft;
    else if (NSPointInRect(point, rightFrame))
        dragOperation |= EXTArtBoardMouseDragOperationResizeRight;

    if (NSPointInRect(point, topFrame))
        dragOperation |= EXTArtBoardMouseDragOperationResizeTop;
    else if (NSPointInRect(point, bottomFrame))
        dragOperation |= EXTArtBoardMouseDragOperationResizeBottom;

    return dragOperation;
}

- (void)startDragOperationAtPoint:(NSPoint)originalPoint {
    _dragOperation = [self mouseDragOperationAtPoint:originalPoint];
    if (_dragOperation == EXTArtBoardMouseDragOperationNone)
        return;
    
    _initialDragPoint = originalPoint;
    _initialDragFrame = _frame;

    if (_dragOperation == EXTArtBoardMouseDragOperationMove)
        [[NSCursor closedHandCursor] push];
}

- (void)performDragOperationWithPoint:(NSPoint)point {
    const NSSize mouseOffset = {
        .width = point.x - _initialDragPoint.x,
        .height = point.y - _initialDragPoint.y,
    };

    NSRect targetFrame = _frame;

    if (_dragOperation == EXTArtBoardMouseDragOperationMove) {
        targetFrame = NSOffsetRect(_initialDragFrame, mouseOffset.width, mouseOffset.height);
    }
    else if ((_dragOperation & EXTArtBoardMouseDragOperationResize) == EXTArtBoardMouseDragOperationResize) {
        if ((_dragOperation & EXTArtBoardMouseDragOperationResizeTop) == EXTArtBoardMouseDragOperationResizeTop) {
            const CGFloat targetHeight = _initialDragFrame.size.height + mouseOffset.height;

            if (targetHeight >= _EXTArtBoardMinimumSize.height)
                targetFrame.size.height = targetHeight;
        }
        else if ((_dragOperation & EXTArtBoardMouseDragOperationResizeBottom) == EXTArtBoardMouseDragOperationResizeBottom) {
            const CGFloat targetHeight = _initialDragFrame.size.height - mouseOffset.height;

            if (targetHeight >= _EXTArtBoardMinimumSize.height) {
                targetFrame.size.height = targetHeight;
                targetFrame.origin.y = _initialDragFrame.origin.y + mouseOffset.height;
            }
        }

        if ((_dragOperation & EXTArtBoardMouseDragOperationResizeLeft) == EXTArtBoardMouseDragOperationResizeLeft) {
            const CGFloat targetWidth = _initialDragFrame.size.width - mouseOffset.width;

            if (targetWidth >= _EXTArtBoardMinimumSize.width) {
                targetFrame.size.width = targetWidth;
                targetFrame.origin.x = _initialDragFrame.origin.x + mouseOffset.width;
            }
        }
        else if ((_dragOperation & EXTArtBoardMouseDragOperationResizeRight) == EXTArtBoardMouseDragOperationResizeRight) {
            const CGFloat targetWidth = _initialDragFrame.size.width + mouseOffset.width;

            if (targetWidth >= _EXTArtBoardMinimumSize.width)
                targetFrame.size.width = targetWidth;
        }
    }

    if (! NSEqualRects(_frame, targetFrame))
        [self setFrame:targetFrame];
}

- (void)finishDragOperation {
    if (_dragOperation == EXTArtBoardMouseDragOperationMove)
        [NSCursor pop];

    _dragOperation = EXTArtBoardMouseDragOperationNone;
}

- (void)cancelDragOperation {
    if (_dragOperation != EXTArtBoardMouseDragOperationNone)
        [self setFrame:_initialDragFrame];
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
    
    NSRect innerFrame, topFrame, bottomFrame, leftFrame, rightFrame;
    EXTArtBoardComputeHotSpotFrames(_frame, &innerFrame, &leftFrame, &rightFrame, &topFrame, &bottomFrame);

    // Compute corner hot spots

    const NSRect topLeftFrame = NSIntersectionRect(topFrame, leftFrame);
    const NSRect topRightFrame = NSIntersectionRect(topFrame, rightFrame);
    const NSRect bottomLeftFrame = NSIntersectionRect(bottomFrame, leftFrame);
    const NSRect bottomRightFrame = NSIntersectionRect(bottomFrame, rightFrame);

    // Subtract corner hot spots from the edges

    topFrame = NSInsetRect(topFrame, _EXTArtBoardResizeCursorHotSpotLength, 0);
    bottomFrame = NSInsetRect(bottomFrame, _EXTArtBoardResizeCursorHotSpotLength, 0);
    leftFrame = NSInsetRect(leftFrame, 0, _EXTArtBoardResizeCursorHotSpotLength);
    rightFrame = NSInsetRect(rightFrame, 0, _EXTArtBoardResizeCursorHotSpotLength);

    // Set cursors
    // TODO: maybe use limited resize cursors
    [view addCursorRect:innerFrame cursor:[NSCursor openHandCursor]];
	[view addCursorRect:leftFrame cursor:[NSCursor resizeLeftRightCursor]];
	[view addCursorRect:rightFrame cursor:[NSCursor resizeLeftRightCursor]];
	[view addCursorRect:bottomFrame cursor:[NSCursor resizeUpDownCursor]];
	[view addCursorRect:topFrame cursor:[NSCursor resizeUpDownCursor]];
	[view addCursorRect:topLeftFrame cursor:[NSCursor _topLeftResizeCursor]];
	[view addCursorRect:topRightFrame cursor:[NSCursor _topRightResizeCursor]];
	[view addCursorRect:bottomLeftFrame cursor:[NSCursor _bottomLeftResizeCursor]];
	[view addCursorRect:bottomRightFrame cursor:[NSCursor _bottomRightResizeCursor]];
}

@end
