//
//  main.m
//  LevoClient
//
//  Created by iBcker on 13-5-10.
//  Copyright (c) 2013年 iBcker. All rights reserved.
//

#import <Cocoa/Cocoa.h>

int main(int argc, char *argv[])
{
    //杀死启动器进程
    char cmd[100]="kill ";
    strcat(cmd, argv[1]);
    system(cmd);
    return NSApplicationMain(argc, (const char **)argv);
}
