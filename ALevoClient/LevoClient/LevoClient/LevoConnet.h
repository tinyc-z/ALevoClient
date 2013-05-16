//
//  Zlevo.h
//  MZlevoclient
//
//  Created by iBcker on 13-5-8.
//  Copyright (c) 2013年 iBcker. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LevoConnet : NSObject

DEF_SINGLETON(LevoConnet)
- (NSString *)selectedDevName;
- (NSArray *)readDeviceList;
- (NSString *)readIpString;
- (NSString *)readMacAddress;
-(void)getKbps:(int)sec speed:(void(^)(float upSpeed,float downSpeed))update;

- (NSString *)getGateWay;
-(BOOL)isRunningCheck;
-(void)checkOnline:(void(^)(BOOL online))onLine;

- (void)initEnvironment;
//- (void)connetNeedInit:(BOOL)init and:(void(^)(void))fail;
- (void)connetNeedInit:(BOOL)init sucess:(void(^)(void))sucess andFail:(void(^)(void))fail;
- (void)cancle;
- (void)cancleWithcloseHandle;
@end
