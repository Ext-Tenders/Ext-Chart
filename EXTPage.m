//
//  EXTPage.m
//  Ext Chart
//
//  Created by Michael Hopkins on 7/20/11.
//  Copyright 2011 Harvard. All rights reserved.
//

#import "EXTPage.h"
#import "EXTTerm.h"
#import "EXTdifferential.h"
#import "EXTPair.h"


@implementation EXTPage

@synthesize whichPage;
@synthesize termsArray;
@synthesize differentialsArray;
@synthesize modified;


// I (mjh) changed this.   It looks like initPage is the designated initializer, and so init should call it.  Also, it's supposedly bad form to use setters in the init functions, because of race conditions and possible side effects.   Since the setter is synthesized, it's probably OK here. and ALSO, you're supposed to do [super init] first, and only if works, start assigning ivars.  One reason is so that the instance variables are initialized in the proper order.  

- (id) init {
	return [self initPage:0];
}

- (id) initPage:(int)page {
	if (self = [super init]) {
		whichPage = page;
		modified = NO;
		[self setTermsArray:[NSMutableDictionary dictionaryWithCapacity:100]];
		[self setDifferentialsArray:[NSMutableDictionary dictionaryWithCapacity:100]];
	}
	return self;
}

// this next method should be replace by an implementation of the <NSCopying> protocol

- (id) initFromPage:(EXTPage *)otherPage {
	[self init];
	whichPage = [otherPage whichPage];
	[[self termsArray] setDictionary:[otherPage termsArray]];
	[[self differentialsArray] setDictionary:[otherPage differentialsArray]];
	return self;
}

- (void) dealloc {
	[termsArray release];
	[differentialsArray release];
	[super dealloc];
}

- (id) initWithCoder: (NSCoder*) coder {
	if (self = [super init])
	{
		[self setTermsArray:[coder decodeObjectForKey:@"termsArray"]];
		[self setDifferentialsArray:[coder decodeObjectForKey:@"differentialsArray"]];
	}
	return self;
}

// TODO: this is probably supposed to be an EXTDocument constructor.
- (id) randomInitPage:(int) thePage {
	self = [self initPage:thePage];
	for(int i = 0; i < 6*8; i++)
		for(int j = 0; j < 5*8; j++) {
			int r = arc4random()%10;
			if (r < 1) {
				EXTPair* loc = [EXTPair pairWithA:i AndB:j];
				EXTTerm* term = [EXTTerm newTerm:loc andNames:[[NSMutableArray alloc]initWithObjects:@"",nil]];
				[[self termsArray]setObject:term forKey:loc];
				//NSLog(@"generating term at %@", loc);
			}
		}
	
	for(id key in termsArray) {
		int r = arc4random()%10;
		if (r < 3) {
			EXTdifferential* diff = [EXTdifferential differentialWithPage:[self whichPage] AndStart:key];
			[[self differentialsArray]setObject:diff forKey:key];
			//NSLog(@"generating differential at %@", key);
		}
	}
	
	for(id key in differentialsArray) {
		EXTdifferential* diff = [[self differentialsArray] objectForKey:key];
		EXTPair* end = [diff end];
		if ([[self termsArray]objectForKey:end] == nil) {
            EXTTerm *term= [EXTTerm newTerm:end andNames:[[NSMutableArray alloc]initWithObjects:@"",nil]];
			[[self termsArray]setObject:term forKey:end];
		}
	}

	return self;
}

- (void) encodeWithCoder:(NSCoder*) coder {
	[coder encodeObject: termsArray forKey:@"termsArray"];
	[coder encodeObject: differentialsArray forKey:@"differentialsArray"];
}


- (EXTPage *) computeHomology {
	EXTPage *computation = [[EXTPage alloc] initFromPage:self];
	[computation setWhichPage:whichPage+1];  // should this setting go here?
	[[computation differentialsArray] removeAllObjects];
	for(EXTdifferential *differential in [differentialsArray allValues]) {
		EXTPair *start = [differential start];
		EXTPair *end   = [differential end];
		[[computation termsArray]removeObjectForKey:start];
		[[computation termsArray]removeObjectForKey:end];
	}
	return [computation autorelease];
}

@end
