//
//  EXTTermLayer.m
//  Ext Chart
//
//  Created by Bavarious on 04/07/2014.
//  Copyright (c) 2014 Harvard University. All rights reserved.
//

#import "EXTTermLayer.h"

NSString * const EXTTermLayerFontName = @"Palatino-Roman";

@implementation EXTTermLayerSurrogate

@synthesize highlighted = _highlighted;
@synthesize highlightColor = _highlightColor;
@synthesize selectedObject = _selectedObject;
@synthesize selectionColor = _selectionColor;

@synthesize termCell = _termCell;

+ (NSSet *)surrogateSelectors {
    static NSSet *_selectors;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSArray *selectors = @[
                               NSStringFromSelector(@selector(isHighlighted)),
                               NSStringFromSelector(@selector(setHighlighted:)),
                               NSStringFromSelector(@selector(highlightColor)),
                               NSStringFromSelector(@selector(setHighlightColor:)),
                               NSStringFromSelector(@selector(isSelectedObject)),
                               NSStringFromSelector(@selector(setSelectedObject:)),
                               NSStringFromSelector(@selector(selectionColor)),
                               NSStringFromSelector(@selector(setSelectionColor:)),
                               NSStringFromSelector(@selector(termCell)),
                               NSStringFromSelector(@selector(setTermCell:)),
                               ];

        _selectors = [NSSet setWithArray:selectors];
    });

    return _selectors;
}

#pragma mark - Lifecycle

- (void)dealloc {
    CGColorRelease(_highlightColor);
    CGColorRelease(_selectionColor);
}

#pragma mark - NSCopying

- (instancetype)copyWithZone:(NSZone *)zone {
    EXTTermLayerSurrogate *copy = [[self class] new];
    copy.termCell = self.termCell;
    copy.highlighted = self.highlighted;
    copy.highlightColor = self.highlightColor;
    copy.selectedObject = self.selectedObject;
    copy.selectionColor = self.selectionColor;
    return copy;
}

#pragma mark - Properties

- (void)setHighlightColor:(CGColorRef)highlightColor
{
    if (_highlightColor != highlightColor) {
        CGColorRelease(_highlightColor);
        _highlightColor = CGColorCreateCopy(highlightColor);
        if (self.interactionChangedContinuation) self.interactionChangedContinuation();
    }
}

- (void)setSelectionColor:(CGColorRef)selectionColor
{
    if (_selectionColor != selectionColor) {
        CGColorRelease(_selectionColor);
        _selectionColor = CGColorCreateCopy(selectionColor);
        if (self.interactionChangedContinuation) self.interactionChangedContinuation();
    }
}

- (void)setHighlighted:(bool)highlighted
{
    if (highlighted != _highlighted) {
        _highlighted = highlighted;
        if (self.interactionChangedContinuation) self.interactionChangedContinuation();
    }
}

- (void)setSelectedObject:(bool)selectedObject
{
    if (selectedObject != _selectedObject) {
        _selectedObject = selectedObject;
        if (self.interactionChangedContinuation) {
            self.interactionChangedContinuation();
        }
    }

    if (selectedObject && self.selectionAnimationContinuation) {
        CAKeyframeAnimation *animation = CAKeyframeAnimation.animation;
        animation.keyPath = @"transform";
        animation.values = @[[NSValue valueWithCATransform3D:CATransform3DIdentity],
                             [NSValue valueWithCATransform3D:CATransform3DMakeScale(0.75, 0.75, 1.0)],
                             [NSValue valueWithCATransform3D:CATransform3DMakeScale(1.5, 1.5, 1.0)],
                             [NSValue valueWithCATransform3D:CATransform3DIdentity]];
        animation.keyTimes = @[@0.0, @0.3, @0.8, @1.0];
        animation.duration = 0.2;
        animation.removedOnCompletion = YES;

        self.selectionAnimationContinuation(animation);
    }
}

@end
