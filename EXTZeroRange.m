//
//  EXTZeroRange.m
//  Ext Chart
//
//  Created by Eric Peterson on 6/20/13.
//  Copyright (c) 2013 Harvard University. All rights reserved.
//

#import "EXTZeroRange.h"
#import "EXTSpectralSequence.h"

@implementation EXTZeroRangePair

@synthesize leftEdge, rightEdge, topEdge, bottomEdge;

-(BOOL) isInRange:(EXTPair*)loc {
    return ((loc.a >= leftEdge) &&
            (loc.a <= rightEdge) &&
            (loc.b >= bottomEdge) &&
            (loc.b <= topEdge));
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super init]) {
        leftEdge = [aDecoder decodeIntForKey:@"leftEdge"];
        rightEdge = [aDecoder decodeIntForKey:@"rightEdge"];
        topEdge = [aDecoder decodeIntForKey:@"topEdge"];
        bottomEdge = [aDecoder decodeIntForKey:@"bottomEdge"];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeInteger:leftEdge forKey:@"leftEdge"];
    [aCoder encodeInteger:rightEdge forKey:@"rightEdge"];
    [aCoder encodeInteger:topEdge forKey:@"topEdge"];
    [aCoder encodeInteger:bottomEdge forKey:@"bottomEdge"];
}

- (id)copyWithZone:(NSZone *)zone {
    EXTZeroRangePair *ret = [[EXTZeroRangePair allocWithZone:zone] init];
    ret.leftEdge = leftEdge;
    ret.rightEdge = rightEdge;
    ret.topEdge = topEdge;
    ret.bottomEdge = bottomEdge;
    
    return ret;
}

@end



@implementation EXTZeroRangeTriple

@synthesize leftEdge, rightEdge, topEdge, bottomEdge, backEdge, frontEdge;

+(EXTZeroRangeTriple*) firstOctant {
    EXTZeroRangeTriple *ret = [EXTZeroRangeTriple new];
    
    ret.leftEdge = ret.bottomEdge = ret.backEdge = 0;
    ret.rightEdge = ret.topEdge = ret.frontEdge = INT_MAX;
    
    return ret;
}

-(BOOL) isInRange:(EXTTriple*)loc {
    return ((loc.a >= leftEdge) &&
            (loc.a <= rightEdge) &&
            (loc.b >= bottomEdge) &&
            (loc.b <= topEdge) &&
            (loc.c >= backEdge) &&
            (loc.c <= frontEdge));
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super init]) {
        leftEdge = [aDecoder decodeIntForKey:@"leftEdge"];
        rightEdge = [aDecoder decodeIntForKey:@"rightEdge"];
        topEdge = [aDecoder decodeIntForKey:@"topEdge"];
        bottomEdge = [aDecoder decodeIntForKey:@"bottomEdge"];
        frontEdge = [aDecoder decodeIntForKey:@"frontEdge"];
        backEdge = [aDecoder decodeIntForKey:@"backEdge"];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeInteger:leftEdge forKey:@"leftEdge"];
    [aCoder encodeInteger:rightEdge forKey:@"rightEdge"];
    [aCoder encodeInteger:topEdge forKey:@"topEdge"];
    [aCoder encodeInteger:bottomEdge forKey:@"bottomEdge"];
    [aCoder encodeInteger:frontEdge forKey:@"frontEdge"];
    [aCoder encodeInteger:backEdge forKey:@"backEdge"];
}

- (id)copyWithZone:(NSZone *)zone {
    EXTZeroRangeTriple *ret = [[EXTZeroRangeTriple allocWithZone:zone] init];
    ret.leftEdge = leftEdge;
    ret.rightEdge = rightEdge;
    ret.topEdge = topEdge;
    ret.bottomEdge = bottomEdge;
    ret.frontEdge = frontEdge;
    ret.bottomEdge = bottomEdge;
    
    return ret;
}

@end



@implementation EXTZeroRangeStrict

@synthesize sSeq;

+(EXTZeroRangeStrict*) newWithSSeq:(EXTSpectralSequence*)sSeq {
    EXTZeroRangeStrict *ret = [EXTZeroRangeStrict new];
    
    ret.sSeq = sSeq;
    
    return ret;
}

-(BOOL) isInRange:(NSObject<EXTLocation> *)loc {
    if ([self.sSeq findTerm:loc])
        return false;
    
    return true;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    return;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    sSeq = nil;
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    EXTZeroRangeStrict *ret = [[EXTZeroRangeStrict allocWithZone:zone] init];
    ret.sSeq = sSeq;
    return ret;
}

@end