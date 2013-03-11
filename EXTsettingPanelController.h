//
//  EXTsettingPanelController.h
//  Ext Chart
//
//  Created by Michael Hopkins on 7/31/11.
//  Copyright 2011 HLProducts. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface EXTsettingPanelController : NSWindowController {
	IBOutlet NSColorWell *gridLineColorWell;
	IBOutlet NSColorWell *emphasisLineColorWell;
	IBOutlet NSTextField *gridSpacingSelection;
	IBOutlet NSTextField *emphasisLineSelection;
	
	NSUInteger emphasisGridSpacing;
}

@property(assign) NSUInteger emphasisGridSpacing;

//-(IBAction) setGridLineColor:(id)sender;
//-(IBAction) setGridEmphasisColor:(id)sender;
//-(IBAction) setGridSpacing:(id)sender;
//-(IBAction) setEmphasisSpacing:(id)sender;
//
@end
