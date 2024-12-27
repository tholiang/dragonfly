//
//  ComputePipeline.m
//  dragonfly
//
//  Created by Thomas Liang on 7/5/22.
//

#import <Foundation/Foundation.h>
#include "ComputePipelineMetalSDL.h"
#include <iostream>

ComputePipelineMetalSDL::~ComputePipelineMetalSDL() {
    
}

id <MTLComputePipelineState> ComputePipelineMetalSDL::GetPipelineStateFromName(NSString* name) {
    return [device newComputePipelineStateWithFunction:[library newFunctionWithName:name] error:nil];
}

void ComputePipelineMetalSDL::init() {
    device = MTLCreateSystemDefaultDevice();
    command_queue = [device newCommandQueue];
    library = [device newDefaultLibrary];
    
    // init buffers
    window_attributes_buffer = nil;
    panel_info_buffer = nil;
    for (int i = 0; i < PNL_NUM_OUTBUFS; i++) { panel_buffers[i] = nil; }
    for (int i = 0; i < CPT_NUM_OUTBUFS; i++) { compute_buffers[i] = nil; }
    
    // create kernel pipelines and set them to set Metal kernels
    kernels[CPT_TRANSFORMS_KRN_IDX] = GetPipelineStateFromName(@"CalculateModelNodeTransforms");
    kernels[CPT_VERTEX_KRN_IDX] = GetPipelineStateFromName(@"CalculateVertices");
    kernels[CPT_PROJ_VERTEX_KRN_IDX] = GetPipelineStateFromName(@"CalculateProjectedVertices");
    kernels[CPT_VERTEX_SQR_KRN_IDX] = GetPipelineStateFromName(@"CalculateVertexSquares");
    kernels[CPT_SCALED_DOT_KRN_IDX] = GetPipelineStateFromName(@"CalculateScaledDots");
    kernels[CPT_PROJ_DOT_KRN_IDX] = GetPipelineStateFromName(@"CalculateProjectedDots");
    kernels[CPT_PROJ_NODE_KRN_IDX] = GetPipelineStateFromName(@"CalculateProjectedNodes");
    kernels[CPT_LIGHTING_KRN_IDX] = GetPipelineStateFromName(@"CalculateFaceLighting");
    kernels[CPT_SLICE_PLATE_KRN_IDX] = GetPipelineStateFromName(@"CalculateSlicePlates");
    kernels[CPT_UI_VERTEX_KRN_IDX] = GetPipelineStateFromName(@"CalculateUIVertices");
}

void ComputePipelineMetalSDL::SetWindowAttributeBuffer(WindowAttributes w) {
    if (window_attributes_buffer == nil) {
        window_attributes_buffer = [device newBufferWithLength:sizeof(w) options:MTLResourceStorageModeShared];
    }
    
    // add data to window attribute buffer
    *((WindowAttributes *)window_attributes_buffer.contents) = w;
    [window_attributes_buffer didModifyRange: NSMakeRange(0, sizeof(WindowAttributes))]; // alert gpu about what was modified
}

void ComputePipelineMetalSDL::ResizePanelBufferInfo() {
    panel_info_buffer = [device newBufferWithLength:gpu_panel_info_buffer_capacity options:MTLResourceStorageModeManaged];
}

void ComputePipelineMetalSDL::ModifyPanelBufferInfo(Buffer *data) {
    memcpy(panel_info_buffer.contents, (void *) data, gpu_panel_info_buffer_capacity);
    [panel_info_buffer didModifyRange: NSMakeRange(0, gpu_panel_info_buffer_capacity)]; // alert gpu about what was modified
}

void ComputePipelineMetalSDL::ResizePanelBuffer(unsigned long buf, BufferStorageMode storage_mode) {
    MTLResourceOptions options;
    if (storage_mode == Shared) { options = MTLResourceStorageModeShared; }
    else if (storage_mode == Managed) { options = MTLResourceStorageModeManaged; }
    panel_buffers[buf] = [device newBufferWithLength: gpu_compiled_panel_buffer_capacities[buf] options:options];
}

void ComputePipelineMetalSDL::ModifyPanelBuffer(unsigned long buf, char *data, unsigned long start, unsigned long len) {
    memcpy(panel_buffers[buf].contents, (void *) (data + start), len);
    [panel_buffers[buf] didModifyRange: NSMakeRange(start, len)]; // alert gpu about what was modified
}

void ComputePipelineMetalSDL::ResizeComputeBuffer(unsigned long buf, BufferStorageMode storage_mode) {
    MTLResourceOptions options;
    if (storage_mode == Shared) { options = MTLResourceStorageModeShared; }
    else if (storage_mode == Managed) { options = MTLResourceStorageModeManaged; }
    compute_buffers[buf] = [device newBufferWithLength: gpu_compute_buffer_capacities[buf] options:options];
}

void ComputePipelineMetalSDL::BeginCompute() {
    // TODO: MOVE THIS OUT?
    compute_command_buffer = [command_queue commandBuffer];
    compute_encoder = [compute_command_buffer computeCommandEncoder];
}

void ComputePipelineMetalSDL::EndCompute() {
    [compute_encoder endEncoding];
    
    // Synchronize the managed buffers for cpu (window)
    id <MTLBlitCommandEncoder> blit_command_encoder = [compute_command_buffer blitCommandEncoder];
    for (int i = 0; i < CPT_NUM_OUTBUFS; i++) {
        [blit_command_encoder synchronizeResource: compute_buffers[i]];
    }
    [blit_command_encoder endEncoding];
    
    [compute_command_buffer commit];
    [compute_command_buffer waitUntilCompleted];
}

void ComputePipelineMetalSDL::RunKernel(unsigned long kernel, unsigned long N, bool window_attr, vector<unsigned long> compute_bufs, vector<unsigned long> panel_bufs) {
    MTLSize gridsize;
    NSUInteger numthreads;
    MTLSize threadgroupsize;
    
    [compute_encoder setComputePipelineState: kernels[kernel]];
    // set buffers
    int cur_buf_idx = 0;
    if (window_attr) {
        [compute_encoder setBuffer: window_attributes_buffer offset:0 atIndex:0];
        cur_buf_idx++;
    }
    [compute_encoder setBuffer: panel_info_buffer offset:0 atIndex:1];
    cur_buf_idx++;
    for (int i = 0; i < compute_bufs.size(); i++) {
        [compute_encoder setBuffer: compute_buffers[compute_bufs[i]] offset:0 atIndex:cur_buf_idx];
        cur_buf_idx++;
    }
    for (int i = 0; i < panel_bufs.size(); i++) {
        [compute_encoder setBuffer: panel_buffers[panel_bufs[i]] offset:0 atIndex:cur_buf_idx];
        cur_buf_idx++;
    }
    
    // set thread size variables - per scene and control node
    gridsize = MTLSizeMake(N, 1, 1);
    numthreads = kernels[kernel].maxTotalThreadsPerThreadgroup;
    if (numthreads > N) numthreads = N;
    threadgroupsize = MTLSizeMake(numthreads, 1, 1);
    // execute
    [compute_encoder dispatchThreads:gridsize threadsPerThreadgroup:threadgroupsize];
}

void ComputePipelineMetalSDL::SendDataToRenderer(RenderPipeline *renderer) {
    RenderPipelineMetalSDL *renderer_metalsdl = (RenderPipelineMetalSDL *) renderer;
    
    for (int i = 0; i < CPT_NUM_OUTBUFS; i++) {
        renderer_metalsdl->SetBuffer(i, compute_buffers[i], gpu_compute_buffer_capacities[i]);
    }
}

void ComputePipelineMetalSDL::SendDataToWindow(Window *w) {
    char **win_compute_buffers = w->GetComputeBuffers();
    
    for (int i = 0; i < CPT_NUM_OUTBUFS; i++) {
        memcpy((void *) win_compute_buffers[i], compute_buffers[i].contents, gpu_compute_buffer_capacities[i]);
    }
}
