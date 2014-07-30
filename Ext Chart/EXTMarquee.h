//
//  EXTMarquee.h
//  Ext Chart
//
//  Created by Bavarious on 23/09/2013.
//  Copyright (c) 2013 Harvard University. All rights reserved.
//

@import Foundation;

@interface EXTMarquee : NSObject <NSCoding>

@property (nonatomic, strong) NSString *string;
@property (nonatomic, assign) NSRect frame;
@property (nonatomic, strong) NSImage *image;

@end
