//
//  EXTZeroRange.h
//  Ext Chart
//
//  Created by Eric Peterson on 6/20/13.
//  Copyright (c) 2013 Harvard University. All rights reserved.
//
//  We're very careful to avoid overcomputing differentials by using partial
//  definitions of objects.  Sometimes, though, we know that a region is filled
//  with zero groups, and that any differential or multiplication passing
//  through it will turn out to be null, and so differentials *can* propagate,
//  provided that they propagate as zero.  These classes track such regions.
//

#import <Foundation/Foundation.h>
#import "EXTLocation.h"
#import "EXTPair.h"
#import "EXTTriple.h"


@protocol EXTZeroRange <NSObject, NSCopying, NSCoding>

-(BOOL) isInRange:(EXTLocation*)loc;

@end

typedef NSObject<EXTZeroRange> EXTZeroRange;


#pragma mark --- some specific implementations ---


@interface EXTZeroRangePair : NSObject <EXTZeroRange>

@property int leftEdge, rightEdge, topEdge, bottomEdge;

-(BOOL) isInRange:(EXTPair*)loc;

@end


@interface EXTZeroRangeTriple : NSObject <EXTZeroRange>

@property int leftEdge, rightEdge, topEdge, bottomEdge, backEdge, frontEdge;

-(BOOL) isInRange:(EXTTriple*)loc;

@end