//
//  EXTChartClipView.m
//  Ext Chart
//
//  Created by Bavarious on 30/06/2014.
//  Copyright (c) 2014 Harvard University. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "EXTChartClipView.h"

// This is based on http://github.com/github/Rebel RBLClipView

@implementation EXTChartClipView

- (instancetype)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.layer = [CAScrollLayer layer];
        self.wantsLayer = YES;

        self.layerContentsRedrawPolicy = NSViewLayerContentsRedrawNever;

        self.drawsBackground = YES;
        self.backgroundColor = [NSColor windowBackgroundColor];

        self.layer.opaque = self.drawsBackground;
        self.layer.backgroundColor = [self.backgroundColor CGColor];
        self.layer.drawsAsynchronously = YES;
        // Can this layer be drawn asynchronously?
    }
    return self;
}

- (BOOL)isOpaque
{
    return YES;
}

// If we disable responsive scrolling, we don't see stuttered scrolling. Yay?
+ (BOOL)isCompatibleWithResponsiveScrolling
{
    return NO;
}

@end
