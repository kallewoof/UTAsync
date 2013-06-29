//
//  UTAsync.h
//
//  Created by Karl-Johan Alm on 6/29/13.
//  BSD licensed
//

#import <Foundation/Foundation.h>

typedef BOOL(^async_block)(void);               // a block with a success flag

// core functionality
extern dispatch_block_t ut_async();             // get a block to call when async is complete
extern BOOL ut_hold(int timeout_seconds);       // wait for async ops to finish up
extern void ut_sleep(double seconds);           // sleep asynchronously

// convenience methods
// these handle the above internally

extern BOOL ut_poll(int         timeout_seconds,// poll the given block asynchronously for success at given frequency
                    double      polls_per_second,
                    async_block block); 

// convenience macros, extending the above further

#define ASYNC_POLL(to, pps, test) \
    ut_poll(to, pps, ^BOOL() { \
        BOOL _the_results_ = test; \
        NSLog(@"results for " #test " are: %@", _the_results_ ? @"YES" : @"NO"); \
        return _the_results_; \
    })

// convenience macros with SenTest extension

#define STAsyncPoll(to, pps, test, message) \
    STAssertTrue(ASYNC_POLL(to,pps,test), message " within " #to " s")
