//
//  EXTToolPalletteController.h
//  Ext Chart
//
//  Created by Michael Hopkins on 8/23/11.
//  Copyright 2011 Harvard University. All rights reserved.
//

#import <Cocoa/Cocoa.h>

enum EXTToolType {
    EXTArrowToolRow = 0,
    EXTGeneratorToolRow,
    EXTDifferentialToolRow,
};


@interface EXTToolPaletteController : NSWindowController
    + (instancetype)sharedToolPaletteController;
    - (Class)currentToolClass;
@end
