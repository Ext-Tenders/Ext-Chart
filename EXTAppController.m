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


@implementation EXTAppController

- (void) awakeFromNib{
	[self showToolPalette:self];	
//	NSLog(@"toolPaletteController's retain count is %d", [toolPaletteController retainCount]);

}

-(IBAction) showSettingsPanel:(id)sender{
	if (!panelController) {
		panelController = [[EXTsettingPanelController alloc] init];
	}
//		NSLog(@"showing %@", panelController);
		[panelController showWindow:self];
}

// the commented out code in the method below resulted in there being _two_ instances of the toolPaletteController, one, the running one, and the other just there to have an ID.   Of course notifications then failed to work

- (IBAction) showToolPalette:(id)sender{
//	if (!toolPaletteController) {
//		toolPaletteController = [[EXTToolPaletteController alloc] init];
//	}
//	[toolPaletteController showWindow:self];

	[[EXTToolPaletteController toolPaletteControllerId] showWindow:self];
}
@end
