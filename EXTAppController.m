//
//  EXTAppController.m
//  Ext Chart
//
//  Created by Michael Hopkins on 7/31/11.
//  Copyright 2011 Harvard University. All rights reserved.
//

#import "EXTAppController.h"
#import "EXTsettingPanelController.h"
#import "EXTDemos.h"
#import "EXTDocument.h"
#import "EXTMaySpectralSequence.h"


typedef enum : NSInteger {
    EXTAppControllerRandomExampleTag  = 0,
    EXTAppControllerS5ExampleTag      = 1,
    EXTAppControllerKUhC2ExampleTag   = 2,
    EXTAppControllerA1MSSExampleTag   = 3,
    EXTAppControllerMayExampleTag     = 4
} EXTAppControllerExampleTag;


@interface EXTAppController ()
    @property(nonatomic, strong) EXTsettingPanelController *panelController;
@end


@implementation EXTAppController

- (IBAction)showSettingsPanel:(id)sender{
	if (! self.panelController) {
		self.panelController = [EXTsettingPanelController new];
	}

    [self.panelController showWindow:self];
}

- (IBAction)newExampleDocument:(id)sender
{
    NSAssert([sender respondsToSelector:@selector(tag)], @"This action only accepts senders that respond to -tag");
    
    EXTSpectralSequence *sseq;

    switch ((EXTAppControllerExampleTag)[sender tag]) {
        case EXTAppControllerRandomExampleTag:
            sseq = [EXTDemos randomDemo];
            break;

        case EXTAppControllerS5ExampleTag:
            sseq = [EXTDemos S5Demo];
            break;
            
        case EXTAppControllerKUhC2ExampleTag:
            sseq = [EXTDemos KUhC2Demo];
            break;
            
        case EXTAppControllerA1MSSExampleTag:
            sseq = [EXTDemos A1MSSDemo];
            break;
            
        case EXTAppControllerMayExampleTag:
            sseq = [EXTMaySpectralSequence fillToWidth:6];
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
