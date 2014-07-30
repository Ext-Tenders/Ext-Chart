//
//  EXTTermLayer.h
//  Ext Chart
//
//  Created by Bavarious on 04/07/2014.
//  Copyright (c) 2014 Harvard University. All rights reserved.
//

@import QuartzCore;

#import "EXTChartViewInteraction.h"

@class EXTChartViewModelTermCell;

@protocol EXTTermLayer <EXTChartViewInteraction>
@property (nonatomic, strong) EXTChartViewModelTermCell *termCell;

+ (instancetype)termLayerWithTotalRank:(NSInteger)totalRank length:(NSInteger)length;

@optional
- (void)resetContents; // FIXME: rename this to something more meaningful
@end


// FIXME: Move to EXTTermLayerPrivate.h
extern NSString * const EXTTermLayerFontName;

/// Implements state and behaviour that’s common to all EXTTermLayer-conformant classes, and can
/// be used as the forwarding target for the selectors it responds to.
@interface EXTTermLayerSurrogate : NSObject <NSCopying, EXTChartViewInteraction>
@property (nonatomic, strong) EXTChartViewModelTermCell *termCell;
@property (nonatomic, copy) void (^interactionChangedContinuation)(void);
@property (nonatomic, copy) void (^selectionAnimationContinuation)(CAAnimation *animation);

/// Returns a list of selectors that the surrogate should handle instead of an EXTTermLayer-conformant
/// subclass. The selectors are represented as NSString objects.
+ (NSSet *)surrogateSelectors;
@end
