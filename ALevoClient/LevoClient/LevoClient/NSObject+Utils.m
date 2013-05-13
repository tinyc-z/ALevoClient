//
//  NSObject+Utils.m
//  IOSDemos
//
//  Created by iBcker on 12-9-8.
//  Copyright (c) 2012年 iBcker. All rights reserved.
//

#import "NSObject+Utils.h"

@implementation NSObject(plugin_performs)
- (void)performBlock:(void (^)(void))block
          afterDelay:(NSTimeInterval)delay
{
    block = [block copy];
    [self performSelector:@selector(fireBlockAfterDelay:)
               withObject:block
               afterDelay:delay];
}
- (void)fireBlockAfterDelay:(void (^)(void))block {
    block();
}

- (void)performBlockOnMainThread:(void (^)(void))block
{
    block = [block copy];
    [self performSelectorOnMainThread:@selector(fireBlockOnMainThread:)
                           withObject:block
                        waitUntilDone:NO];
}

- (void)fireBlockOnMainThread:(void (^)(void))block {
    block();
}


- (void)performBlockInBackground:(void (^)(void))block
{
    block = [block copy];
    [self performSelectorInBackground:@selector(fireBlockInBackground:) withObject:block];
}

- (void)performBlockInBackground:(void (^)(void))block afterDelay:(NSTimeInterval)delay
{
    block = [block copy];
    [self performSelector:@selector(performBlockInBackground:) withObject:block afterDelay:delay];
}

- (void)fireBlockInBackground:(void (^)(void))block {
    block();
}

- (void)performSelectorInBackground:(SEL)aSelector withObject:(id)arg afterDelay:(NSTimeInterval)delay
{
    [self performSelector:@selector(fireInBackground:withObject:) withObject:arg afterDelay:delay];
    
}

- (void)fireInBackground:(SEL)aSelector withObject:arg
{
    [self performSelectorInBackground:aSelector withObject:arg];
}


@end
