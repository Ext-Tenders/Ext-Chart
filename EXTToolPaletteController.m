//
//  EXTToolPalletteController.m
//  Ext Chart
//
//  Created by Michael Hopkins on 8/23/11.
//  Copyright 2011 HLProducts. All rights reserved.
//

#import "EXTToolPaletteController.h"
#import "EXTTerm.h"
#import "EXTdifferential.h"


@implementation EXTToolPaletteController

// there's a subtlety in the next class method.   It must be called instead of alloc/init, to instantiate the unique instance.   This call is made in the app controller.   The other option is to store the id as an ivar in the appController, and get it with a getter method.   Not sure which makes more sense.   Objects would need to know the id of the unique appController.   If it were a delegate, they could get that from the app itself.   But I don't think a delegate can have any instance variables.   Not sure...

+ (id)toolPaletteControllerId{
	// returns the id of the unique	EXTToolPaletteController instance.  Got this from Sketch, too
	static EXTToolPaletteController *toolPaletteControllerInstance = nil;
	// a given function or method will only initialize a static variable once.   Putting it in the method, rather than above the @interface line limits the scope of the variable to the method.  Otherwise its scope is the whole class, hence it would be accessible from every instance (which, in this case is unique, so it probably doesn't make much real difference).  	
	
    if (!toolPaletteControllerInstance) {
		//        sharedToolPaletteController = [[SKTToolPaletteController allocWithZone:NULL] init];
		toolPaletteControllerInstance = [[EXTToolPaletteController allocWithZone:NULL] init];
    }
    return toolPaletteControllerInstance;
}

-(id)init{
	
	if (![super initWithWindowNibName:@"EXTToolPalette"]){
		return nil;
	}
	return self;
}

- (void)windowDidLoad {
//    NSArray *cells = [toolPallette cells];
//    NSUInteger i, c = [cells count];
    
    [super windowDidLoad];
	
//    for (i=0; i<c; i++) {
//        [[cells objectAtIndex:i] setRefusesFirstResponder:YES];
//    }
	[(NSPanel *)[self window] setBecomesKeyOnlyIfNeeded:YES];	
}

- (IBAction) toolSelectionDidChange:(id)sender{	
	// post a notification that the tool did change
	
	[[NSNotificationCenter defaultCenter] postNotificationName:@"EXTtoolSelectionChanged" object:self];
	
}


- (Class)currentToolClass{
	enum EXTToolType toolType = (enum EXTToolType)[toolPallette selectedRow];
	Class theClass = nil;
	switch (toolType) {
		case EXTArrowToolRow:
            // TODO: this can't be right.
			theClass = [EXTdifferential class];
			break;
		case EXTGeneratorToolRow:
			theClass = [EXTTerm class];
			break;
		case EXTDifferentialToolRow:
			theClass = [EXTdifferential class];
			break;
	}
	return theClass;
}

@end
