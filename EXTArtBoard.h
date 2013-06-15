//
//  EXTArtBoard.h
//  Ext Chart
//
//  Created by Michael Hopkins on 8/13/11.
//  Copyright 2011 Harvard University. All rights reserved.
//

#import <Cocoa/Cocoa.h>


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

    - (id)initWithFrame:(NSRect)frame;

    - (void)fillRect;
    - (void)strokeRect;
    - (void)buildCursorRectsInView:(NSView *)view;
@end
