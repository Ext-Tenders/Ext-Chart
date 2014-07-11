//
//  NSValue+EXTIntPoint.h
//  Ext Chart
//
//  Created by Bavarious on 11/07/2014.
//  Copyright (c) 2014 Harvard University. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSValue (EXTIntPoint)
+ (instancetype)extValueWithIntPoint:(EXTIntPoint)point;
- (EXTIntPoint)extIntPointValue;
@end
