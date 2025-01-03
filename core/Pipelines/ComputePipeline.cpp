//
//  ComputePipeline.cpp
//  dragonfly
//
//  Created by Thomas Liang on 3/9/24.
//

#include <stdio.h>
#include <iostream>
#include "ComputePipeline.h"

ComputePipeline::ComputePipeline() {
    for (int i = 0; i < PNL_NUM_OUTBUFS; i++) {
        gpu_compiled_panel_buffer_allotments[i] = 0;
    }
    
    for (int i = 0; i < CPT_NUM_OUTBUFS; i++) {
        gpu_compute_buffer_allotments[i] = 0;
    }
}

ComputePipeline::~ComputePipeline() {
    
}

void ComputePipeline::SetBuffers(Window *w) {
    /* general buffers */
    WindowAttributes window_attr = w->GetAttributes();
    SetWindowAttributeBuffer(window_attr);
    
    if (w->IsPanelBufferInfoDirty()) {
        Buffer *panel_info_buffer = w->GetPanelBufferInfo();
        if (gpu_panel_info_buffer_allotment != TotalBufferSize(panel_info_buffer)) {
            gpu_panel_info_buffer_allotment = TotalBufferSize(panel_info_buffer);
            ResizePanelBufferInfo();
        }
        
        ModifyPanelBufferInfo(w->GetPanelBufferInfo());
        w->CleanPanelBufferInfo();
    }
    
    
    /* compiled panel buffers */
    Buffer **window_bufs = w->GetCompiledPanelBuffers();
    
    for (int i = 0; i < PNL_NUM_OUTBUFS; i++) {
        if (!w->IsCompiledPanelBufferDirty(i)) { continue; }
        
        if (gpu_compiled_panel_buffer_allotments[i] != TotalBufferSize(window_bufs[i])) {
            gpu_compiled_panel_buffer_allotments[i] = TotalBufferSize(window_bufs[i]);
            ResizePanelBuffer(i, PNL_OUTBUF_STORAGE_MODES[i]);
        }
        
        ModifyPanelBuffer(i, window_bufs[i], 0, gpu_compiled_panel_buffer_allotments[i]);
        w->CleanCompiledPanelBuffer(i);
    }
    
    
    /* compute (output) buffers */
    Buffer **compute_bufs = w->GetComputeBuffers();
    for (int i = 0; i < CPT_NUM_OUTBUFS; i++) {
        if (!w->IsComputeBufferDirty(i)) { continue; }
        
        if (gpu_compute_buffer_allotments[i] != TotalBufferSize(compute_bufs[i])) {
            gpu_compute_buffer_allotments[i] = TotalBufferSize(compute_bufs[i]);
            ResizeComputeBuffer(i, CPT_OUTBUF_STORAGE_MODES[i]);
        }
        
        ModifyComputeBuffer(i, compute_bufs[i], 0, gpu_compute_buffer_allotments[i]);
        w->CleanComputeBuffer(i);
    }
}

void ComputePipeline::Compute(Window *w) {
    BeginCompute();
    
    /* call kernels */
    unsigned long *kernel_counts = w->GetKernelCounts();
    
    /* model rendering kernels */
    // calculate nodes (scene and control) in world space from model space
    RunKernel(
        CPT_TRANSFORMS_KRN_IDX,
        kernel_counts[CPT_TRANSFORMS_KRN_IDX],
        false,
        { CPT_COMPMODELNODE_OUTBUF_IDX },
        { PNL_NODE_OUTBUF_IDX, PNL_NODEMODELID_OUTBUF_IDX, PNL_MODELTRANS_OUTBUF_IDX }
    );
    
    // calculate vertices (scene and control) in world space from node-ish space
    RunKernel(
        CPT_VERTEX_KRN_IDX,
        kernel_counts[CPT_VERTEX_KRN_IDX],
        false,
        { CPT_COMPMODELVERTEX_OUTBUF_IDX },
        { PNL_NODEVERTEXLNK_OUTBUF_IDX, PNL_NODE_OUTBUF_IDX }
    );
    
    // calculate projected vertices from world space vertices
    RunKernel(
        CPT_PROJ_VERTEX_KRN_IDX,
        kernel_counts[CPT_PROJ_VERTEX_KRN_IDX],
        false,
        { CPT_COMPCOMPVERTEX_OUTBUF_IDX, CPT_COMPMODELVERTEX_OUTBUF_IDX },
        { PNL_CAMERA_OUTBUF_IDX }
    );
    
    // calculate vertex squares from projected vertices if needed
    RunKernel(
        CPT_VERTEX_SQR_KRN_IDX,
        kernel_counts[CPT_VERTEX_SQR_KRN_IDX],
        true,
        { CPT_COMPCOMPVERTEX_OUTBUF_IDX, CPT_COMPCOMPFACE_OUTBUF_IDX },
        {}
    );
    
    // calculate projected scene nodes if needed
//    RunKernel(
//        CPT_PROJ_NODE_KRN_IDX,
//        num_nodes,
//        true,
//        { CPT_COMPCOMPVERTEX_OUTBUF_IDX, CPT_COMPMODELVERTEX_OUTBUF_IDX },
//        { PNL_NODE_OUTBUF_IDX, PNL_CAMERA_OUTBUF_IDX }
//    );
    
    // if lighting is enabled calculate scene face lighting
    // TODO: lighting
    
    
    /* slice rendering kernels */
    // TODO: edit slice "scheme"
    
    // project dots
//    unsigned long num_dots = panel_bufs[PNL_SLICEDOT_OUTBUF_IDX]->size / sizeof(Dot);
//    RunKernel(
//        CPT_PROJ_DOT_KRN_IDX,
//        num_dots,
//        true,
//        { CPT_COMPCOMPVERTEX_OUTBUF_IDX, CPT_COMPCOMPFACE_OUTBUF_IDX },
//        { PNL_SLICEDOT_OUTBUF_IDX, PNL_SLICETRANS_OUTBUF_IDX, PNL_CAMERA_OUTBUF_IDX, PNL_DOTSLICEID_OUTBUF_IDX }
//    );
    
    // make slice plates
//    unsigned long num_slices = panel_bufs[PNL_SLICETRANS_OUTBUF_IDX]->size / sizeof(ModelTransform);
//    RunKernel(
//        CPT_SLICE_PLATE_KRN_IDX,
//        num_slices,
//        false,
//        { CPT_COMPCOMPVERTEX_OUTBUF_IDX, CPT_COMPCOMPFACE_OUTBUF_IDX },
//        { PNL_SLICETRANS_OUTBUF_IDX, PNL_SLICEATTR_OUTBUF_IDX, PNL_CAMERA_OUTBUF_IDX }
//    );
    
    
    /* ui rendering kernels */
    // "project" ui vertices
    RunKernel(
        CPT_UI_VERTEX_KRN_IDX,
        kernel_counts[CPT_UI_VERTEX_KRN_IDX],
        true,
        { CPT_COMPCOMPVERTEX_OUTBUF_IDX },
        { PNL_UIVERTEX_OUTBUF_IDX, PNL_UIELEMID_OUTBUF_IDX, PNL_UITRANS_OUTBUF_IDX }
    );
    
    EndCompute();
}
