//
//  ComputePipeline_MetalSDL.h
//  dragonfly
//
//  Created by Thomas Liang on 7/5/22.
//

#ifndef ComputePipelineMetalSDL_h
#define ComputePipelineMetalSDL_h

#include <stdio.h>
#include <vector>
#include <string>
using std::string;

#include "Utils/Vec.h"
using namespace Vec;

#import <Metal/Metal.h>
#import <QuartzCore/QuartzCore.h>

#import "ComputePipeline.h"
#import "RenderPipelineMetalSDL.h"

class ComputePipelineMetalSDL : public ComputePipeline {
private:
    /* metal specifics */
    id <MTLDevice> device;
    id <MTLCommandQueue> command_queue;
    id <MTLLibrary> library;
    
    id <MTLCommandBuffer> compute_command_buffer;
    id <MTLComputeCommandEncoder> compute_encoder;
    
    /* ---PIPELINE STATES FOR GPU COMPUTE KERNELS--- */
    id <MTLComputePipelineState> kernels[CPT_NUM_KERNELS];
    
    /* ---BUFFERS FOR SCENE COMPUTE--- */
    // attribute data
    id <MTLBuffer> window_attributes_buffer;
    id <MTLBuffer> panel_info_buffer;
    // panel data
    id <MTLBuffer> panel_buffers[PNL_NUM_OUTBUFS];
    // compute data
    id <MTLBuffer> compute_buffers[CPT_NUM_OUTBUFS];
    
    void SetWindowAttributeBuffer(WindowAttributes w);
    void ResizePanelInfoBuffer(); // to gpu_panel_info_buffer_capacity
    void ModifyPanelInfoBuffer(Buffer *buf);
    void ResizePanelBuffer(unsigned long buf, BufferStorageMode storage_mode); // to gpu_compiled_panel_buffer_capacities
    void ModifyPanelBuffer(unsigned long buf, char *data, unsigned long start, unsigned long len);
    void ResizeComputeBuffer(unsigned long buf, BufferStorageMode storage_mode); // to gpu_compute_buffer_capacities
    
    /* Kernels */
    id <MTLComputePipelineState> GetPipelineStateFromName(NSString* name);
    /*
     run a specified gpu kernel with N threads
     order buffers as:
     1. window attributes (if specified)
     2. panel info buffer (always)
     3. specified compute buffers
     4. specified compiled panel buffers
    */
    void RunKernel(unsigned long kernel, unsigned long N, bool window_attr, vector<unsigned long> compute_bufs, vector<unsigned long> panel_bufs);
    void BeginCompute();
    void EndCompute();
public:
    ~ComputePipelineMetalSDL();
    void init();
    
    // pipeline
    void SendDataToRenderer(RenderPipeline *renderer);
    void SendDataToWindow(Window *w);
};

#endif /* ComputePipelineMetalSDL_h */
