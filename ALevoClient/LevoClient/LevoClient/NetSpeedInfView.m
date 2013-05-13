//
//  NetSpeedInformation.m
//  LevoClient
//
//  Created by iBcker on 13-5-12.
//  Copyright (c) 2013年 iBcker. All rights reserved.
//

#import "NetSpeedInfView.h"
#import "LevoConnet.h"
@interface NetSpeedInfView()
@property(nonatomic,assign)LevoConnet *engine;
@end
@implementation NetSpeedInfView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
        self.engine=[LevoConnet sharedInstance];
//         [self updateView];
    }
    return self;
}
//- (void)viewWillDraw
//{
//    NSLog(@"update speed view--");
//   
//}
- (void)updateView
{
    [self.engine getKbps:5 speed:^(float upSpeed, float downSpeed) {
        if (!self.isHidden) {
        NSLog(@"%f  --  %f",upSpeed,downSpeed);
            dispatch_async(dispatch_get_main_queue(), ^{
                self.lbUp.stringValue=[NSString stringWithFormat:@"⇡dd%f",upSpeed];
                self.lbDown.stringValue=[NSString stringWithFormat:@"⇣%f",downSpeed];
                [self setNeedsDisplay:YES];
                [self performSelector:@selector(updateView) withObject:nil afterDelay:0.5];
            });

        }
    }];
}
//- (void)drawRect:(NSRect)dirtyRect
//{
//    // Drawing code here.
//}

@end
