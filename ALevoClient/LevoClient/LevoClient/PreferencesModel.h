//
//  PreferencesModel.h
//  LevoClient
//
//  Created by iBcker on 13-5-11.
//  Copyright (c) 2013年 iBcker. All rights reserved.
//

#import <Foundation/Foundation.h>

#define KConnetSate @"connetState"
#define KConnetLogs @"logsCount"

#define KUserName @"UserName"
#define KUserPwd @"UserPwd"
#define KAutoReConnet @"AutoReConnet"
#define KAutoLogin @"AutoLogin"
#define KCheckOfflineHost @"CheckOfflineHost"
#define KCheckOfflineTime @"CheckOfflineTime"
#define KDevice @"Device"

#define DefaultCheckOfflineTime 5

typedef enum{
    ConnetStateOffLine,
    ConnetStateOnline,
    ConnetStateLgoing,
    ConnetStateError,
}ConnetState;

@interface PreferencesModel : NSObject

@property(nonatomic,strong)NSString *UserName;
@property(nonatomic,strong)NSString *UserPwd;
@property(nonatomic,assign)BOOL AutoReConnet;
@property(nonatomic,assign)BOOL AutoLogin;
@property(nonatomic,strong)NSString *CheckOfflineHost;

@property(nonatomic,assign)int CheckOfflineTime;
@property(nonatomic,strong)NSString *Device;

@property(nonatomic,assign)int ConnetedTime;//在线时间
@property(nonatomic,assign)int ReConnetTime;//连接重试次数

@property(nonatomic,assign)ConnetState connetState;
@property(nonatomic,assign)int connetTimeout;

@property(nonatomic,assign)BOOL StopConnet;//用户手动停止

@property(nonatomic,strong)NSMutableArray *logs;
@property(nonatomic,assign)long logsCount;
@property(nonatomic,strong)NSString *versionStr;

- (void)pushErrorLog:(NSString *)log;
- (void)pushLog:(NSString *)log;
- (NSArray *)log:(int)row;
- (void)cleanLog;

DEF_SINGLETON(PreferencesModel);
@end
