//
//  EXTGeneratorInspectorViewController.m
//  Ext Chart
//
//  Created by Eric Peterson on 8/1/13.
//  Copyright (c) 2013 Harvard University. All rights reserved.
//

#import "EXTGeneratorInspectorViewController.h"
#import "EXTSpectralSequence.h"

@interface EXTGeneratorInspectorViewController ()

@property (weak,nonatomic) EXTSpectralSequence *sseq;

@end

@implementation EXTGeneratorInspectorViewController

@synthesize sseq;

- (id)init {
    return [super initWithNibName:@"EXTGeneratorInspectorViewController" bundle:nil];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

@end
