//
//  EXTDocumentInspectorView.m
//  Ext Chart
//
//  Created by Bavarious on 09/07/2013.
//  Copyright (c) 2013 Harvard University. All rights reserved.
//

#import "EXTDocumentInspectorView.h"
#import <QuartzCore/QuartzCore.h>


#pragma mark - Private variables

static const CGFloat _EXTLeftRightMargin = 10.0;
static const CGFloat _EXTTopMargin = 10.0;
static const CGFloat _EXTGroupHeaderHeight = 40.0;


@interface EXTDocumentInspectorGroupView : NSView
    @property(nonatomic, readonly) NSView *contentView;
    - (id)initWithFrame:(NSRect)frame contentView:(NSView *)contentView title:(NSString *)title;
@end


@implementation EXTDocumentInspectorView {
    CGFloat _contentHeight;
}

- (void)addSubview:(NSView *)subview withTitle:(NSString *)title {
    NSSize subviewSize = [subview frame].size;
    NSRect groupViewFrame = {
        .origin.x = _EXTLeftRightMargin,
        .origin.y = _contentHeight + _EXTTopMargin,
        .size.width = subviewSize.width,
        .size.height = subviewSize.height + _EXTGroupHeaderHeight
    };

    EXTDocumentInspectorGroupView *groupView = [[EXTDocumentInspectorGroupView alloc] initWithFrame:groupViewFrame contentView:subview title:title];
    [groupView setFrame:groupViewFrame];
    [groupView setAutoresizingMask:NSViewNotSizable];
    [self addSubview:groupView];

    _contentHeight += groupViewFrame.size.height;
}

+ (CGFloat)widthForContentWidth:(CGFloat)contentWidth {
    return contentWidth + (_EXTLeftRightMargin * 2);
}

- (BOOL)isFlipped {
    return YES;
}

- (void)drawRect:(NSRect)dirtyRect {
    NSRect leftBorderFrame = {
        .size.width = 2.0,
        .size.height = [self bounds].size.height
    };

    NSRect leftBorderDirtyFrame = NSIntersectionRect(leftBorderFrame, dirtyRect);
    if (!NSEqualRects(leftBorderDirtyFrame, NSZeroRect)) {
        leftBorderDirtyFrame.size.width = 0.5;
        [[NSColor blackColor] setFill];
        NSRectFill(leftBorderDirtyFrame);

        leftBorderDirtyFrame.origin.x = 1.0;
        [[NSColor whiteColor] setFill];
        NSRectFill(leftBorderDirtyFrame);
    }
}

@end


@implementation EXTDocumentInspectorGroupView

- (id)initWithFrame:(NSRect)frame contentView:(NSView *)contentView title:(NSString *)title {
    self = [super initWithFrame:frame];
    if (self) {
        _contentView = contentView;

        [contentView setFrameOrigin:(NSPoint){0.0, _EXTGroupHeaderHeight}];
        [self addSubview:contentView];

        [self setWantsLayer:YES];
        CALayer *layer = [self layer];
        [layer setBackgroundColor:[[NSColor windowBackgroundColor] CGColor]];
        [layer setCornerRadius:10.0];
        [layer setBorderColor:[[NSColor colorWithCalibratedWhite:0.5 alpha:1.0] CGColor]];
        [layer setBorderWidth:1.0];
        [layer setShadowOpacity:1.0];
        [layer setShadowColor:[[NSColor whiteColor] CGColor]];
        [layer setShadowOffset:(CGSize){0.0, 1.0}];
        [layer setShadowRadius:0.0];
        [layer setMasksToBounds:YES];

        CALayer *headerLayer = [CALayer layer];
        [headerLayer setBackgroundColor:[[NSColor colorWithCalibratedWhite:0.8 alpha:1.0] CGColor]];
        [headerLayer setFrame:(CGRect){{0.0, 0.0}, {frame.size.width, 30.0}}];
        [headerLayer setBorderColor:[[NSColor lightGrayColor] CGColor]];
        [headerLayer setBorderWidth:1.0];
        [headerLayer setShadowOpacity:1.0];
        [headerLayer setShadowColor:[[NSColor whiteColor] CGColor]];
        [headerLayer setShadowOffset:(CGSize){0.0, 1.0}];
        [headerLayer setShadowRadius:0.0];
        [layer addSublayer:headerLayer];

        CATextLayer *textLayer = [CATextLayer layer];
        [textLayer setString:title];
        [textLayer setAlignmentMode:kCAAlignmentCenter];
        [textLayer setFont:(__bridge CFTypeRef)[NSFont boldSystemFontOfSize:13.0]];
        [textLayer setFontSize:13.0];
        [textLayer setForegroundColor:[[NSColor blackColor] CGColor]];
        [textLayer setFrame:(CGRect){{0.0, 8.0}, {frame.size.width, 15.0}}];
        [textLayer setShadowOpacity:1.0];
        [textLayer setShadowColor:[[NSColor whiteColor] CGColor]];
        [textLayer setShadowOffset:(CGSize){0.0, 1.0}];
        [textLayer setShadowRadius:0.0];
        [headerLayer addSublayer:textLayer];

    }
    return self;
}

- (BOOL)isFlipped {
    return YES;
}

@end