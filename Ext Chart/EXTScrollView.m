//
//  EXTScrollView.m
//  Ext Chart
//
//  Created by Michael Hopkins on 7/24/11.
//  Copyright 2011 Harvard University. All rights reserved.
//

#import "EXTScrollView.h"


@implementation EXTScrollView

static Class _rulerViewClass;

+ (void)setRulerViewClass:(Class)rulerViewClass {
    _rulerViewClass = rulerViewClass;
}

+ (Class)rulerViewClass {
    return _rulerViewClass;
}

#pragma mark - Trackpad events

// TODO: the default implementation of -magnifyWithEvent: and -setMagnification:centeredAtPoint:
// do not work correctly with visible rulers, so we do it manually
- (void)magnifyWithEvent:(NSEvent *)event {
	NSClipView *clipView = [self contentView];
	const NSRect previousClipViewBounds = [clipView bounds];
	const CGFloat scale = 1 / ([event magnification] + 1.0);
    const NSPoint clipViewEventLocation = [clipView convertPoint:[event locationInWindow] fromView:nil];
    const NSRect newClipViewBounds = {
        .size.height = previousClipViewBounds.size.height * scale,
        .size.width = previousClipViewBounds.size.width * scale,
        .origin.x = previousClipViewBounds.origin.x * scale + clipViewEventLocation.x * (1 - scale),
        .origin.y = previousClipViewBounds.origin.y * scale + clipViewEventLocation.y * (1 - scale)
    };

    [clipView setBounds:newClipViewBounds];
}

#pragma mark - Zooming

// TODO: since -setMagnification:centeredAtPoint: does not work correctly with visible rulers,
// we do it manually
- (void)zoomToPoint:(NSPoint)point withScaling:(CGFloat)scale {
	NSView *clipView = [self contentView];
	const NSRect	 previousClipViewBounds = [clipView bounds];
	const CGFloat actualScale = 1 / scale;
	const NSRect newClipViewBounds = {
        .size.height = previousClipViewBounds.size.height * actualScale,
        .size.width = previousClipViewBounds.size.width * actualScale,
        .origin.x = previousClipViewBounds.origin.x * actualScale + point.x * (1 - actualScale),
        .origin.y = previousClipViewBounds.origin.y * actualScale + point.y * (1 - actualScale)
    };

    [clipView setBounds:newClipViewBounds];
}

#pragma mark - Scrolling

- (IBAction)scrollOriginToCenter:(id)sender {
    NSView *documentView = [self documentView];
    const NSRect documentViewBounds = [documentView bounds];
    const NSSize clipViewSize = [[self contentView] bounds].size;
    const NSPoint contentViewOrigin = {
        .x = NSMidX(documentViewBounds) - clipViewSize.width / 2.0,
        .y = NSMidY(documentViewBounds) - clipViewSize.height / 2.0
    };

    [documentView scrollPoint:contentViewOrigin];
}

- (IBAction)scrollOriginToLowerLeft:(id)sender {
    NSView *documentView = [self documentView];
    const NSRect documentViewBounds = [documentView bounds];
    const NSPoint contentViewOrigin = {NSMidX(documentViewBounds), NSMidY(documentViewBounds)};
    
    [documentView scrollPoint:contentViewOrigin];
}

@end
