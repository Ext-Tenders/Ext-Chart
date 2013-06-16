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
    #define DLog(format, ...)
#endif

/*! EXTLog() always logs the message */
#define EXTLog(format, ...) NSLog((@"%s L%d" format), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__)
