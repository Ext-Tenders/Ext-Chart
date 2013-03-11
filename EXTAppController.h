//
//  EXTDocumentSettingsController.h
//  Ext Chart
//
//  Created by Michael Hopkins on 7/31/11.
//  Copyright 2011 HLProducts. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class EXTsettingPanelController;
@class EXTToolPaletteController;


@interface EXTAppController : NSObject {
	EXTsettingPanelController *panelController;
	EXTToolPaletteController *toolPaletteController;
}
- (IBAction) showSettingsPanel:(id)sender;
- (IBAction) showToolPalette:(id)sender;
@end
