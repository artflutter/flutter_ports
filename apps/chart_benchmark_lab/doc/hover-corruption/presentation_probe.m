// Diagnostic only: private engine method interception, never production code.
// Copyright (c) 2026 Vasiliy Ditsyak. SPDX-License-Identifier: MIT
#import <Foundation/Foundation.h>
#import <Metal/Metal.h>
#import <objc/runtime.h>
#include <stdatomic.h>
#include <execinfo.h>

static _Thread_local BOOL inPresent = NO;
static NSMutableArray<id<MTLCommandBuffer>>* fences;
static unsigned int peak;
static unsigned int calls;
static NSString* mode;
static NSMapTable<id<MTLBuffer>,id<MTLCommandBuffer>>* lastUse;
static NSMutableSet<id<MTLBuffer>>* touched;
static unsigned int hazards;
static NSThread* raster;


__attribute__((constructor)) static void installPresentProbe(void) {
 @autoreleasepool {
  Class surface = NSClassFromString(@"FlutterSurfaceManager");
  SEL present = NSSelectorFromString(@"presentSurfaces:atTime:notify:");
  Method pmethod = class_getInstanceMethod(surface,present);
  if (!pmethod) { fprintf(stderr,"PRESENT_PROBE missing surface method\n");return; }
  IMP originalPresent = method_getImplementation(pmethod);
  IMP presentHook = imp_implementationWithBlock(^(id self,id surfaces,double time,dispatch_block_t notify){
   if (!raster) raster=NSThread.currentThread;
   inPresent=YES;
   ((void(*)(id,SEL,id,double,dispatch_block_t))originalPresent)(self,present,surfaces,time,notify);
   inPresent=NO;
  });
  class_replaceMethod(surface,present,presentHook,method_getTypeEncoding(pmethod));
  id<MTLDevice> device=MTLCreateSystemDefaultDevice();
  id<MTLCommandQueue> queue=[device newCommandQueue];
  id<MTLCommandBuffer> cb=[queue commandBuffer];
  Class cls=object_getClass(cb);
  Method wmethod=class_getInstanceMethod(cls,@selector(waitUntilScheduled));
  IMP originalWait=method_getImplementation(wmethod);
  lastUse=[NSMapTable weakToStrongObjectsMapTable];touched=[NSMutableSet set];
  id<MTLBuffer> testBuffer=[device newBufferWithLength:1024000 options:MTLResourceStorageModeShared];
  Class bufferClass=object_getClass(testBuffer);
  Method cmethod=class_getInstanceMethod(bufferClass,@selector(contents));
  IMP originalContents=method_getImplementation(cmethod);
  IMP contentsHook=imp_implementationWithBlock(^void*(id<MTLBuffer> self){
   if(raster==NSThread.currentThread && self.length==1024000){
    id<MTLCommandBuffer> previous=[lastUse objectForKey:self];
    if(previous && previous.status<MTLCommandBufferStatusCompleted && hazards<5){
     hazards++;fprintf(stderr,"BUFFER_REUSE_HAZARD %u buffer=%p previous frame fence status=%lu (completed=4) presentCount=%u\n",hazards,(__bridge void*)self,(unsigned long)previous.status,calls);
     void* stack[12];int n=backtrace(stack,12);backtrace_symbols_fd(stack,n,2);
    }
    [touched addObject:self];
   }
   return ((void*(*)(id,SEL))originalContents)(self,@selector(contents));
  });
  class_replaceMethod(bufferClass,@selector(contents),contentsHook,method_getTypeEncoding(cmethod));
  fences=[NSMutableArray array];mode=[NSProcessInfo.processInfo.environment objectForKey:@"PRESENT_MODE"] ?: @"observe";
  IMP hook=imp_implementationWithBlock(^(id<MTLCommandBuffer> self){
   if(!inPresent){((void(*)(id,SEL))originalWait)(self,@selector(waitUntilScheduled));return;}
   if([mode isEqualToString:@"complete"]){[self waitUntilCompleted];}
   else {((void(*)(id,SEL))originalWait)(self,@selector(waitUntilScheduled));}
   while(fences.count && fences.firstObject.status>=MTLCommandBufferStatusCompleted)[fences removeObjectAtIndex:0];
   [fences addObject:self]; calls++;
   for(id<MTLBuffer> buffer in touched) [lastUse setObject:self forKey:buffer];
   [touched removeAllObjects];
   if(fences.count>peak){peak=(unsigned int)fences.count;fprintf(stderr,"PRESENT_PROBE outstanding frame fences=%u at present=%u mode=%s\n",peak,calls,mode.UTF8String);}
   if([mode isEqualToString:@"bounded"] && fences.count>=3){
    [fences.firstObject waitUntilCompleted];[fences removeObjectAtIndex:0];
   }
  });
  class_replaceMethod(cls,@selector(waitUntilScheduled),hook,method_getTypeEncoding(wmethod));
  fprintf(stderr,"PRESENT_PROBE installed on FlutterSurfaceManager and %s, mode=%s\n",class_getName(cls),mode.UTF8String);
 }
}
