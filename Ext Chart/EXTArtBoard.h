//
//  EXTArtBoard.h
//  Ext Chart
//
//  Created by Michael Hopkins on 8/13/11.
//  Copyright 2011 Harvard University. All rights reserved.
//

@import Cocoa;

typedef enum : NSUInteger {
    EXTArtBoardMouseDragOperationNone = 0,
    EXTArtBoardMouseDragOperationMove = 1u << 0,
    EXTArtBoardMouseDragOperationResize = 1u << 1,

    EXTArtBoardMouseDragOperationResizeTop = EXTArtBoardMouseDragOperationResize | 1u << 2,
    EXTArtBoardMouseDragOperationResizeBottom = EXTArtBoardMouseDragOperationResize | 1u << 3,
    EXTArtBoardMouseDragOperationResizeLeft = EXTArtBoardMouseDragOperationResize | 1u << 4,
    EXTArtBoardMouseDragOperationResizeRight = EXTArtBoardMouseDragOperationResize | 1u << 5,
} EXTArtBoardMouseDragOperation;


@interface EXTArtBoard : NSObject
    /*!
     @property frame
     @abstract The location of the art board in its containing view coordinate space.
     */
    @property(nonatomic, assign) NSRect frame;

    /*!
     @property drawingRect
     @abstract The rectangle used by the art board to draw itself in its containing view coordinate space.
     @discussion The drawing rectangle extends the art board frame
     */
    @property(nonatomic, assign, readonly) NSRect drawingRect;

    /*!
     @property minimumSize
     @abstract The minimum size of the art board in view coordinate space.
     */
    @property(nonatomic, assign) NSSize minimumSize;

    @property(nonatomic, assign) bool hasShadow;

    - (instancetype)initWithFrame:(NSRect)frame;

    - (void)fillRect;
    - (void)strokeRect;
    - (void)buildCursorRectsInView:(NSView *)view;

    - (EXTArtBoardMouseDragOperation)mouseDragOperationAtPoint:(NSPoint)point;
    - (void)startDragOperationAtPoint:(NSPoint)originalPoint;
    - (void)performDragOperationWithPoint:(NSPoint)point;
    - (void)finishDragOperation;
    - (void)cancelDragOperation;
@end
