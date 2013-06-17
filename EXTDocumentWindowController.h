//
//  EXTDocumentWindowController.h
//  Ext Chart
//
//  Created by Bavarious on 31/05/2013.
//  Copyright (c) 2013 Harvard University. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "EXTView.h"

@interface EXTDocumentWindowController : NSWindowController <EXTViewDelegate>
- (void)drawPagesUpTo:(NSUInteger)pageNumber;
- (void)drawPageNumber:(NSUInteger)pageNumber ll:(NSPoint)lowerLeftCoord ur:(NSPoint)upperRightCoord withSpacing:(CGFloat)gridSpacing;
@end
