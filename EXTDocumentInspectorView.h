//
//  EXTDocumentInspectorView.h
//  Ext Chart
//
//  Created by Bavarious on 09/07/2013.
//  Copyright (c) 2013 Harvard University. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface EXTDocumentInspectorView : NSView
    - (void)addSubview:(NSView *)subview withTitle:(NSString *)title collapsed:(bool)collapsed centered:(bool)centered;
    + (NSColor *)backgroundColor;
@end
