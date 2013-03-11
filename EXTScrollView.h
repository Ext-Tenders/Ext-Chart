#import <Cocoa/Cocoa.h>

@class NSPopUpButton;

#define MAX_SCALE_FACTOR  64.0
#define MIN_SCALE_FACTOR  .1 


@interface EXTScrollView : NSScrollView {
    NSPopUpButton *_scalePopUpButton;
	NSComboBox *_scalingComboBox;
//    CGFloat scaleFactor;
}

- (IBAction)zoomIn:(id)sender;
- (IBAction)zoomOut:(id)sender;
- (IBAction)zoomToFit:(id)sender;
- (IBAction)scrollToCenter:(id)sender;

- (IBAction)fitWidth:(id)sender;
- (IBAction)fitHeight:(id)sender;

- (void)zoomToPoint: (NSPoint) point withScaling: (CGFloat)scale;
- (CGFloat)scaleFactor;



/*
-(void)scalePopUpAction:(id)sender;
-(void)setScaleFactor:(float)factor adjustPopup:(BOOL)flag;
-(float)scaleFactor;
 */


@end
