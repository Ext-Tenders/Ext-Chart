//
//  EXTPage.h
//  Ext Chart
//
//  Created by Michael Hopkins on 7/20/11.
//  Copyright 2011 Harvard. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class EXTTerm, EXTdifferential, EXTPair;

@interface EXTPage : NSObject <NSCoding> {
	int whichPage;
	NSMutableDictionary *termsArray;
	NSMutableDictionary *differentialsArray;
	NSMutableArray *dirtyDifferentials;
	BOOL modified;
}

@property (assign) int whichPage;
@property (retain) NSMutableDictionary* termsArray;
@property (retain) NSMutableDictionary* differentialsArray;
@property (assign) BOOL modified;


// the designated initializer
- (id) initPage:(int)page;
- (id) randomInitPage:(int)page;
// the next should probably be an implementation of the NSCopying protocol.   I think we want a shallow copy, so that the array of terms stay the same.   In other words, each group lives on many pages.  
- (id) initFromPage:(EXTPage *)otherPage;

- (void) drawFrom:(EXTPair*)lowerLeft To:(EXTPair*)upperRight WithSpacing:(CGFloat)gridSpacing;
- (EXTPage *) computeHomology;

@end
