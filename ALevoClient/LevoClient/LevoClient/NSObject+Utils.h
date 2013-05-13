//
//  NSObject+Utils.h
//  IOSDemos
//
//  Created by iBcker on 12-9-8.
//  Copyright (c) 2012年 iBcker. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSObject(plugin_performs)

//给performSelectorXXX增加block操作

- (void)performBlock:(void (^)(void))block
          afterDelay:(NSTimeInterval)delay;

- (void)performBlockOnMainThread:(void (^)(void))block;

- (void)performSelectorInBackground:(SEL)aSelector
                         withObject:(id)arg
                         afterDelay:(NSTimeInterval)delay;

- (void)performBlockInBackground:(void (^)(void))block;

- (void)performBlockInBackground:(void (^)(void))block
                      afterDelay:(NSTimeInterval)delay;
@end
