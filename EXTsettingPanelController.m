//
//  EXTsettingPanelController.m
//  Ext Chart
//
//  Created by Michael Hopkins on 7/31/11.
//  Copyright 2011 HLProducts. All rights reserved.
//

#import "EXTsettingPanelController.h"


@implementation EXTsettingPanelController

@synthesize emphasisGridSpacing;

-(id)init{
	
	if (![super initWithWindowNibName:@"EXTDocSettings"]){
		return nil;
	}
	return self;
}

@end
