#ifndef ComputePipelineGLFW_h
#define ComputePipelineGLFW_h

#include <stdio.h>
#include <vector>
#include <string>

#include "Utils/Vec.h"
using namespace Vec;

#import "ComputePipeline.h"
#import "RenderPipelineMetalSDL.h"

class ComputePipelineGLFW : public ComputePipeline {
private:
    // glfw specifics
    
    // ---PIPELINE STATES FOR GPU COMPUTE KERNELS---
    
    // ---BUFFERS FOR SCENE COMPUTE---
    // compute data
    
    // general scene data
    
    // model data (from both scene and controls models)
    
    // slice data
    
    // ui data
    
    // ---COMPILED BUFFERS TO SEND TO RENDERER---
public:
    ~ComputePipelineGLFW();
    void init();
    
    // call on start, when scheme changes, or when counts change
    // does not set any values, only creates buffers and sets size
    void CreateBuffers();
    
    // call when static data changes
    void ResetStaticBuffers();
    
    // call every frame
    void ResetDynamicBuffers();
    
    // pipeline
    void Compute();
    void SendDataToRenderer(RenderPipeline *renderer);
    void SendDataToScheme();
};

#endif /* ComputePipelineGLFW_h */