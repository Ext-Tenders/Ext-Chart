//
//  EXTDocumentSettingsController.m
//  Ext Chart
//
//  Created by Michael Hopkins on 7/31/11.
//  Copyright 2011 HLProducts. All rights reserved.
//

#import "EXTAppController.h"
#import "EXTsettingPanelController.h"
#import "EXTToolPaletteController.h"


@interface EXTAppController ()
    @property(nonatomic, strong) EXTsettingPanelController *panelController;
    @property(nonatomic, strong) EXTToolPaletteController *toolPaletteController;
@end


@implementation EXTAppController

- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
	[self showToolPalette:self];
}

- (IBAction)showSettingsPanel:(id)sender{
	if (! self.panelController) {
		self.panelController = [EXTsettingPanelController new];
	}

    [self.panelController showWindow:self];
}

- (IBAction) showToolPalette:(id)sender
{
    [EXTToolPaletteController.sharedToolPaletteController showWindow:self];
}
@end
