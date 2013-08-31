//
//  EXTToolboxView.h
//  Ext Chart
//
//  Created by Bavarious on 31/08/2013.
//  Copyright (c) 2013 Harvard University. All rights reserved.
//

#import <Cocoa/Cocoa.h>


typedef enum : NSInteger {
    _EXTGeneratorToolTag = 1,
    _EXTDifferentialToolTag = 2,
    _EXTMultiplicativeStructureToolTag = 3,
    _EXTArtboardToolTag = 4,
    _EXTMarqueeToolTag = 5,
    _EXTToolTagCount
} EXTToolboxTag;


@interface EXTToolboxView : NSMatrix
@end
