//
//  AppDelegate.m
//  ZLevoClient
//
//  Created by iBcker on 13-5-10.
//  Copyright (c) 2013年 iBcker. All rights reserved.
//

#import "AppDelegate.h"
//#import "STPrivilegedTask.h"

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [self start];
}

- (void)start
{
    NSString * output = nil;
    NSString * processErrorDescription = nil;
    NSString *path=[[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/LevoClient.app/Contents/MacOS/LevoClient"];
    BOOL success = [self runProcessAsAdministrator:path
                                     withArguments:@[]
                                            output:&output
                                  errorDescription:&processErrorDescription];
    NSLog(@"%@",processErrorDescription);

    //STPrivilegedTask 怎么竟出毛病···晕死···不用你试试···
//    NSString *path=[[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/LevoClient.app/Contents/MacOS/LevoClient"];
//    STPrivilegedTask *ta=[[STPrivilegedTask alloc] init];
//    [ta setLaunchPath:path];
////    [ta waitUntilExit]
//    [ta launch];

    [self doExit];
}

- (void)doExit
{
    NSLog(@"ALevoClient启动器结束");
    exit(1);
}




- (BOOL) runProcessAsAdministrator:(NSString*)scriptPath
                     withArguments:(NSArray *)arguments
                            output:(NSString **)output
                  errorDescription:(NSString **)errorDescription {
    
    NSString * allArgs = [arguments componentsJoinedByString:@" "];
    NSString * fullScript = [NSString stringWithFormat:@"%@ %@", scriptPath, allArgs];
    
    NSDictionary *errorInfo = [NSDictionary new];
    NSString *script =  [NSString stringWithFormat:@"do shell script \"%@\" with administrator privileges", fullScript];
    
    NSAppleScript *appleScript = [[NSAppleScript new] initWithSource:script];
    NSAppleEventDescriptor * eventResult = [appleScript executeAndReturnError:&errorInfo];
    
    // Check errorInfo
    if (! eventResult)
    {
        // Describe common errors
        *errorDescription = nil;
        if ([errorInfo valueForKey:NSAppleScriptErrorNumber])
        {
            NSNumber * errorNumber = (NSNumber *)[errorInfo valueForKey:NSAppleScriptErrorNumber];
            if ([errorNumber intValue] == -128)
                *errorDescription = @"The administrator password is required to do this.";
        }
        
        // Set error message from provided message
        if (*errorDescription == nil)
        {
            if ([errorInfo valueForKey:NSAppleScriptErrorMessage])
                *errorDescription =  (NSString *)[errorInfo valueForKey:NSAppleScriptErrorMessage];
        }
        
        return NO;
    }
    else
    {
        // Set output to the AppleScript's output
        *output = [eventResult stringValue];
        
        return YES;
    }
}

@end
