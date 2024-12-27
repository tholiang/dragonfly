#include "ComputePipelineGLFW.h"
#include <iostream>
#include <cmath>

ComputePipelineGLFW::ComputePipelineGLFW() {
    for (int i = 0; i < CPT_NUM_KERNELS; i++) {
        kernels[i] = NULL;
    }
}

ComputePipelineGLFW::~ComputePipelineGLFW() {

}

void ComputePipelineGLFW::init() {
    // init buffers
    glGenBuffers(1, &window_attributes_buffer);
    glGenBuffers(1, &panel_info_buffer);
    for (int i = 0; i < PNL_NUM_OUTBUFS; i++) { glGenBuffers(1, &panel_buffers[i]); }
    for (int i = 0; i < CPT_NUM_OUTBUFS; i++) { glGenBuffers(1, &compute_buffers[i]); }
    
    // create compute shader objects
    kernels[CPT_TRANSFORMS_KRN_IDX] = new ComputeShader("Processing/Compute/CalculateModelNodeTransforms.comp", "Processing/util.glsl");
    kernels[CPT_VERTEX_KRN_IDX] = new ComputeShader("Processing/Compute/CalculateVertices.comp", "Processing/util.glsl");
    kernels[CPT_PROJ_VERTEX_KRN_IDX] = new ComputeShader("Processing/Compute/CalculateProjectedVertices.comp", "Processing/util.glsl");
    kernels[CPT_VERTEX_SQR_KRN_IDX] = new ComputeShader("Processing/Compute/CalculateVertexSquares.comp", "Processing/util.glsl");
    kernels[CPT_SCALED_DOT_KRN_IDX] = new ComputeShader("Processing/Compute/CalculateScaledDots.comp", "Processing/util.glsl");
    kernels[CPT_PROJ_DOT_KRN_IDX] = new ComputeShader("Processing/Compute/CalculateProjectedDots.comp", "Processing/util.glsl");
    kernels[CPT_PROJ_NODE_KRN_IDX] = new ComputeShader("Processing/Compute/CalculateProjectedNodes.comp", "Processing/util.glsl");
    kernels[CPT_LIGHTING_KRN_IDX] = new ComputeShader("Processing/Compute/CalculateFaceLighting.comp", "Processing/util.glsl");
    kernels[CPT_SLICE_PLATE_KRN_IDX] = new ComputeShader("Processing/Compute/CalculateSlicePlates.comp", "Processing/util.glsl");
    kernels[CPT_UI_VERTEX_KRN_IDX] = new ComputeShader("Processing/Compute/CalculateUIVertices.comp", "Processing/util.glsl");
}

void ComputePipelineGLFW::SetWindowAttributeBuffer(WindowAttributes w) {
    glBindBuffer(GL_SHADER_STORAGE_BUFFER, window_attributes_buffer);
    glBufferData(GL_SHADER_STORAGE_BUFFER, sizeof(WindowAttributes), &w, GL_STATIC_DRAW);
}

void ComputePipelineGLFW::ResizePanelBufferInfo() {
    glBindBuffer(GL_SHADER_STORAGE_BUFFER, panel_info_buffer);
    glBufferData(GL_SHADER_STORAGE_BUFFER, gpu_panel_info_buffer_allotment, NULL, GL_STATIC_DRAW);
}

void ComputePipelineGLFW::ModifyPanelBufferInfo(Buffer *data) {
    glNamedBufferSubData (panel_info_buffer, 0, gpu_panel_info_buffer_allotment, data);
}

void ComputePipelineGLFW::ResizePanelBuffer(unsigned long buf, BufferStorageMode storage_mode) {
    GLenum options;
    if (storage_mode == Shared) { options = GL_DYNAMIC_DRAW; }
    else if (storage_mode == Managed) { options = GL_STATIC_DRAW; }
    glBindBuffer(GL_SHADER_STORAGE_BUFFER, panel_buffers[buf]);
    glBufferData(GL_SHADER_STORAGE_BUFFER, gpu_compiled_panel_buffer_allotments[buf], NULL, options);
}

void ComputePipelineGLFW::ModifyPanelBuffer(unsigned long buf, char *data, unsigned long start, unsigned long len) {
    glNamedBufferSubData (panel_buffers[buf], start, len, data);
}

void ComputePipelineGLFW::ResizeComputeBuffer(unsigned long buf, BufferStorageMode storage_mode) {
    GLenum options;
    if (storage_mode == Shared) { options = GL_DYNAMIC_READ; }
    else if (storage_mode == Managed) { options = GL_STATIC_READ; }
    glBindBuffer(GL_SHADER_STORAGE_BUFFER, compute_buffers[buf]);
    glBufferData(GL_SHADER_STORAGE_BUFFER, gpu_compiled_panel_buffer_allotments[buf], NULL, options);
}

void ComputePipelineGLFW::BeginCompute() {

}

void ComputePipelineGLFW::EndCompute() {
    // Synchronize the managed buffers for scheme
    glMemoryBarrier(GL_ALL_BARRIER_BITS);
}

void ComputePipelineGLFW::RunKernel(unsigned long kernel, unsigned long N, vector<unsigned long> compute_bufs, vector<unsigned long> panel_bufs) {
    glUseProgram(kernels[kernel]);
    // set buffers
    glBindBufferBase(GL_SHADER_STORAGE_BUFFER, 1, window_attributes_buffer);
    glBindBufferBase(GL_SHADER_STORAGE_BUFFER, 2, panel_info_buffer);
    int cur_buf_idx = 3;
    for (int i = 0; i < compute_bufs.size(); i++) {
        glBindBufferBase(GL_SHADER_STORAGE_BUFFER, cur_buf_idx, compute_buffers[compute_bufs[i]]);
        cur_buf_idx++;
    }
    for (int i = 0; i < panel_bufs.size(); i++) {
        glBindBufferBase(GL_SHADER_STORAGE_BUFFER, cur_buf_idx, panel_buffers[panel_bufs[i]]);
        cur_buf_idx++;
    }

    glDispatchCompute( std::ceil(((float) N)/128), 1, 1 );

    // TODO: probably don't do this every time
    // memory barrier for transforms
    glMemoryBarrier(GL_ALL_BARRIER_BITS);
}

void ComputePipelineGLFW::SendDataToRenderer(RenderPipeline *renderer) {
    RenderPipelineGLFW *renderer_glfw = (RenderPipelineGLFW *) renderer;
    
}

void ComputePipelineGLFW::SendDataToWindow(Window *w) {
    char **win_compute_buffers = w->GetComputeBuffers();
    
    for (int i = 0; i < CPT_NUM_OUTBUFS; i++) {
        glGetNamedBufferSubData (compute_buffers[i], 0, gpu_compute_buffer_capacities[i], win_compute_buffers[i]);
    }
}
