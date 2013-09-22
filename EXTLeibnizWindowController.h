//
//  EXTLeibnizWindowController.h
//  Ext Chart
//
//  Created by Eric Peterson on 8/27/13.
//  Copyright (c) 2013 Harvard University. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "EXTSpectralSequence.h"
#import "EXTDocumentWindowController.h"

@interface EXTLeibnizWindowController : NSWindowController

@property (nonatomic, weak) EXTDocumentWindowController *documentWindowController;

-(void)showWindow:(id)sender;
-(void)mouseDownAtGridLocation:(EXTIntPoint)gridLocation;

@end
