//
//  EXTToolPalletteController.h
//  Ext Chart
//
//  Created by Michael Hopkins on 8/23/11.
//  Copyright 2011 HLProducts. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class EXTTerm, EXTDifferential;

// If I understand the scoping correctly, this declaration of an enumerated data type makes these available in any other method that imports this header file.

enum EXTToolType {
    EXTArrowToolRow = 0,
    EXTGeneratorToolRow,
    EXTDifferentialToolRow,
};


@interface EXTToolPaletteController : NSWindowController {
	IBOutlet NSMatrix *toolPallette;

}

+ (id) toolPaletteControllerId;
- (IBAction) toolSelectionDidChange:(id)sender;
- (Class)currentToolClass;

@end
