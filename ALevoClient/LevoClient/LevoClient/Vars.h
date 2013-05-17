//
//  Vars.h
//  LevoClient
//
//  Created by iBcker on 13-5-10.
//  Copyright (c) 2013年 iBcker. All rights reserved.
//


#define DEF_SINGLETON(__klass__) + (__klass__ *)sharedInstance;

#define IMP_SINGLETON(__klass__) \
+ (__klass__ *)sharedInstance { \
static id sharedObject = nil; \
static dispatch_once_t onceToken; \
dispatch_once(&onceToken, ^{ \
sharedObject = [[__klass__ alloc] init]; \
}); \
return sharedObject; \
}\
- (id)copyWithZone:(NSZone*)zone{\
return self;\
}

#define CheckOfflineHost1 "8.8.4.4"
#define CheckOfflineHost2 "www.baidu.com"
