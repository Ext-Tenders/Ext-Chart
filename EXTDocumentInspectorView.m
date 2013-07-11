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

    // If we change the view width, group (sub)views may be resized to accomodate the new width
    // given their autoresizing mask. When that happens, AppKit decides to change masksToBounds
    // to NO, which ends up rendering the group views as straight rectangles. Since this is the
    // only place where the view frame is supposed to change, we re-enable masksToBounds to get
    // rounded rectangles back again. Take that, AppKit!
    for (NSView *subview in [self subviews])
        if ([subview isKindOfClass:[EXTDocumentInspectorGroupView class]])
            [[subview layer] setMasksToBounds:YES];
}

- (BOOL)isFlipped {
    return YES;
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
        [headerLayer setAutoresizingMask:kCALayerWidthSizable];
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
        [textLayer setAutoresizingMask:kCALayerWidthSizable];
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
