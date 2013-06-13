//
//  EXTDocumentSettingsController.m
//  Ext Chart
//
//  Created by Michael Hopkins on 7/31/11.
//  Copyright 2011 Harvard University. All rights reserved.
//

#import "EXTAppController.h"
#import "EXTsettingPanelController.h"
#import "EXTToolPaletteController.h"
#import "EXTSpectralSequence.h"
#import "EXTDocument.h"


typedef enum : NSInteger {
    EXTAppControllerWorkingExampleTag = 1,
    EXTAppControllerRandomExampleTag  = 2,
    EXTAppControllerS5ExampleTag      = 3,
} EXTAppControllerExampleTag;


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

- (IBAction)showToolPalette:(id)sender
{
    [EXTToolPaletteController.sharedToolPaletteController showWindow:self];
}

- (IBAction)newExampleDocument:(id)sender
{
    NSAssert([sender respondsToSelector:@selector(tag)], @"This action only accepts senders that respond to -tag");
    
    EXTSpectralSequence *sseq;

    switch ((EXTAppControllerExampleTag)[sender tag]) {
        case EXTAppControllerWorkingExampleTag:
            sseq = [EXTSpectralSequence workingDemo];
            break;

        case EXTAppControllerRandomExampleTag:
            sseq = [EXTSpectralSequence randomDemo];
            break;

        case EXTAppControllerS5ExampleTag:
            sseq = [EXTSpectralSequence S5Demo];
            break;

        default:
            sseq = nil;
            break;
    }

    if (! sseq)
        return;

    EXTDocument *newDocument = [[NSDocumentController sharedDocumentController] openUntitledDocumentAndDisplay:YES error:NULL];
    [newDocument setSseq:sseq];
}

@end
