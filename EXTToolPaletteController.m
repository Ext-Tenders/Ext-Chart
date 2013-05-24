//
//  EXTToolPalletteController.m
//  Ext Chart
//
//  Created by Michael Hopkins on 8/23/11.
//  Copyright 2011 HLProducts. All rights reserved.
//

#import "EXTToolPaletteController.h"
#import "EXTTerm.h"
#import "EXTDifferential.h"


@interface EXTToolPaletteController ()
    @property(nonatomic, weak) IBOutlet NSMatrix *toolPallette;

    - (IBAction)toolSelectionDidChange:(id)sender;
@end


@implementation EXTToolPaletteController

static EXTToolPaletteController *_sharedToolPaletteController = nil; // singleton

+ (instancetype)sharedToolPaletteController
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedToolPaletteController = [[super allocWithZone:NULL] init];
    });

    return _sharedToolPaletteController;
}

+ (id)allocWithZone:(NSZone *)zone
{
    return self.sharedToolPaletteController;
}

- (id)init
{
	self = [super initWithWindowNibName:@"EXTToolPalette"];
    return self;
}

- (id)copyWithZone:(NSZone *)zone
{
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
	
//    NSArray *cells = [toolPallette cells];
//    NSUInteger i, c = [cells count];
//    for (i=0; i<c; i++) {
//        [[cells objectAtIndex:i] setRefusesFirstResponder:YES];
//    }

	[(NSPanel *)[self window] setBecomesKeyOnlyIfNeeded:YES];
}

- (IBAction)toolSelectionDidChange:(id)sender
{
	// post a notification that the tool did change
	
	[[NSNotificationCenter defaultCenter] postNotificationName:@"EXTtoolSelectionChanged" object:self];
}


- (Class)currentToolClass
{
	enum EXTToolType toolType = (enum EXTToolType)self.toolPallette.selectedRow;
	Class theClass = nil;
	switch (toolType) {
		case EXTArrowToolRow:
            // TODO: this can't be right.
			theClass = [EXTDifferential class];
			break;
		case EXTGeneratorToolRow:
			theClass = [EXTTerm class];
			break;
		case EXTDifferentialToolRow:
			theClass = [EXTDifferential class];
			break;
	}
	return theClass;
}

@end
