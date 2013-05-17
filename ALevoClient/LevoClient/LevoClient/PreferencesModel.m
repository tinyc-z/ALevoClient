//
//  PreferencesModel.m
//  LevoClient
//
//  Created by iBcker on 13-5-11.
//  Copyright (c) 2013年 iBcker. All rights reserved.
//

#import "PreferencesModel.h"
#import "LevoConnet.h"
#import <objc/runtime.h>

#define MaxLogNum 100

@interface PreferencesModel()

@property(strong)NSUserDefaults *config;
@end
@implementation PreferencesModel

IMP_SINGLETON(PreferencesModel)

-(id)init
{
    if (self=[super init]) {
        self.logs=[[NSMutableArray alloc] initWithCapacity:5];
        self.config=[NSUserDefaults standardUserDefaults];
        [self readVersion];
        [self creatUserDefault];

        
        
        _UserName=[self.config stringForKey:KUserName];
        _UserPwd=[self.config stringForKey:KUserPwd];

        _AutoReConnet=[self.config boolForKey:KAutoReConnet];
        _AutoLogin=[self.config boolForKey:KAutoLogin];

        _CheckOfflineHost=[self.config stringForKey:KCheckOfflineHost];
        _CheckOfflineTime=(int)[self.config integerForKey:KCheckOfflineTime];
        
        if (_CheckOfflineTime<=0)_CheckOfflineTime=DefaultCheckOfflineTime;
        
        _Device=[self.config stringForKey:KDevice];
        
        [self addObserver:self forKeyPath:KUserName options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:nil];
        [self addObserver:self forKeyPath:KUserPwd options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:nil];
        [self addObserver:self forKeyPath:KAutoReConnet options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:nil];
        [self addObserver:self forKeyPath:KAutoLogin    options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:nil];
        [self addObserver:self forKeyPath:KDevice options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:nil];
        [self addObserver:self forKeyPath:KCheckOfflineHost options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:nil];
        [self addObserver:self forKeyPath:KCheckOfflineTime options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:nil];
    }
    return self;
}

- (void)creatUserDefault
{
    NSString *key=@"firstTimeFlag";
    if(![self.config objectForKey:key]){
        [self.config setBool:YES forKey:KAutoLogin];
        [self.config setBool:YES forKey:KAutoReConnet];
        [self.config setObject:@"NO" forKey:key];
        [self.config setObject:@"" forKey:KUserName];
        [self.config setObject:@"" forKey:KUserPwd];
        [self.config setObject:@"" forKey:KDevice];
        [self.config setObject:@"" forKey:KCheckOfflineHost];
        [self.config setInteger:5 forKey:KCheckOfflineTime];
        [self pushLog:@"creatUserDefault"];
    }else{
        if (![self.config objectForKey:KUserName]) {
            [self.config setObject:@"" forKey:KUserName];
        }
        if (![self.config objectForKey:KUserPwd]) {
            [self.config setObject:@"" forKey:KUserPwd];
        }
        if (![self.config objectForKey:KDevice]) {
            [self.config setObject:@"" forKey:KDevice];
        }
        if (![self.config objectForKey:KCheckOfflineHost]) {
            [self.config setObject:@"" forKey:KCheckOfflineHost];
        }
    }
    [self.config synchronize];
}

- (void)readVersion
{
    [[NSBundle mainBundle] infoDictionary];
    NSDictionary* infoDict = [[NSBundle mainBundle] infoDictionary];
    _versionStr=[NSString stringWithFormat:@"%@%@",[infoDict objectForKey:@"CFBundleShortVersionString"],[infoDict objectForKey:@"CFBundleVersion"]];
}

- (void)pushErrorLog:(NSString *)log
{
    [self pushLog:log];
    self.StopConnet=YES;
}

- (void)pushLog:(NSString *)log
{
    @synchronized(self){
        if (!log) {
            log=@"<nil>";
        }
        if ([self.logs count]>=MaxLogNum) {
            [self.logs removeObjectAtIndex:0];
            [self.logs removeObjectAtIndex:1];
        }
        [self.logs addObject:log];
        self.logsCount=[self.logs count];
    }
}

- (NSArray *)log:(int)row
{
    if ([self.logs count]<=row) {
        return [self.logs copy];
    }else{
         NSMutableArray *logs=[[NSMutableArray alloc] initWithCapacity:row];
        int count =(int)[self.logs count];
        for (int i=count-row; i<count; i++) {
            [logs addObject:[self.logs objectAtIndex:i]];
        }
        return logs;
    }
}



- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([change[@"new"]isEqualTo:change[@"old"]] || !change[@"new"]) {
        return;
    }
    NSLog(@"model->%@",change);
    if ([keyPath isEqualToString:KUserName]||
        [keyPath isEqualToString:KUserPwd]||
        [keyPath isEqualToString:KCheckOfflineHost]||
        [keyPath isEqualToString:KDevice]) {
        [self.config setObject:change[@"new"] forKey:keyPath];
    }else if ([keyPath isEqualToString:KAutoReConnet]||
              [keyPath isEqualToString:KAutoLogin]
              ) {
        [self.config setBool:[change[@"new"] boolValue] forKey:keyPath];
    }else if ([keyPath isEqualToString:KCheckOfflineTime]) {
        [self.config setInteger:[change[@"new"] integerValue] forKey:keyPath];
    }
    [self.config synchronize];
    
}

- (void)cleanLog
{
    [self.logs removeAllObjects];
    self.logsCount=0;
}



//-----------------辅助方法----------------

- (NSString *)description
{
    NSMutableDictionary *propertyInfo = [NSMutableDictionary dictionary];
    
    Class class_t = [self class];
    while ([class_t isSubclassOfClass:[PreferencesModel class]]) {
        NSDictionary *temp = [self propertyInfoWith:class_t];
        [propertyInfo addEntriesFromDictionary:temp];
        class_t = [class_t superclass];
    }
    
    return [propertyInfo description];
}

- (NSDictionary *)propertyInfoWith:(Class)clazz
{
    u_int count;
    objc_property_t* properties = class_copyPropertyList(clazz, &count);
    NSMutableDictionary *propertyDic = [NSMutableDictionary dictionaryWithCapacity:count];
    for (int i = 0; i < count ; i++)
    {
        const char* propertyName = property_getName(properties[i]);
        NSString *key = [NSString  stringWithCString:propertyName encoding:NSUTF8StringEncoding];
        id value = [self valueForKey:key];
        if (nil == value) value = @"<nil>";
        propertyDic[key] = value;
    }
    free(properties);
    return propertyDic;
}

@end
