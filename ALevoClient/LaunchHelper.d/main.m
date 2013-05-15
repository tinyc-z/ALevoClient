//
//  main.m
//  LaunchHelper
//
//  Created by iBcker on 13-5-15.
//  Copyright (c) 2013年 iBcker. All rights reserved.
//

#import <Foundation/Foundation.h>

int main(int argc, const char * argv[])
{

    @autoreleasepool {
            NSTask *launch=[[NSTask alloc] init];
            //        NSString *path=[NSString stringWithUTF8String:argv[1]];
            NSString *path=[[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/LevoClient.app/Contents/MacOS/LevoClient"];
            NSLog(@"path->%@",path);
            [launch setLaunchPath:path];
            [launch launch];
        exit(1);
        exit(0);
    }
    return 0;
}

