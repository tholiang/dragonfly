#ifndef ComputePipelineGLFW_h
#define ComputePipelineGLFW_h

#include <stdio.h>
#include <vector>
#include <string>

#include <glad/glad.h>
#include <GLFW/glfw3.h>

#include "Utils/Vec.h"
using namespace Vec;

#include "ShaderProcessor.h"

#include "ComputePipeline.h"
#include "RenderPipelineGLFW.h"

class ComputePipelineGLFW : public ComputePipeline {
private:
    // glfw specifics
    
    // ---PIPELINE STATES FOR GPU COMPUTE KERNELS---
    ComputeShader *kernels[CPT_NUM_KERNELS];

    // ---BUFFERS FOR SCENE COMPUTE---
    // attribute data
    GLuint window_attributes_buffer;
    GLuint panel_info_buffer;
    // panel data
    GLuint panel_buffers[PNL_NUM_OUTBUFS];
    // compute data
    GLuint compute_buffers[CPT_NUM_OUTBUFS];

    void SetWindowAttributeBuffer(WindowAttributes w);
    void ResizePanelInfoBuffer(); // to gpu_panel_info_buffer_capacity
    void ModifyPanelInfoBuffer(Buffer *buf);
    void ResizePanelBuffer(unsigned long buf, BufferStorageMode storage_mode); // to gpu_compiled_panel_buffer_capacities
    void ModifyPanelBuffer(unsigned long buf, char *data, unsigned long start, unsigned long len);
    void ResizeComputeBuffer(unsigned long buf, BufferStorageMode storage_mode); // to gpu_compute_buffer_capacities
    
    /* Kernels */
    /*
     run a specified gpu kernel with N threads
     order buffers as:
     1. window attributes (always)
     2. panel info buffer (always)
     3. specified compute buffers
     4. specified compiled panel buffers
    */
    void RunKernel(unsigned long kernel, unsigned long N, vector<unsigned long> compute_bufs, vector<unsigned long> panel_bufs);
    void BeginCompute();
    void EndCompute();
public:
    ComputePipelineGLFW();
    ~ComputePipelineGLFW();
    void init();

    // pipeline
    void SendDataToRenderer(RenderPipeline *renderer);
    void SendDataToScheme();
};

#endif /* ComputePipelineGLFW_h */