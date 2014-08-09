//
//  EXTDocument.h
//  Ext Chart
//
//  Created by Michael Hopkins on 7/20/11.
//  Copyright 2011 Harvard University. All rights reserved.
//

@import Cocoa;

#import "EXTLocation.h"

@class EXTDocumentWindowController;
@class EXTSpectralSequence;
@class EXTDifferential;
@class EXTTerm;


@interface EXTDocument : NSDocument

@property(nonatomic, strong) EXTSpectralSequence *sseq;

/// an array of EXTMarquee objects
@property(nonatomic, strong) NSMutableArray *marquees;

/// array of dictionaries: {"style", "enabled", "location", "vector"}
@property(nonatomic, strong) NSMutableArray *multiplicationAnnotations;

// User interface configuration
// TODO: we should use KVO to track incoming modifications to these and trigger
// -updateChangeCount: messages when changes happen.
@property(nonatomic, strong) NSColor *gridColor;
@property(nonatomic, strong) NSColor *gridEmphasisColor;
@property(nonatomic, strong) NSColor *axisColor;
@property(nonatomic, strong) NSColor *highlightColor;
@property(nonatomic, strong) NSColor *selectionColor;
@property(nonatomic, assign) NSInteger gridSpacing;
@property(nonatomic, assign) NSInteger gridEmphasisSpacing;
@property(nonatomic, assign) EXTIntRect artBoardGridFrame;
@property(nonatomic, readonly) EXTDocumentWindowController *mainWindowController;

/// copies the meat out of diffl into the relevant preexisting differential in the model.
-(void) updateDifferential:(EXTDifferential*)diffl;
/// copies the meat out of term into the relevant preexisting term in the model.
-(void) updateTerm:(EXTTerm*)term;

@end
