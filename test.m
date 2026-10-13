#define TRACKPAD_TEST
#import "Trackpad.m"
#include <assert.h>
static NSMutableArray<NSEvent *> *sent;
static BOOL allowPan=YES;
static double lastX,lastY;
static unsigned panCalls;
static BOOL fakePan(double x,double y,double height) {
    if (!allowPan) return NO;
    if (x || y) { lastX=x; lastY=y; panCalls++; }
    return YES;
}
@interface TestApp : NSApplication @end
@implementation TestApp
- (BOOL)isActive { return YES; }
- (void)sendEvent:(NSEvent *)e { [sent addObject:e]; }
@end
@interface TestWindow : NSWindow @end
@implementation TestWindow
- (BOOL)isKeyWindow { return YES; }
@end
@interface Gesture : NSEvent
@property NSEventType kind;
@property CGFloat dx, dy, mag;
@property BOOL precise, inverted;
@property NSEventModifierFlags flags;
@property NSWindow *testWindow;
@end
@implementation Gesture
- (NSEventType)type { return self.kind; }
- (CGFloat)scrollingDeltaX { return self.dx; }
- (CGFloat)scrollingDeltaY { return self.dy; }
- (CGFloat)magnification { return self.mag; }
- (BOOL)hasPreciseScrollingDeltas { return self.precise; }
- (BOOL)isDirectionInvertedFromDevice { return self.inverted; }
- (NSEventModifierFlags)modifierFlags { return self.flags; }
- (NSWindow *)window { return self.testWindow; }
@end
int main(void) { @autoreleasepool {
    [TestApp sharedApplication]; sent = [NSMutableArray array]; panHandler=fakePan;
    TestWindow *w = [[TestWindow alloc] initWithContentRect:NSMakeRect(0,0,100,100)
        styleMask:NSWindowStyleMaskBorderless backing:NSBackingStoreBuffered defer:YES];
    Gesture *e = [Gesture new]; e.testWindow=w;
    e.kind=NSEventTypeMagnify; e.mag=0.05;
    assert(handle(e)==nil && held[kVK_ANSI_Q]);
    assert(sent.lastObject.keyCode==kVK_ANSI_Q && sent.lastObject.type==NSEventTypeKeyDown);
    e.mag=-0.05; handle(e);
    assert(!held[kVK_ANSI_Q] && held[kVK_ANSI_E]);
    releaseAll(); assert(sent.lastObject.type==NSEventTypeKeyUp);
    assert(timer==nil); // No recurring background timer when input is idle.
    e.kind=NSEventTypeScrollWheel; e.precise=YES; e.inverted=YES; e.dx=4; e.dy=-4;
    NSUInteger keyCount=sent.count;
    assert(handle(e)==nil); handle(e); flushPan();
    assert(lastX==8 && lastY==-8 && panCalls==1 && sent.count==keyCount);
    e.inverted=NO; handle(e); flushPan();
    assert(lastX==4 && lastY==-4); // OS-provided direction is never flipped twice.
    WBVector3 p={100,100,-0.5};
    p=offsetPosition(p,10,20,50,100);
    assert(p.x==90 && p.y==120 && p.z==-0.5); // Content right/down => camera left/up.
    p=offsetPosition(p,-10,-20,50,100);
    assert(p.x==100 && p.y==100);
    p=offsetPosition(p,10,20,25,100);
    assert(p.x==95 && p.y==110); // Same on-screen travel at different zoom levels.
    handle(e); unsigned calls=panCalls;
    e.flags=NSEventModifierFlagOption;
    assert(handle(e)==e); flushPan(); assert(panCalls==calls);
    e.flags=0; allowPan=NO; assert(handle(e)==e); allowPan=YES;
    e.precise=NO; assert(handle(e)==e);
    enabled=NO; e.precise=YES; assert(handle(e)==e); enabled=YES;
    physical[kVK_ANSI_Q]=YES; e.kind=NSEventTypeMagnify; e.mag=0.05;
    keyCount=sent.count; handle(e); assert(sent.count==keyCount);
    physical[kVK_ANSI_Q]=NO; releaseAll(); assert(timer==nil && !panScheduled);
    puts("PASS: pinch regression; proportional pan at two zoom levels; coordinate axes; OS direction preservation; event coalescing; UI/Option bypass; mouse passthrough; physical key protection; no idle timer");
} return 0; }
