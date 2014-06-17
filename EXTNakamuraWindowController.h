//
//  EXTNakamuraWindowController.h
//  Ext Chart
//
//  Created by Eric Peterson on 6/16/14.
//  Copyright (c) 2014 Harvard University. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "EXTDocumentWindowController.h"

@interface EXTNakamuraWindowController : NSWindowController

@property (nonatomic, weak) EXTDocumentWindowController *documentWindowController;

-(void)mouseDownAtGridLocation:(EXTIntPoint)gridLocation;

@end
