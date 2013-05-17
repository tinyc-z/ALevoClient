//
//  PreferencesWindowController.h
//  LevoClient
//
//  Created by iBcker on 13-5-10.
//  Copyright (c) 2013年 iBcker. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol PreferencesDelegate <NSObject>
@required
- (void)onPreferencesApply;
@end

@interface PreferencesWindowController : NSWindowController<NSTabViewDelegate>

@property(assign)id<PreferencesDelegate> delegate;

@property (weak) IBOutlet NSTabView *tabView;
@property (weak) IBOutlet NSPopUpButton *DeviceList;

@property (strong) IBOutlet NSWindow *wAbout;

@property (weak) IBOutlet NSTextField *UserName;
@property (weak) IBOutlet NSSecureTextField *UserPwd;
@property (weak) IBOutlet NSButton *AutoRelogin;
@property (weak) IBOutlet NSButton *AutoLogin;
@property (weak) IBOutlet NSPopUpButton *CheckOfflineTime;
@property (weak) IBOutlet NSTextField *CheckOfflineHost;
@property (weak) IBOutlet NSTextField *MacAddr;

@property (weak) IBOutlet NSTextField *LbAboutVersion;

@property (weak) IBOutlet NSButton *BnApply;

@property (weak) IBOutlet NSButton *bnAbout;
- (IBAction)onAbout:(id)sender;

- (void)loadDataAndShow:(int)index;
- (IBAction)onWeibo:(id)sender;

@end
