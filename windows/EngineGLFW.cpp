#include "EngineGLFW.h"

EngineGLFW::EngineGLFW() {
}

EngineGLFW::~EngineGLFW() {
    delete compute_pipeline;
    delete render_pipeline;
    
    delete camera;
    delete scene;
    delete scheme;
    delete scheme_controller;
}

int EngineGLFW::SetPipelines() {
    compute_pipeline = new ComputePipelineGLFW();
    compute_pipeline->init();
    compute_pipeline->SetScheme(scheme);
    
    render_pipeline = new RenderPipelineGLFW();
    window_id = render_pipeline->init();
    if (window_id < 0) {
        return 1;
    }
    render_pipeline->SetScheme(scheme);
    render_pipeline->SetSchemeController(scheme_controller);
    
    compute_pipeline->CreateBuffers();
    compute_pipeline->ResetStaticBuffers();
    
    return 0;
}

int EngineGLFW::HandleInputEvents() {
    return 0;
}