#import <Cocoa/Cocoa.h>
#import <Carbon/Carbon.h>
#include <math.h>
#import "CameraBridge.h"

// Process-local adapter. No global event tap or accessibility permission.
static BOOL enabled = YES, synthetic = NO;
static BOOL held[128], physical[128];
static double until[128];
static __weak NSWindow *targetWindow;
static id monitor, resignObserver;
static NSTimer *timer;
static BOOL (*panHandler)(double,double,double) = panCamera;
static double pendingX,pendingY,pendingHeight;
static BOOL panScheduled;
static unsigned panGeneration;
static void cancelPan(void) {
    pendingX=pendingY=0; panScheduled=NO; panGeneration++;
}
static void flushPan(void) {
    double x=pendingX,y=pendingY; pendingX=pendingY=0; panScheduled=NO;
    if (enabled && NSApp.isActive) panHandler(x,y,pendingHeight);
}
static void queuePan(double x,double y,double height) {
    pendingX+=x; pendingY+=y; pendingHeight=height;
    if (panScheduled) return;
    panScheduled=YES; unsigned generation=panGeneration;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC/60),dispatch_get_main_queue(), ^{
        if (generation==panGeneration) flushPan();
    });
}
static double now(void) { return NSProcessInfo.processInfo.systemUptime; }
static BOOL controlled(unsigned short k) {
    return k == kVK_ANSI_Q || k == kVK_ANSI_E;
}
static NSString *characters(unsigned short k) {
    unichar c = k == kVK_LeftArrow ? NSLeftArrowFunctionKey :
                k == kVK_RightArrow ? NSRightArrowFunctionKey :
                k == kVK_UpArrow ? NSUpArrowFunctionKey :
                k == kVK_DownArrow ? NSDownArrowFunctionKey :
                k == kVK_ANSI_Q ? 'q' : 'e';
    return [NSString stringWithCharacters:&c length:1];
}
static void sendKey(unsigned short k, BOOL down) {
    NSWindow *w = targetWindow ?: NSApp.keyWindow;
    if (!w) return;
    NSEvent *e = [NSEvent keyEventWithType:down ? NSEventTypeKeyDown : NSEventTypeKeyUp
        location:NSZeroPoint modifierFlags:0 timestamp:now() windowNumber:w.windowNumber
        context:nil characters:characters(k) charactersIgnoringModifiers:characters(k)
        isARepeat:NO keyCode:k];
    synthetic = YES;
    [NSApp sendEvent:e];
    synthetic = NO;
}
static void releaseKey(unsigned short k) {
    if (held[k]) { held[k] = NO; if (!physical[k]) sendKey(k, NO); }
    until[k] = 0;
}
static void releaseAll(void) {
    [timer invalidate]; timer=nil; cancelPan();
    for (unsigned short k=0; k<128; k++) releaseKey(k);
}
static void armRelease(void) {
    [timer invalidate]; timer=nil;
    double deadline=INFINITY;
    for (unsigned short k=0;k<128;k++) if (held[k]) deadline=fmin(deadline,until[k]);
    if (!isfinite(deadline)) return;
    timer=[NSTimer timerWithTimeInterval:fmax(0.001,deadline-now()) repeats:NO block:^(NSTimer *t) {
        for (unsigned short k=0;k<128;k++) if (held[k] && now()>=until[k]) releaseKey(k);
        armRelease();
    }];
    [NSRunLoop.mainRunLoop addTimer:timer forMode:NSRunLoopCommonModes];
}
static void pulse(unsigned short k, unsigned short opposite, double amount) {
    releaseKey(opposite);
    if (physical[k] || amount < 0.01) return;
    until[k] = now() + fmin(0.14, 0.035 + amount * 0.004);
    if (!held[k]) { held[k] = YES; sendKey(k, YES); }
    armRelease();
}
static NSEvent *handle(NSEvent *e) {
    if (synthetic) return e;
    if (e.type == NSEventTypeKeyDown || e.type == NSEventTypeKeyUp) {
        if (e.keyCode == kVK_F8) {
            if (e.type == NSEventTypeKeyDown && !e.isARepeat) {
                enabled = !enabled; releaseAll();
                NSLog(@"[WorldBox Trackpad v2] %@", enabled ? @"ON" : @"OFF");
            }
            return nil;
        }
        if (e.keyCode < 128 && controlled(e.keyCode)) {
            physical[e.keyCode] = e.type == NSEventTypeKeyDown;
            held[e.keyCode] = NO; until[e.keyCode] = 0;
        }
        return e;
    }
    if (!enabled || !NSApp.isActive) return e;
    // Option temporarily restores the game's unmodified input.
    if (e.modifierFlags & (NSEventModifierFlagOption | NSEventModifierFlagCommand |
                          NSEventModifierFlagControl)) { releaseAll(); return e; }
    NSWindow *w = e.window ?: NSApp.keyWindow;
    if (!w || !w.isKeyWindow || [w.firstResponder isKindOfClass:NSTextView.class]) return e;
    targetWindow = w;
    if (e.type == NSEventTypeMagnify) {
        double d = e.magnification;
        if (fabs(d) > 0.0001) pulse(d > 0 ? kVK_ANSI_Q : kVK_ANSI_E,
                                   d > 0 ? kVK_ANSI_E : kVK_ANSI_Q, fabs(d)*150);
        return nil;
    }
    if (e.type == NSEventTypeScrollWheel && e.hasPreciseScrollingDeltas) {
        double height=w.contentView.bounds.size.height;
        if (!panHandler(0,0,height)) { cancelPan(); return e; }
        queuePan(e.scrollingDeltaX,e.scrollingDeltaY,height);
        return nil;
    }
    return e;
}
#ifndef TRACKPAD_TEST
__attribute__((constructor)) static void initialize(void) {
    dispatch_async(dispatch_get_main_queue(), ^{
        monitor = [NSEvent addLocalMonitorForEventsMatchingMask:
            NSEventMaskMagnify | NSEventMaskScrollWheel | NSEventMaskKeyDown | NSEventMaskKeyUp
            handler:^NSEvent *(NSEvent *e) { return handle(e); }];
        resignObserver = [NSNotificationCenter.defaultCenter
            addObserverForName:NSApplicationWillResignActiveNotification object:nil queue:nil
            usingBlock:^(NSNotification *n) { releaseAll(); memset(physical, 0, sizeof physical); }];
        NSLog(@"[WorldBox Trackpad v2] loaded: pinch=Q/E, scroll=direct-camera, F8=toggle, Option=bypass");
    });
}
#endif
