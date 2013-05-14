//
//  AppDelegate.m
//  LevoClient
//
//  Created by iBcker on 13-5-10.
//  Copyright (c) 2013年 iBcker. All rights reserved.
//


#import "AppDelegate.h"
#import "PreferencesWindowController.h"
#import "PreferencesModel.h"
#import "LevoConnet.h"
#import "NetSpeedInfView.h"

#define KImageOnline @"link.png"
#define KImageLoging @"reLink.png"
#define KImageOffLine @"unlink.png"
#define KImageGreedLight @"greedlight.png"

#define KConnetTimeOut 5

@interface AppDelegate()
{
    __block int connetTimeout;
}
@property(nonatomic,strong)PreferencesWindowController *preferencesWC;

@property(assign)PreferencesModel *config;

@property(nonatomic,strong)NSStatusItem *statusBar;
@property(nonatomic,strong)NSButton *statusBarButton;
@property(strong)NSImageView *falshlight;

- (BOOL)neeShowUserPreferences;//读取用户配置

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    if([[LevoConnet sharedInstance] isRunningCheck]){
        [self showAler:@"启动出错" context:@"程序可能没有root权限或者已经运行~！" action:@selector(onExit:)];
    }else{
        self.config=[PreferencesModel sharedInstance];
        self.preferencesWC.delegate=self;
        [self.config addObserver:self forKeyPath:KConnetSate options:NSKeyValueObservingOptionNew context:nil];
        [self initStatusBar];
        self.popover.behavior = NSPopoverBehaviorTransient;
        [self.popView addSubview:self.logView];
        self.logView.top=25;
        self.logView.left=13;
        [self.logView setHidden:YES];
        
        self.config.connetTimeout=KConnetTimeOut;
        NSButton *bn=self.bnPreferences;
        [bn setBordered:NO];
        [self.popView addSubview:self.deviceInfo];
        self.deviceInfo.top=10;
        [NSTimer scheduledTimerWithTimeInterval: 0.5
                                         target: self
                                       selector: @selector(timerAction:)
                                       userInfo: nil
                                        repeats: YES];
        [self updateView:ConnetStateOffLine];
        if([self neeShowUserPreferences]){
            [self showPreferences];
        }else if (self.config.AutoLogin) {
            [self onLogin:nil];
        }
    }
}

- (void)timerAction:(id)sender
{
    if (self.config.connetState==ConnetStateOnline) {
        int time=[NSDate timeIntervalSinceReferenceDate]-self.config.ConnetedTime;
        if (time<60) {
            self.deviceInfo.lbStateContext.stringValue=[NSString stringWithFormat:@"在线%d秒",time%60];
        }else if(time<3600){
            self.deviceInfo.lbStateContext.stringValue=[NSString stringWithFormat:@"在线%d分%d秒",time/60,time%60];
        }else{
            self.deviceInfo.lbStateContext.stringValue=[NSString stringWithFormat:@"在线%d小时%d分%d秒",time/3600,time/60,time%60];
        }
    }
    [self showConnetLight];
}


- (PreferencesWindowController *)preferencesWC
{
    if (!_preferencesWC) {
        _preferencesWC=[[PreferencesWindowController alloc] initWithWindowNibName:@"PreferencesWindowController"];
    }
    return _preferencesWC;
}



-(void)initStatusBar
{
    self.statusBar = [[NSStatusBar systemStatusBar] statusItemWithLength:NSSquareStatusItemLength];
    self.statusBar.image=[NSImage imageNamed:KImageOffLine];
    [self.statusBar setHighlightMode:YES];
    [self.statusBar setAction:@selector(onMenuAction:)];
    
    self.statusBarButton=(NSButton *)[self.statusBar valueForKey:@"fView"];
    NSImageView *imagev=[[NSImageView alloc] init];
    imagev.frame=CGRectMake(22, 14, 6, 6);
    imagev.image=[NSImage imageNamed:KImageGreedLight];
    self.falshlight=imagev;
    [self.falshlight setAlphaValue:.8];
    [self.statusBarButton addSubview:self.falshlight];
    [self showConnetLight];
}

- (BOOL)neeShowUserPreferences
{
    return (self.config.UserName.length==0||self.config.UserPwd.length==0);
}



- (void)statusBarStyle:(ConnetState)state
{
    switch (state) {
        case ConnetStateOnline:
            self.statusBar.image=[NSImage imageNamed:KImageOnline];
            break;
        case ConnetStateLgoing:
            self.statusBar.image=[NSImage imageNamed:KImageLoging];
            break;
        case ConnetStateOffLine:
            self.statusBar.image=[NSImage imageNamed:KImageOffLine];
            break;
        default:
            break;
    }
    [self showConnetLight];
}


- (void)showConnetLight
{
    if (self.config.connetState==ConnetStateLgoing) {
        [self.falshlight setHidden:!self.falshlight.isHidden];
    }else{
        [self.falshlight setHidden:YES];
    }
}

- (BOOL)windowShouldClose:(id)sender
{
    return YES;
}



- (void)showPreferences
{
    [self.popover close];
    if (!self.preferencesWC.window.isVisible) {
        [self.preferencesWC.window makeKeyAndOrderFront:nil];
        [self.preferencesWC showWindow:nil];
//        [self.preferencesWC becomeFirstResponder];
    }
    [NSApp activateIgnoringOtherApps:YES];
}

- (void)showPoper:(id)sender;
{
    self.deviceInfo.lbDev.stringValue=[NSString stringWithFormat:@"%@/%@",[[LevoConnet sharedInstance] selectedDevName],[[LevoConnet sharedInstance] readIpString]];
    self.deviceInfo.lbMac.stringValue=[[LevoConnet sharedInstance] readMacAddress];
    [self.popover showRelativeToRect:[sender bounds] ofView:sender preferredEdge:NSMaxYEdge];
    [NSApp activateIgnoringOtherApps:YES];
}

- (void)showAler:(NSString *)title context:(NSString *)context action:(SEL)selecter;
{
    if (!self.alert.isVisible) {
        [self.alert makeKeyAndOrderFront:nil];
        [self.alert setLevel:kCGScreenSaverWindowLevel+1];
        [self.alert.windowController showWindow:nil];
    }
    self.alert.title=title;
    self.alerContextLb.stringValue=context;
    [self.alertBnOk setAction:selecter];
    [NSApp activateIgnoringOtherApps:YES];
}

- (IBAction)onMenuAction:(id)sender;
{
    if (self.preferencesWC.window.isVisible) {
        [self showPreferences];
    }else{
        [self showPoper:sender];
    }
}


- (IBAction)onLogin:(id)sender
{
    @synchronized(self){
        self.config.connetTimeout=KConnetTimeOut;
        if (self.config.connetState==ConnetStateLgoing||self.config.connetState==ConnetStateOnline) {
            self.config.StopConnet=YES;
            [self try2Cancle];
        }else{
            [self.config cleanLog];
            self.config.StopConnet=NO;
            self.config.ReConnetTime=0;
            [self try2Login];
        }
    }
}

- (void)updateView:(ConnetState)state
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self statusBarStyle:state];
        switch (state) {
            case ConnetStateLgoing:
                self.bnLogin.title=@"取消";
                int time=self.config.ReConnetTime;
                if (time==1) {
                    [[PreferencesModel sharedInstance]pushLog:@"尝试登录..."];
                }else{
                    [[PreferencesModel sharedInstance]pushLog:[NSString stringWithFormat:@"第%d次尝试登录...",time]];
                }
                self.deviceInfo.lbStateContext.stringValue=@"连接中...";
                [self.bnPreferences setHidden:YES];
                [self.logView setHidden:NO];
                [self.deviceInfo setHidden:YES];
                break;
            case ConnetStateOnline:
                [[PreferencesModel sharedInstance]pushLog:@"登录成功..."];
                self.config.ConnetedTime=[NSDate timeIntervalSinceReferenceDate];
                self.bnLogin.title=@"断开";
                self.deviceInfo.lbStateContext.stringValue=@"在线";
                [self.bnPreferences setHidden:YES];
                [self.logView setHidden:YES];
                [self.deviceInfo setHidden:NO];
                break;
            case ConnetStateOffLine:
//                [[PreferencesModel sharedInstance]pushLog:@"断开登录..."];
                self.bnLogin.title=@"连接";
                self.deviceInfo.lbStateContext.stringValue=@"离线";
                [self.bnPreferences setHidden:NO];
                [self.logView setHidden:YES];
                [self.deviceInfo setHidden:NO];
                break;
            default:
                break;
        }
    });
}


- (void)try2Login
{
    if (self.config.StopConnet==YES){
        self.config.connetState=ConnetStateOffLine;
        return;
    }
    self.config.connetState=ConnetStateLgoing;
    self.config.ReConnetTime+=1;
    [[LevoConnet sharedInstance] connetNeedInit:YES sucess:^{
        NSLog(@"------> login sucess <------");
        self.config.connetTimeout=KConnetTimeOut;
        self.config.connetState=ConnetStateOnline;
        self.config.ReConnetTime=0;
        [self checkOnline];
    } andFail:^{
        NSLog(@"------> login fail %d <------",self.config.ReConnetTime);
        [self try2Login];
    }];
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(cancleHandler) object:nil];
    [self performSelector:@selector(cancleHandler) withObject:nil afterDelay:self.config.connetTimeout];
}

- (void)cancleHandler
{
    if(self.config.connetState!=ConnetStateOnline){
        if (self.config.connetTimeout<15) {
            self.config.connetTimeout+=2;
        }
        [self try2Cancle];
    }
}

- (void)try2Cancle
{
    [[LevoConnet sharedInstance] cancle];
}


- (void)checkOnline
{
    if(self.config.StopConnet||self.config.connetState!=ConnetStateOnline)return;
    [[LevoConnet sharedInstance] checkOnline:^(BOOL online) {
        if (online) {
            NSLog(@"--->在线");
            [self performSelector:@selector(checkOnline) withObject:nil afterDelay:self.config.CheckOfflineTime];
        }else{
            NSLog(@"--->掉线");
            if (self.config.AutoReConnet) {
//                [self try2Login];
                [self try2Cancle];
            }
            self.config.connetState=ConnetStateOffLine;
        }
    }];
}

- (IBAction)onPreferences:(id)sender
{
    [self showPreferences];
}
- (IBAction)onExit:(id)sender
{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [[LevoConnet sharedInstance] cancle];
    });
    exit(1);
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:KConnetSate]) {
        ConnetState state=[change[@"new"] intValue];
        [self updateView:state];
    }
}

- (void)onPreferencesApply
{
    [self showPoper:self.statusBarButton];
    if (self.config.AutoLogin) {
        [self onLogin:nil];
    }
}

@end
