//
//  LogView.m
//  LevoClient
//
//  Created by iBcker on 13-5-13.
//  Copyright (c) 2013年 iBcker. All rights reserved.
//

#import "LogView.h"
#import "PreferencesModel.h"
@interface LogView()
@end

@implementation LogView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
        [[PreferencesModel sharedInstance] addObserver:self forKeyPath:KConnetLogs options:NSKeyValueObservingOptionNew context:nil];
    }
    return self;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    NSArray *logs=[[PreferencesModel sharedInstance] log:6];
//    NSLog(@"%@",logs);
    NSMutableString *logStr=[[NSMutableString alloc] init];
    for (int i = 0; i<[logs count]; i++) {
        [logStr appendFormat:@"%@\n",logs[i]];
    }
    self.lb1.stringValue=logStr;
}

@end
