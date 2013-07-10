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
