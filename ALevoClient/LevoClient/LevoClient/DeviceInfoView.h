//
//  DeviceInfoView.h
//  LevoClient
//
//  Created by iBcker on 13-5-12.
//  Copyright (c) 2013年 iBcker. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface DeviceInfoView : NSView
@property (weak) IBOutlet NSTextField *lbDev;
@property (weak) IBOutlet NSTextField *lbMac;
@property (weak) IBOutlet NSTextField *lbStateContext;
@property (weak) IBOutlet NSTextField *lbStateTitle;

@end
