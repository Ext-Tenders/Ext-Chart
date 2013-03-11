//
//  EXTScrollView.m
//  Ext Chart
//
//  Created by Michael Hopkins on 7/24/11.
//  Copyright 2011 HLProducts. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "EXTScrollView.h"



/* For genstrings:
 NSLocalizedStringFromTable(@"10%", @"ZoomValues", @"Zoom popup entry")
 NSLocalizedStringFromTable(@"25%", @"ZoomValues", @"Zoom popup entry")
 NSLocalizedStringFromTable(@"50%", @"ZoomValues", @"Zoom popup entry")
 NSLocalizedStringFromTable(@"75%", @"ZoomValues", @"Zoom popup entry")
 NSLocalizedStringFromTable(@"100%", @"ZoomValues", @"Zoom popup entry")
 NSLocalizedStringFromTable(@"125%", @"ZoomValues", @"Zoom popup entry")
 NSLocalizedStringFromTable(@"150%", @"ZoomValues", @"Zoom popup entry")
 NSLocalizedStringFromTable(@"200%", @"ZoomValues", @"Zoom popup entry")
 NSLocalizedStringFromTable(@"400%", @"ZoomValues", @"Zoom popup entry")
 NSLocalizedStringFromTable(@"800%", @"ZoomValues", @"Zoom popup entry")
 NSLocalizedStringFromTable(@"1600%", @"ZoomValues", @"Zoom popup entry")
 */   
// static NSString *_NSDefaultScaleMenuLabels[] = {/* @"Set...", */ @"10%", @"25%", @"50%", @"75%", @"100%", @"125%", @"150%", @"200%", @"400%", @"800%", @"1600%", @"3200%"};
//
//static float _NSDefaultScaleMenuFactors[] = {/* 0.0, */ 0.1, 0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 2.0, 4.0, 8.0, 16.0, 32.0};
//static unsigned _NSDefaultScaleMenuSelectedItemIndex = 4;
//static float _NSScaleMenuFontSize = 10.0;


@implementation EXTScrollView


// mjh:  the initWithFrame function is not being called.   I tried logging it.
- (id)initWithFrame:(NSRect)rect {
    if ((self = [super initWithFrame:rect])) {
//        scaleFactor = 1.0;
    }
    return self;
}

-(void)awakeFromNib{
//	NSLog(@"awake from nib called");
	[[self documentView] scrollPoint:NSMakePoint(0, 0)];
	[[self window] makeFirstResponder:self];

//	NSView *docView = [self documentView];
//	NSLog(@"the documentView's bounds rectangle has origin (%f, %f), width %f and height %f", [docView bounds].origin.x, [docView bounds].origin.y, [docView bounds].size.width, [docView bounds].size.height);
//	NSLog(@"the documentView's frame rectangle has origin (%f, %f), width %f and height %f", [docView frame].origin.x, [docView frame].origin.y, [docView frame].size.width, [docView frame].size.height);	
}


/* -(void)makeScalingComboBox{
	if (_scalingComboBox == nil) {
		NSArray *defaultScaleMenuArray = [NSArray arrayWithObjects:@"10%", @"25%", @"50%", @"75%", @"100%", @"125%", @"150%", @"200%", @"400%", @"800%", @"1600%", @"3200%", nil];
		
		_scalingComboBox = [[NSComboBox alloc] initWithFrame:NSZeroRect];
		NSComboBoxCell *scalingComboBoxCell = [_scalingComboBox cell];
		[scalingComboBoxCell setBezelStyle:NSRegularSquareBezelStyle];
		[scalingComboBoxCell setButtonBordered:YES];
		[scalingComboBoxCell addItemsWithObjectValues:defaultScaleMenuArray];
		[scalingComboBoxCell selectItemAtIndex:3];
		[_scalingComboBox setHasVerticalScroller:YES];
		[_scalingComboBox setFont:[NSFont systemFontOfSize:[NSFont smallSystemFontSize]]];
		[_scalingComboBox setIntercellSpacing:NSMakeSize(5.0, 0.0)];
		[self addSubview:_scalingComboBox];
		[_scalingComboBox release];
	}
}

//why doesn't the next method have to appear in the header file?

- (void)makeScalePopUpButton {
    if (_scalePopUpButton == nil) {
        unsigned cnt, numberOfDefaultItems = (sizeof(_NSDefaultScaleMenuLabels) / sizeof(NSString *));
        id curItem;
		
        // create it
        _scalePopUpButton = [[NSPopUpButton allocWithZone:[self zone]] initWithFrame:NSMakeRect(0.0, 0.0, 1.0, 1.0) pullsDown:NO];
        [(NSPopUpButtonCell *)[_scalePopUpButton cell] setBezelStyle:NSShadowlessSquareBezelStyle];
        [[_scalePopUpButton cell] setArrowPosition:NSPopUpArrowAtBottom];
        
        // fill it
        for (cnt = 0; cnt < numberOfDefaultItems; cnt++) {
            [_scalePopUpButton addItemWithTitle:NSLocalizedStringFromTable(_NSDefaultScaleMenuLabels[cnt], @"ZoomValues", nil)];
            curItem = [_scalePopUpButton itemAtIndex:cnt];
            if (_NSDefaultScaleMenuFactors[cnt] != 0.0) {
                [curItem setRepresentedObject:[NSNumber numberWithFloat:_NSDefaultScaleMenuFactors[cnt]]];
            }
        }
        [_scalePopUpButton selectItemAtIndex:_NSDefaultScaleMenuSelectedItemIndex];
		
        // hook it up
        [_scalePopUpButton setTarget:self];
        [_scalePopUpButton setAction:@selector(scalePopUpAction:)];
		
        // set a suitable font
        [_scalePopUpButton setFont:[NSFont toolTipsFontOfSize:_NSScaleMenuFontSize]];
		
        // Make sure the popup is big enough to fit the cells.
        [_scalePopUpButton sizeToFit];
		
		// don't let it become first responder
		[_scalePopUpButton setRefusesFirstResponder:YES];
		
        // put it in the scrollview
        [self addSubview:_scalePopUpButton];
        [_scalePopUpButton release];
    }
}

- (void)tile {
    // Let the superclass do most of the work.
    [super tile];
	
    if (![self hasHorizontalScroller]) {
        if (_scalePopUpButton) [_scalePopUpButton removeFromSuperview];
        _scalePopUpButton = nil;
    } else {
		NSScroller *horizScroller;
		NSRect horizScrollerFrame, buttonFrame;
		
        if (!_scalePopUpButton) [self makeScalePopUpButton];
		//		if (!_scalingComboBox) [self makeScalingComboBox];
		
        horizScroller = [self horizontalScroller];
        horizScrollerFrame = [horizScroller frame];
        buttonFrame = [_scalePopUpButton frame];
		//		comboBoxFrame = [_scalingComboBox frame];
		
		
        // Now we'll just adjust the horizontal scroller size and set the button size and location.
		
		//       horizScrollerFrame.size.width = horizScrollerFrame.size.width - buttonFrame.size.width;
		//        [horizScroller setFrameSize:horizScrollerFrame.size];
		
        
//		[self setHasHorizontalRuler:YES];
//		[self setHasVerticalRuler:YES];
//		[self setRulersVisible:YES];
		
		//		comboBoxFrame.origin.x = horizScrollerFrame.origin.x;
		//		comboBoxFrame.origin.y = horizScrollerFrame.origin.y-10;
		//        comboBoxFrame.size.height = 26;
		//		comboBoxFrame.size.width = buttonFrame.size.width;
		//		
		//		buttonFrame.origin.x = comboBoxFrame.origin.x+comboBoxFrame.size.width;
		//		buttonFrame.origin.y = horizScrollerFrame.origin.y-1;
		//		buttonFrame.size.height = horizScrollerFrame.size.height+1;
		
		
		buttonFrame.origin.x = horizScrollerFrame.origin.x;
		buttonFrame.origin.y = horizScrollerFrame.origin.y;
		buttonFrame.size.height = horizScrollerFrame.size.height;
		
		
		
        [_scalePopUpButton setFrame:buttonFrame];
		//		[_scalingComboBox setFrame:comboBoxFrame];
		
		
		horizScrollerFrame.size.width -= buttonFrame.size.width;
		horizScrollerFrame.origin.x += buttonFrame.size.width;
        [horizScroller setFrame:horizScrollerFrame];
		
    }
}

- (void)drawRect:(NSRect)rect {
    NSRect verticalLineRect;
    
    [super drawRect:rect];
	
    if ([_scalePopUpButton superview]) {
        verticalLineRect = [_scalePopUpButton frame];
        verticalLineRect.origin.x -= 1.0;
        verticalLineRect.size.width = 1.0;
        if (NSIntersectsRect(rect, verticalLineRect)) {
            [[NSColor blackColor] set];
            NSRectFill(verticalLineRect);
        }
    }
}

- (void)scalePopUpAction:(id)sender {
    NSNumber *selectedFactorObject = [[sender selectedCell] representedObject];
    
    if (selectedFactorObject == nil) {
        NSLog(@"Scale popup action: setting arbitrary zoom factors is not yet supported.");
        return;
    } else {
        [self setScaleFactor:[selectedFactorObject floatValue] adjustPopup:NO];
    }
}

- (float)scaleFactor {
    return scaleFactor;
}

- (void)setScaleFactor:(float)newScaleFactor adjustPopup:(BOOL)flag {
    if (scaleFactor != newScaleFactor) {
		NSSize curDocFrameSize;
		NSRect currentDocBoundsRect;
		CGFloat newOriginX, newOriginY, newWidth, newHeight;
		
		NSView *clipView = [[self documentView] superview];
		
        if (flag) {	// Coming from elsewhere, first validate it
            unsigned cnt = 0, numberOfDefaultItems = (sizeof(_NSDefaultScaleMenuFactors) / sizeof(float));
			
            // We only work with some preset zoom values, so choose one of the appropriate values (Fudge a little for floating point == to work)
            while (cnt < numberOfDefaultItems && newScaleFactor * .99 > _NSDefaultScaleMenuFactors[cnt]) cnt++;
            if (cnt == numberOfDefaultItems) cnt--;
            [_scalePopUpButton selectItemAtIndex:cnt];
            scaleFactor = _NSDefaultScaleMenuFactors[cnt];
        } else {
            scaleFactor = newScaleFactor;
        }
		
		// Get the frame.  The frame must stay the same.
		curDocFrameSize = [clipView frame].size;
		
		// The new bounds will be frame divided by scale factor
		newWidth = curDocFrameSize.width / scaleFactor;
		newHeight = curDocFrameSize.height / scaleFactor;
		
		// move the origin so it zooms in to the center of the screen;
		// first get the currend bounds rectangle
		
		currentDocBoundsRect = [clipView bounds];
		
		newOriginX = currentDocBoundsRect.origin.x + (currentDocBoundsRect.size.width  - newWidth)/2;
		newOriginY = currentDocBoundsRect.origin.y + (currentDocBoundsRect.size.height - newHeight)/2;
		
		[clipView setBounds:NSMakeRect(newOriginX, newOriginY, newWidth, newHeight)];
		
		
    }
}

- (void)setHasHorizontalScroller:(BOOL)flag {
    if (!flag) [self setScaleFactor:1.0 adjustPopup:NO];
    [super setHasHorizontalScroller:flag];
}
 */

#pragma mark *** trackpad events handling ***

- (void)magnifyWithEvent:(NSEvent *)event {

	CGFloat factor = [self scaleFactor];
	BOOL tooBig = [event magnification] > 0 && factor >= MAX_SCALE_FACTOR;
	BOOL tooSmall = [event magnification] < 0 && factor <= MIN_SCALE_FACTOR;
	if (tooBig || tooSmall) {
		return;
	}
	NSRect newRect;
	NSView *clipView = [[self documentView] superview];
	NSRect	clipViewBoundsRect = [clipView bounds];
	CGFloat scale = 1/([event magnification] + 1.0);
	NSPoint mouseLoc = [event locationInWindow];
	mouseLoc = [clipView convertPointFromBase:mouseLoc];

// we want to zoom in at the mouse point, so we move the origin	
	newRect.size.height = clipViewBoundsRect.size.height*scale ;
	newRect.size.width = clipViewBoundsRect.size.width*scale;
	newRect.origin.x = clipViewBoundsRect.origin.x*scale + mouseLoc.x*(1-scale);
	newRect.origin.y = clipViewBoundsRect.origin.y*scale + mouseLoc.y*(1-scale);

    [clipView setBounds:newRect];
}


- (void)swipeWithEvent:(NSEvent *)event {
	[[self documentView] swipeWithEvent:event];
}

#pragma mark *** zooming and scrolling ***

-(CGFloat)scaleFactor{
	CGFloat boundsWidth = [self contentView].bounds.size.width;
	CGFloat frameWidth = [self contentSize].width;
	return frameWidth/boundsWidth;
}

-(void)zoomToPoint: (NSPoint) point withScaling: (CGFloat)scale{
	
	NSRect newRect;
	NSView *clipView = [self contentView];
	NSRect	clipViewBoundsRect = [clipView bounds];
	CGFloat actualScale = 1/scale;

	
	// we want to zoom in at the point, so we move the origin	
	newRect.size.height = clipViewBoundsRect.size.height*actualScale ;
	newRect.size.width = clipViewBoundsRect.size.width*actualScale;
	newRect.origin.x = clipViewBoundsRect.origin.x*actualScale + point.x*(1-actualScale);
	newRect.origin.y = clipViewBoundsRect.origin.y*actualScale + point.y*(1-actualScale);
	
    [clipView setBounds:newRect];
	
}

-(IBAction)zoomIn:(id)sender{
	if ([self scaleFactor] >= MAX_SCALE_FACTOR) {
		return;
	}
	
	// do these variable names shadow the ones in the above function?
	
	NSRect	clipViewBoundsRect = [[self contentView] bounds];
	

	CGFloat centerX = NSMidX(clipViewBoundsRect);
	CGFloat centerY = NSMidY(clipViewBoundsRect);
	
	[self zoomToPoint:NSMakePoint(centerX, centerY) withScaling: sqrt(2.0)];
	
}
-(IBAction)zoomOut:(id)sender{
	if ([self scaleFactor] <= MIN_SCALE_FACTOR) {
		return;
	}
	
	// do these variable names shadow the ones in the above function?
	
	NSRect	clipViewBoundsRect = [[self contentView] bounds];
	
	CGFloat centerX = NSMidX(clipViewBoundsRect);
	CGFloat centerY = NSMidY(clipViewBoundsRect);
	
	[self zoomToPoint:NSMakePoint(centerX, centerY) withScaling: 1/sqrt(2.0)];
	
	
}

-(IBAction)zoomToFit:(id)sender{
	
}

-(IBAction)fitWidth:(id)sender{
//	// why should the scrollview know that document contains an artboard?
	// under construction
//	CGFloat artBoardWidth = [[[self documentView] theArtBoard] width];
//	NSRect clipViewBoundsRect = [[self contentView] bounds];
//	NSRect newRect;
//	
//	CGFloat scale = clipViewBoundsRect.size.width/artBoardWidth;
//	newRect = NSMakeRect(<#CGFloat x#>, <#CGFloat y#>, <#CGFloat w#>, <#CGFloat h#>)
//
//	[self zoomToPoint:NSMakePoint(centerX, centerY) withScaling:lkj];
	
}

-(IBAction)fitHeight:(id)sender{
	
}

-(IBAction)zoomOriginLowerLeft:(id)sender{
	
	[[self documentView] scrollPoint:NSMakePoint(0, 0)];
}

-(IBAction)scrollToCenter:(id)sender{
	NSSize clipViewBoundsSize = [[self contentView] bounds].size;
	[[self documentView] scrollPoint:NSMakePoint(-clipViewBoundsSize.width/2, -clipViewBoundsSize.height/2)];
}



@end
