//
//  EXTLeibnizWindowController.h
//  Ext Chart
//
//  Created by Eric Peterson on 8/27/13.
//  Copyright (c) 2013 Harvard University. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "EXTSpectralSequence.h"

@interface EXTLeibnizWindowController : NSWindowController

@property (weak,nonatomic) EXTSpectralSequence *sseq;

-(void)showWindow:(id)sender;
-(void)mouseDownAtGridLocation:(EXTIntPoint)gridLocation;

@end
