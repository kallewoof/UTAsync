UTAsync
=======

Unit Test Asynchronity for iOS/Cocoa

BSD licensed.

Brief
=======

Unit testing UI components or interactivity is very hard, especially because of the asynchronous nature of user interaction.

UTAsync is a tiny (Cocoa) C library (one .h and one .m file, 0 classes, 127 lines of code) with a few functions and macros to make unit testing UI components easy as pie.

It is restricted to SenTestingKit (at this point) and requires GCD blocks (probably always) to operate. 

Header
========

```C
// core functionality
extern dispatch_block_t ut_async();             // get a block to call when async is complete
extern BOOL ut_hold(int timeout_seconds);       // wait for async ops to finish up
extern void ut_sleep(double seconds);           // sleep asynchronously

// convenience methods
// these handle the above internally

extern BOOL ut_poll(int         timeout_seconds,// poll the given block asynchronously for success
                    double      polls_per_second, // at given frequency
                    async_block block); 

// convenience macros, extending the above further

#define ASYNC_POLL(to, pps, test) \
    ut_poll(to, pps, ^BOOL() { \
        return test;
    })

// convenience macros with SenTest extension

#define STAsyncPoll(to, pps, test, message) \
    STAssertTrue(ASYNC_POLL(to,pps,test), message " within " #to " s")
```

Examples
========

We can grab an "async" block, start up an asynchronous process, then "catch" the block at some point using `ut_hold(timeout)`, all the while staying on the main loop

```Objective-C
dispatch_block_t async = ut_async(); // set up a new async object

dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
    // do random things
    usleep(1234567);
    async();
});

STAssertTrue(ut_hold(3), @"usleeping for about 1.2 sec took longer than 3 seconds!");
```

We can simply wait for something to wrap up (on the main thread) without giving up the main thread using `ut_sleep(seconds)`

```Objective-C
// calculate huge chunk of stuff in some thread
ut_sleep(3); // wait for things to calm down a bit
// ....
```

Using `ut_poll(timeout, polls_per_sec, block)`, we can poll a given property over time. For example, "myViewController should appear on screen within 3 seconds":

```Objective-C
STAssertTrue(ut_poll(3, 4, ^BOOL() {
    return myViewController.isViewLoaded && myViewController.view.window != nil;
}));
// ....
```

which has a macro, and can be shortened to

```Objective-C
STAssertTrue(ASYNC_POLL(3, 4, myViewController.isViewLoaded && myViewController.view.window != nil));
// ....
```

which in turn has a macro for SenTestingKit, and can be shortened to

```Objective-C
STAsyncPoll(3, 4, myViewController.isViewLoaded && myViewController.view.window != nil);
// ....
```

A random example from an existing unit test looks like this:

```Objective-C
[_db loadDocumentAsProject:doc];

// wait for project to become the root view controller
STAsyncPoll(10, 3, [rootvc isKindOfClass:[IProjectHandler class]], 
  @"IProjectHandler class didn't become root vc");
_projhandler = (id)rootvc;

// wait for project to finalize
STAsyncPoll(10, 3, _projhandler.ready, @"project initialization did not finalize");

_w = _projhandler.world;

// ensure world is sane
STAssertTrue(_w.allTiles.count > 0, @"zero tiles in project");

// bring up a transitions controller (for changing transitions in the project)
ICTransitionSlateViewController *vc = [[ICTransitionSlateViewController alloc] init];
//...

// ensure vc appears
STAsyncPoll(2, 4, nil != vc.view.window, @"slate vc did not appear");

// ... 

// we have a UIPickerView, and we want to test selecting the 4th item and then dismissing 
// the popover (which triggers a 'save')
NSString *transition = [transitions objectAtIndex:4];
[picker selectRow:4 inComponent:0 animated:NO];
[vc pickerView:picker didSelectRow:4 inComponent:0];
ut_sleep(0.5);
[popover dismissPopoverAnimated:NO];

// wait for the transition change to take effect
// ...
```

Credit
========

UTAsync is based on the ideas presented at

http://stackoverflow.com/questions/7817605/pattern-for-unit-testing-async-queue-that-calls-main-queue-on-completion 

