#ifndef RenderPipelineGLFW_h
#define RenderPipelineGLFW_h

#include <stdio.h>
#include <vector>
#include <string>

#include "Utils/Vec.h"

#include "imgui.h"
#include <SDL.h>

#include "RenderPipeline.h"
#include "../Schemes/Scheme.h"
#include "../Schemes/SchemeController.h"

class RenderPipelineGLFW : public RenderPipeline {
private:
    // rendering specifics
    
    // ---PIPELINE STATES FOR GPU RENDERER---

    // depth variables for renderer
    
    // ---BUFFERS FOR SCENE RENDER---
public:
    ~RenderPipelineGLFW();
    
    int init();
    void SetBuffers();
    
    void SetPipeline();
    
    void Render();
};

#endif /* RenderPipelineGLFW_h */
