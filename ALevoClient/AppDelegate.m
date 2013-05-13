//
//  AppDelegate.m
//  ZLevoClient
//
//  Created by iBcker on 13-5-10.
//  Copyright (c) 2013年 iBcker. All rights reserved.
//

#import "AppDelegate.h"
#import "STPrivilegedTask.h"

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [self start];
}

- (void)start
{
    NSString *path=[[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/LevoClient.app/Contents/MacOS/LevoClient"];
    NSLog(@"login");
    STPrivilegedTask *ta=[[STPrivilegedTask alloc] init];
    [ta setLaunchPath:path];
    [ta launch];
    [ta waitUntilExit];
    NSLog(@"--exit");
    [NSApp terminate:nil];
}


@end
