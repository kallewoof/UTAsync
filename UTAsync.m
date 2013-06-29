//
//  UTAsync.m
//
//  Created by Karl-Johan Alm on 6/29/13.
//  BSD licensed
//

#import "UTAsync.h"

typedef struct async_t *async_t;
struct async_t {
    BOOL                 failed;
    dispatch_block_t     block;
    dispatch_semaphore_t semaphore;
};

static async_t latest_at = NULL;

static inline void ut_free(async_t at)
{
    dispatch_release(at->semaphore);
    [at->block release];
    free(at);
}

dispatch_block_t ut_async()
{
    async_t at = latest_at = malloc(sizeof(struct async_t));
    at->failed = NO;
    at->semaphore = dispatch_semaphore_create(0);

    at->block = [^{
        if (at->failed) {
            ut_free(at);
            return;
        }
        dispatch_semaphore_signal(at->semaphore);
    } copy];
    
    return at->block;
}

BOOL ut_hold(int timeout_seconds)
{
    async_t at = latest_at;
    assert(at);
    NSDate *loopUntil = [NSDate dateWithTimeIntervalSinceNow:timeout_seconds];
    long r = 0;
    while ((r = dispatch_semaphore_wait(at->semaphore, DISPATCH_TIME_NOW)) && 
           [loopUntil timeIntervalSinceNow] > 0) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                 beforeDate:loopUntil];
    }
    
    // success (from dispatch_semaphore_wait())
    if (0 == r) {
        ut_free(at);
        return YES;
    }
    
    // failure; wait for block to be called to do clean up
    return NO;
}

void ut_sleep(double seconds)
{
    NSDate *loopUntil = [NSDate dateWithTimeIntervalSinceNow:seconds];
    while ([loopUntil timeIntervalSinceNow] > 0.0) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                 beforeDate:loopUntil];
    }
}

BOOL ut_poll(int         timeout_seconds,
             double      polls_per_second,
             async_block block)
{
    dispatch_block_t async = ut_async();
    async_t at = latest_at;
    
    useconds_t period = (useconds_t)(1000000.0 / polls_per_second);

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        while (! at->failed && ! block()) usleep(period);
        async();
    });
    
    return ut_hold(timeout_seconds);
}
