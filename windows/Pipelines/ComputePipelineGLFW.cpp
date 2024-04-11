#include "ComputePipelineGLFW.h"
#include <iostream>

ComputePipelineGLFW::ComputePipelineGLFW() {

}

ComputePipelineGLFW::~ComputePipelineGLFW() {

}

void ComputePipelineGLFW::init() {

}

void ComputePipelineGLFW::CreateBuffers() {

}

void ComputePipelineGLFW::ResetStaticBuffers() {

}

void ComputePipelineGLFW::ResetDynamicBuffers() {

}

void ComputePipelineGLFW::Compute() {

}

void ComputePipelineGLFW::SendDataToRenderer(RenderPipeline *renderer) {
    RenderPipelineGLFW *renderer_glfw = (RenderPipelineGLFW *) renderer;
    renderer_glfw->SetBuffers();
}

void ComputePipelineGLFW::SendDataToScheme() {

}