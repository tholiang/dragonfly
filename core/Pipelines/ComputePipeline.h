//
//  ComputePipeline.h
//  dragonfly
//
//  Created by Thomas Liang on 3/9/24.
//

#ifndef ComputePipeline_h
#define ComputePipeline_h

#include <stdio.h>
#include <vector>
#include <string>
#include <stdint.h>
using std::vector;

#include "Utils/Constants.h"
#include "Utils/Buffers.h"
using namespace DragonflyUtils;
#include "Utils/Vec.h"
using namespace Vec;

#include "../Panels/Window.h"
#include "RenderPipeline.h"

class ComputePipeline {
protected:
    enum BufferStorageMode {
        Shared,
        Managed
    };
    
    // child classes should contain an array of kernels
    
    // capacities of gpu buffers - in bytes!!
    unsigned long gpu_panel_info_buffer_capacity = 0;
    unsigned long gpu_compiled_panel_buffer_capacities[PNL_NUM_OUTBUFS];
    unsigned long gpu_compute_buffer_capacities[CPT_NUM_OUTBUFS];
    
    /* Buffers */
    virtual void SetWindowAttributeBuffer(WindowAttributes w) = 0;
    virtual void ResizePanelInfoBuffer();
    virtual void ModifyPanelInfoBuffer(Buffer *data) = 0;
    virtual void ResizePanelBuffer(unsigned long buf, BufferStorageMode storage_mode) = 0; // to gpu_compiled_panel_buffer_capacities
    virtual void ModifyPanelBuffer(unsigned long buf, char *data, unsigned long start, unsigned long len) = 0;
    virtual void ResizeComputeBuffer(unsigned long buf, BufferStorageMode storage_mode) = 0; // to gpu_compute_buffer_capacities
    
    /* Kernels */
    /*
     run a specified gpu kernel with N threads
     order buffers as:
     1. window attributes (if specified)
     2. panel info buffer (always)
     3. specified compute buffers
     4. specified compiled panel buffers
    */
    virtual void RunKernel(unsigned long kernel, unsigned long N, bool window_attr, vector<unsigned long> compute_bufs, vector<unsigned long> panel_bufs) = 0;
    virtual void BeginCompute() = 0;
    virtual void EndCompute() = 0;
public:
    virtual ~ComputePipeline();
    virtual void init() = 0;

    // get buffers from window
    void SetBuffers(Window *w);
    
    // pipeline
    void Compute(Window *w);
    virtual void SendDataToRenderer(RenderPipeline *renderer) = 0;
    virtual void SendDataToWindow(Window *w) = 0;
};

#endif /* ComputePipeline_h */
