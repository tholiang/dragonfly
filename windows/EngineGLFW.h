#ifndef EngineGLFW_h
#define EngineGLFW_h

#include "Engine.h"

#include "imfilebrowser.h"

#include "Pipelines/ComputePipelineGLFW.h"
#include "Pipelines/RenderPipelineGLFW.h"

class EngineGLFW : public Engine {
private:
    // GLFW
    
    int SetPipelines();
    int HandleInputEvents();
public:
    EngineGLFW();
    ~EngineGLFW();
};

#endif /* EngineGLFW_h */