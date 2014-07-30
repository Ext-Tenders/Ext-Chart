//
//  EXTDocumentControlsView.m
//  Ext Chart
//
//  Created by Bavarious on 02/07/2013.
//  Copyright (c) 2013 Harvard University. All rights reserved.
//

#import "EXTDocumentControlsView.h"


#pragma mark - Private variables

static NSShadow *_EXTBorderShadow = nil;
static NSColor *_EXTTopBackgroundColor = nil;
static NSColor *_EXTBottomBackgroundColor = nil;

@implementation EXTDocumentControlsView

#pragma mark - Life cycle

+ (void)initialize {
    if (self == [EXTDocumentControlsView class]) {
        _EXTBorderShadow = [NSShadow new];
        [_EXTBorderShadow setShadowColor:[NSColor whiteColor]];
        [_EXTBorderShadow setShadowBlurRadius:2.0];
        [_EXTBorderShadow setShadowOffset:(NSSize){0.0, -2.0}];

        _EXTTopBackgroundColor = [NSColor colorWithDeviceWhite:0.95 alpha:1.0];
        _EXTBottomBackgroundColor = [NSColor colorWithDeviceWhite:0.9 alpha:1.0];
    }
}

#pragma mark - Drawing

- (void)_extDrawBackground:(NSRect)dirtyRect {
    NSRect topRect, bottomRect;
    NSRect bounds = [self bounds];
    NSDivideRect(bounds, &topRect, &bottomRect, bounds.size.height / 2.0, NSMaxYEdge);

    NSRect dirtyTop = NSIntersectionRect(dirtyRect, topRect);
    if (!NSEqualRects(dirtyTop, NSZeroRect)) {
        [_EXTTopBackgroundColor setFill];
        NSRectFill(topRect);
    }

    NSRect dirtyBottom = NSIntersectionRect(dirtyRect, bottomRect);
    if (!NSEqualRects(dirtyBottom, NSZeroRect)) {
        [_EXTBottomBackgroundColor setFill];
        NSRectFill(bottomRect);
    }
}

- (void)_extDrawBorders:(NSRect)dirtyRect {
    const NSRect bounds = [self bounds];
    const CGFloat maxX = NSMaxX(bounds);
    const CGFloat maxY = NSMaxY(bounds);
    const CGFloat minX = NSMinX(bounds);

    NSBezierPath *borderPath = [NSBezierPath bezierPath];

    [borderPath moveToPoint:(NSPoint){minX, maxY}];
    [borderPath lineToPoint:(NSPoint){maxX, maxY}];
    [[NSColor blackColor] setStroke];
    [_EXTBorderShadow set];
    [borderPath stroke];
}

- (void)drawRect:(NSRect)dirtyRect {
    [self _extDrawBackground:dirtyRect];
    [super drawRect:dirtyRect];
    [self _extDrawBorders:dirtyRect];
}

@end
