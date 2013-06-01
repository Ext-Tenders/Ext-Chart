//
//  EXTsettingPanelController.m
//  Ext Chart
//
//  Created by Michael Hopkins on 7/31/11.
//  Copyright 2011 Harvard University. All rights reserved.
//

#import "EXTsettingPanelController.h"


@interface EXTsettingPanelController ()
    @property(nonatomic,weak) IBOutlet NSColorWell *gridLineColorWell;
    @property(nonatomic,weak) IBOutlet NSColorWell *emphasisLineColorWell;
    @property(nonatomic,weak) IBOutlet NSTextField *gridSpacingSelection;
    @property(nonatomic,weak) IBOutlet NSTextField *emphasisLineSelection;

//-(IBAction) setGridLineColor:(id)sender;
//-(IBAction) setGridEmphasisColor:(id)sender;
//-(IBAction) setGridSpacing:(id)sender;
//-(IBAction) setEmphasisSpacing:(id)sender;
//
@end


@implementation EXTsettingPanelController

- (id)init
{
	self = [super initWithWindowNibName:@"EXTDocSettings"];
    return self;
}

@end
