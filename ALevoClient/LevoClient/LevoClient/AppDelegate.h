//
//  AppDelegate.h
//  LevoClient
//
//  Created by iBcker on 13-5-10.
//  Copyright (c) 2013年 iBcker. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NetSpeedInfView.h"
#import "DeviceInfoView.h"
#import "LogView.h"

@interface AppDelegate : NSObject <NSApplicationDelegate,NSWindowDelegate>

@property (assign) IBOutlet NSWindow *alert;
@property (weak) IBOutlet NSButton *alertBnOk;
@property (weak) IBOutlet NSTextField *alerContextLb;

@property (weak) IBOutlet NSPopover *popover;
@property (weak) IBOutlet NSView *popView;
@property (weak) IBOutlet LogView *logView;



@property (weak) IBOutlet NetSpeedInfView *netSpeed;
@property (weak) IBOutlet DeviceInfoView *deviceInfo;

@property (weak) IBOutlet NSButton *bnExit;
@property (weak) IBOutlet NSButton *bnLogin;


- (IBAction)onExit:(id)sender;
- (IBAction)onLogin:(id)sender;
- (IBAction)onPreferences:(id)sender;
@property (weak) IBOutlet NSButton *bnPreferences;


@end
