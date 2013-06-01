//
//  EXTTriple.h
//  Ext Chart
//
//  Created by Eric Peterson on 5/29/13.
//  Copyright (c) 2013 Harvard University. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EXTLocation.h"

@interface EXTTriple : NSObject <EXTLocation> {
    int a, b, c;
}
@property int a;
@property int b;
@property int c;

-(id) initWithA:(int)aa B:(int)bb C:(int)cc;
+(id) tripleWithA:(int)aa B:(int)bb C:(int)cc;

-(NSPoint) makePoint;
-(NSString *) description;
+(EXTTriple*) addLocation:(EXTTriple*)a to:(EXTTriple*)b;
+(EXTTriple*) followDiffl:(EXTTriple*)a page:(int)page;
+(EXTTriple*) reverseDiffl:(EXTTriple*)b page:(int)page;

@end
