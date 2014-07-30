//
//  NSCursor+EXTApplePrivate.h
//  Ext Chart
//
//  Created by Bavarious on 15/06/2013.
//  Copyright (c) 2013 Harvard University. All rights reserved.
//

@import Cocoa;

// NSCursor exports border resize cursors but it doesn’t export corner resize cursors
@interface NSCursor (EXTApplePrivate)
    + (instancetype)_bottomLeftResizeCursor;
    + (instancetype)_topLeftResizeCursor;
    + (instancetype)_bottomRightResizeCursor;
    + (instancetype)_topRightResizeCursor;
@end
