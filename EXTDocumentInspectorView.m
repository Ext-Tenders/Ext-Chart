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
// TODO: more constants


@interface EXTDocumentInspectorGroupView : NSView
    @property(nonatomic, readonly) NSView *contentView;
    @property(nonatomic, assign) bool collapsed;
    - (id)initWithFrame:(NSRect)frame contentView:(NSView *)contentView title:(NSString *)title;
@end


@interface EXTDocumentInspectorView ()
    - (void)didClickHeader:(EXTDocumentInspectorGroupView *)groupView;
@end


@implementation EXTDocumentInspectorView

- (void)addSubview:(NSView *)subview withTitle:(NSString *)title {
    NSSize frameSize = [self frame].size;
    NSSize subviewSize = [subview frame].size;
    NSRect groupViewFrame = {
        .origin.x = _EXTLeftRightMargin,
        .origin.y = frameSize.height + _EXTTopMargin,
        .size.width = subviewSize.width,
        .size.height = subviewSize.height + _EXTGroupHeaderHeight
    };

    frameSize.height += groupViewFrame.size.height + _EXTTopMargin;
    frameSize.width = MAX(frameSize.width, groupViewFrame.size.width + _EXTLeftRightMargin * 2);
    [self setFrameSize:frameSize];

    EXTDocumentInspectorGroupView *groupView = [[EXTDocumentInspectorGroupView alloc] initWithFrame:groupViewFrame contentView:subview title:title];
    groupViewFrame.size.width = frameSize.width - _EXTLeftRightMargin * 2;
    [groupView setFrame:groupViewFrame];
    [groupView setAutoresizingMask:NSViewWidthSizable];
    [self addSubview:groupView];

    [self _extResetMasksToBounds];
}

- (void)didClickHeader:(EXTDocumentInspectorGroupView *)groupView {
    NSSize previousSize = [groupView frame].size;
    bool collapsed = [groupView collapsed];
    CGFloat newHeight = collapsed ? [[groupView contentView] frame].size.height + _EXTGroupHeaderHeight : 30.0;
    CGFloat yOffset = newHeight - previousSize.height;
    NSUInteger groupViewIndex = [[self subviews] indexOfObject:groupView];
    NSIndexSet *affectedIndexes = [NSIndexSet indexSetWithIndexesInRange:(NSRange){groupViewIndex + 1, [[self subviews] count] - groupViewIndex - 1}];

    [groupView setFrameSize:(NSSize){previousSize.width, newHeight}];
    [groupView setCollapsed:!collapsed];

    [[self subviews] enumerateObjectsAtIndexes:affectedIndexes options:0 usingBlock:^(NSView *subview, NSUInteger idx, BOOL *stop) {
        NSPoint origin = [subview frame].origin;
        origin.y += yOffset;
        [subview setFrameOrigin:origin];
    }];

    [self _extResetMasksToBounds];
}

// Whenever the frame of a group view changes, AppKit decides to change masksToBounds to NO,
// so we re-enable masksToBounds to get rounded rectangles back again. Take that, AppKit!
- (void)_extResetMasksToBounds {
    for (NSView *subview in [self subviews])
        if ([subview isKindOfClass:[EXTDocumentInspectorGroupView class]])
            [[subview layer] setMasksToBounds:YES];
}

- (BOOL)isFlipped {
    return YES;
}

@end


@implementation EXTDocumentInspectorGroupView {
    CALayer *_headerLayer;
}

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

        _headerLayer = [CALayer layer];
        [_headerLayer setBackgroundColor:[[NSColor colorWithCalibratedWhite:0.8 alpha:1.0] CGColor]];
        [_headerLayer setFrame:(CGRect){{0.0, 0.0}, {frame.size.width, 30.0}}];
        [_headerLayer setAutoresizingMask:kCALayerWidthSizable];
        [_headerLayer setBorderColor:[[NSColor lightGrayColor] CGColor]];
        [_headerLayer setBorderWidth:1.0];
        [_headerLayer setShadowOpacity:1.0];
        [_headerLayer setShadowColor:[[NSColor whiteColor] CGColor]];
        [_headerLayer setShadowOffset:(CGSize){0.0, 1.0}];
        [_headerLayer setShadowRadius:0.0];
        [layer addSublayer:_headerLayer];

        CATextLayer *textLayer = [CATextLayer layer];
        [textLayer setString:title];
        [textLayer setAlignmentMode:kCAAlignmentCenter];
        [textLayer setFont:(__bridge CFTypeRef)[NSFont boldSystemFontOfSize:13.0]];
        [textLayer setFontSize:13.0];
        [textLayer setForegroundColor:[[NSColor blackColor] CGColor]];
        [textLayer setFrame:(CGRect){{0.0, 8.0}, {frame.size.width, 15.0}}];
        [textLayer setAutoresizingMask:kCALayerWidthSizable];
        [textLayer setShadowOpacity:1.0];
        [textLayer setShadowColor:[[NSColor whiteColor] CGColor]];
        [textLayer setShadowOffset:(CGSize){0.0, 1.0}];
        [textLayer setShadowRadius:0.0];
        [_headerLayer addSublayer:textLayer];
    }
    return self;
}

// TODO: Check why mouseUp: is sometimes not being received when the view is collapsed
- (void)mouseUp:(NSEvent *)event {
    [super mouseUp:event];
    NSPoint location = [self convertPoint:[event locationInWindow] fromView:nil];
    if (NSPointInRect(location, [_headerLayer frame]))
        [(EXTDocumentInspectorView *)[self superview] didClickHeader:self];
}

- (void)resetCursorRects {
    [self addCursorRect:[_headerLayer frame] cursor:[NSCursor pointingHandCursor]];
}

- (BOOL)isFlipped {
    return YES;
}

@end
