//
//  EXTUtilities.h
//  Ext Chart
//
//  Created by Bavarious on 15/06/2013.
//  Copyright (c) 2013 Harvard University. All rights reserved.
//

#import <Foundation/Foundation.h>


/*! DLog() only logs the message in debug builds */
#ifdef DEBUG
    #define DLog(format, ...) NSLog((@"%s L%d: " format), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__)
#else
    #define DLog(format, ...) do {} while (false)
#endif

/*! EXTLog() always logs the message */
#define EXTLog(format, ...) NSLog((@"%s L%d" format), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__)


/*! EXTEpsilonEqual() returns true iff its two floating-point arguments differ by at most epsilon, where epsilon depends on the argument’s data types */
static bool __attribute__((__overloadable__, __always_inline__)) EXTEpsilonEqual(float x, float y) {return fabsf(x - y) <= FLT_EPSILON;}
static bool __attribute__((__overloadable__, __always_inline__)) EXTEpsilonEqual(double x, double y) {return fabs(x - y) <= DBL_EPSILON;}
static bool __attribute__((__overloadable__, __always_inline__)) EXTEpsilonEqual(long double x, long double y) {return fabsl(x - y) <= LDBL_EPSILON;}

/*! Boolean to string conversions */
static NSString * __attribute__((__always_inline__)) EXTBoolToString(bool x) { return x ? @"true" : @"false"; }
static const char * __attribute__((__always_inline__)) EXTBoolToCString(bool x) { return x ? "true" : "false"; }


// From https://www.mikeash.com/pyblog/friday-qa-2010-06-18-implementing-equality-and-hashing.html
#define NSUINT_BIT (CHAR_BIT * sizeof(NSUInteger))
#define NSUINTROTATE(val, howmuch) ((((NSUInteger)val) << howmuch) | (((NSUInteger)val) >> (NSUINT_BIT - howmuch)))


/*! Integer coordinate space */
typedef struct {
    NSInteger x;
    NSInteger y;
} EXTIntPoint;

typedef struct {
    NSInteger width;
    NSInteger height;
} EXTIntSize;

typedef struct {
    EXTIntPoint origin;
    EXTIntSize size;
} EXTIntRect;

static inline bool EXTEqualIntPoints(EXTIntPoint point1, EXTIntPoint point2) {
    return point1.x == point2.x && point1.y == point2.y;
}

static inline bool EXTEqualIntSizes(EXTIntSize size1, EXTIntSize size2) {
    return size1.width == size2.width && size1.height == size2.height;
}

static inline EXTIntPoint EXTIntPointFromNSPoint(NSPoint point) {
    return (EXTIntPoint){(NSInteger)point.x, (NSInteger)point.y};
}

static inline NSPoint NSPointFromEXTIntPoint(EXTIntPoint point) {
    return NSMakePoint(point.x, point.y);
}

static inline NSString *EXTStringFromIntPoint(EXTIntPoint point) {
    return [NSString stringWithFormat:@"(%ld, %ld)", point.x, point.y];
}

static inline NSString *EXTStringFromIntSize(EXTIntSize size) {
    return [NSString stringWithFormat:@"(%ld, %ld)", size.width, size.height];
}

static inline NSString *EXTStringFromIntRect(EXTIntRect rect) {
    return [NSString stringWithFormat:@"(%@, %@)", EXTStringFromIntPoint(rect.origin), EXTStringFromIntSize(rect.size)];
}


/*! This function assumes the origin is located at the bottom left corner. Points lying on the bottom or left edges
 are considered part of the rectangle; points lying on the upper or right edges are _not_ part of the rectangle. */
static inline bool EXTIntPointInRect(EXTIntPoint point, EXTIntRect rect) {
    return (point.x >= rect.origin.x &&
            point.y >= rect.origin.y &&
            point.x < rect.origin.x + rect.size.width &&
            point.y < rect.origin.y + rect.size.height);
}

static inline EXTIntPoint EXTIntUpperRightPointOfRect(EXTIntRect rect) {
    return (EXTIntPoint){
        .x = rect.origin.x + rect.size.width,
        .y = rect.origin.y + rect.size.height
    };
}

static inline bool EXTIntersectsIntRects(EXTIntRect rect1, EXTIntRect rect2) {
    return EXTIntPointInRect(rect1.origin, rect2) || EXTIntPointInRect(rect2.origin, rect1);
}
