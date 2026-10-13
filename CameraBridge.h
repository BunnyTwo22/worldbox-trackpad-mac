#import <Cocoa/Cocoa.h>
#include <dlfcn.h>
#include <math.h>

// Mono embedding entry points are resolved from the game's already loaded runtime.
// Metadata below was checked against the installed WorldBox 0.51.2 assembly.
typedef struct { float x,y,z; } WBVector3;
typedef struct { float x,y; } WBVector2;
static void *(*mdomain)(void);
static void (*assemblies)(void (*)(void *,void *),void *);
static void *(*assemblyImage)(void *);
static const char *(*imageName)(void *);
static void *(*klass)(void *,const char *,const char *);
static void *(*method)(void *,const char *,int);
static void *(*field)(void *,const char *);
static void *(*vtable)(void *,void *);
static void (*staticGet)(void *,void *,void *);
static void (*fieldGet)(void *,void *,void *);
static void (*fieldSet)(void *,void *,void *);
static void *(*invoke)(void *,void *,void **,void **);
static void *(*unbox)(void *);
static uint32_t (*pin)(void *,int);
static void (*unpin)(uint32_t);
static void *gameImage,*unityImage,*moveClass,*instanceField,*cameraField,*velocityField;
static void *getWorld,*overUI,*locked,*controlling,*ignoreTouch,*getTransform,*getPosition;
static void *setPosition,*getSize,*bounds,*clearFocus,*clearFocusUnit;
static BOOL bridgeReady,bridgeFailed;
static void findImage(void *a,void *unused) {
    void *i=assemblyImage(a); const char *n=imageName(i);
    if (!strcmp(n,"Assembly-CSharp")) gameImage=i;
    if (!strcmp(n,"UnityEngine.CoreModule")) unityImage=i;
}
static BOOL bindCamera(void) {
    if (bridgeReady || bridgeFailed) return bridgeReady;
    NSString *version=[NSBundle.mainBundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    if (![version isEqualToString:@"0.51.2"]) { bridgeFailed=YES; return NO; }
#define LOAD(dst,name) do { *(void **)(&dst)=dlsym(RTLD_DEFAULT,name); if (!dst) return NO; } while(0)
    LOAD(mdomain,"mono_domain_get"); LOAD(assemblies,"mono_assembly_foreach");
    LOAD(assemblyImage,"mono_assembly_get_image"); LOAD(imageName,"mono_image_get_name");
    LOAD(klass,"mono_class_from_name"); LOAD(method,"mono_class_get_method_from_name");
    LOAD(field,"mono_class_get_field_from_name"); LOAD(vtable,"mono_class_vtable");
    LOAD(staticGet,"mono_field_static_get_value"); LOAD(fieldGet,"mono_field_get_value");
    LOAD(fieldSet,"mono_field_set_value"); LOAD(invoke,"mono_runtime_invoke");
    LOAD(unbox,"mono_object_unbox"); LOAD(pin,"mono_gchandle_new"); LOAD(unpin,"mono_gchandle_free");
#undef LOAD
    if (!mdomain()) return NO;
    assemblies(findImage,NULL); if (!gameImage || !unityImage) return NO;
    moveClass=klass(gameImage,"","MoveCamera");
    void *world=klass(gameImage,"","World"),*map=klass(gameImage,"","MapBox");
    void *component=klass(unityImage,"UnityEngine","Component");
    void *transform=klass(unityImage,"UnityEngine","Transform");
    void *camera=klass(unityImage,"UnityEngine","Camera");
    if (!moveClass || !world || !map || !component || !transform || !camera) goto failed;
    instanceField=field(moveClass,"instance"); cameraField=field(moveClass,"main_camera");
    velocityField=field(moveClass,"_move_velocity");
    getWorld=method(world,"get_world",0); overUI=method(map,"isOverUI",0);
    locked=method(map,"isGameplayControlsLocked",0); controlling=method(map,"isControllingUnit",0);
    ignoreTouch=method(moveClass,"ignoreTouchControls",0);
    getTransform=method(component,"get_transform",0); getPosition=method(transform,"get_position",0);
    setPosition=method(transform,"set_position",1); getSize=method(camera,"get_orthographicSize",0);
    bounds=method(moveClass,"cameraToBounds",0); clearFocus=method(moveClass,"clearFocus",0);
    clearFocusUnit=method(moveClass,"clearFocusUnitOnly",0);
    if (!instanceField || !cameraField || !velocityField || !getWorld || !overUI || !locked ||
        !controlling || !ignoreTouch || !getTransform || !getPosition || !setPosition ||
        !getSize || !bounds || !clearFocus || !clearFocusUnit) goto failed;
    bridgeReady=YES; NSLog(@"[WorldBox Trackpad v2] direct camera bridge ready"); return YES;
failed:
    bridgeFailed=YES; NSLog(@"[WorldBox Trackpad v2] incompatible camera metadata; pan disabled"); return NO;
}
static void *callManaged(void *m,void *o,void **args,BOOL *ok) {
    if (!*ok) return NULL;
    void *exception=NULL,*result=invoke(m,o,args,&exception);
    if (exception) {
        *ok=NO; bridgeFailed=YES; bridgeReady=NO;
        NSLog(@"[WorldBox Trackpad v2] managed call failed; pan disabled");
    }
    return result;
}
static BOOL boolManaged(void *m,void *o,BOOL *ok) {
    void *r=callManaged(m,o,NULL,ok);
    return !*ok || !r || *(uint8_t *)unbox(r)!=0;
}
static WBVector3 offsetPosition(WBVector3 p,double dx,double dy,float size,double height) {
    // Native Cocoa scroll deltas: +X moves visible content right; +Y moves it down.
    // Unity world Y points up. Preserve macOS's natural-scroll preference as Miro does.
    double units=2.0*size/height;
    p.x-=dx*units; p.y+=dy*units;
    return p;
}
// Returns NO over game UI so its ordinary scrolling remains available.
static BOOL panCamera(double dx,double dy,double height) {
    if (height<=0 || !isfinite(dx) || !isfinite(dy) || !bindCamera()) return NO;
    BOOL ok=YES,handled=NO; uint32_t roots[4]={0};
    void *w=callManaged(getWorld,NULL,NULL,&ok); if (!w || !ok) return NO;
    roots[0]=pin(w,1);
    if (boolManaged(overUI,w,&ok) || boolManaged(locked,w,&ok) || boolManaged(controlling,NULL,&ok)) goto done;
    void *mc=NULL; staticGet(vtable(mdomain(),moveClass),instanceField,&mc); if (!mc) goto done;
    roots[1]=pin(mc,1);
    if (boolManaged(ignoreTouch,mc,&ok)) goto done;
    if (dx==0 && dy==0) { handled=YES; goto done; }
    void *cam=NULL; fieldGet(mc,cameraField,&cam); if (!cam) goto done;
    roots[2]=pin(cam,1);
    void *r=callManaged(getSize,cam,NULL,&ok); if (!r || !ok) goto done;
    float size=*(float *)unbox(r); if (!isfinite(size) || size<=0) goto done;
    void *tr=callManaged(getTransform,mc,NULL,&ok); if (!tr || !ok) goto done;
    roots[3]=pin(tr,1);
    r=callManaged(getPosition,tr,NULL,&ok); if (!r || !ok) goto done;
    WBVector3 p=offsetPosition(*(WBVector3 *)unbox(r),dx,dy,size,height);
    WBVector2 zero={0,0}; fieldSet(mc,velocityField,&zero);
    callManaged(clearFocus,mc,NULL,&ok); callManaged(clearFocusUnit,NULL,NULL,&ok);
    void *args[]={&p}; callManaged(setPosition,tr,args,&ok);
    callManaged(bounds,mc,NULL,&ok); handled=ok;
done:
    for (int i=3;i>=0;i--) if (roots[i]) unpin(roots[i]);
    return handled;
}
