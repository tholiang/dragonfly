//
//  ComputePipeline.cpp
//  dragonfly
//
//  Created by Thomas Liang on 3/9/24.
//

#include <stdio.h>
#include <iostream>
#include "ComputePipeline.h"

ComputePipeline::~ComputePipeline() {
    
}

void ComputePipeline::SetBuffers(Window *w) {
    /* general buffers */
    WindowAttributes window_attr = w->GetAttributes();
    SetWindowAttributeBuffer(window_attr);
    
    if (w->IsPanelInfoBufferDirty()) {
        Buffer *panel_info_buffer = w->GetPanelInfoBuffer();
        if (gpu_panel_info_buffer_allotment != TotalBufferSize(panel_info_buffer)) {
            gpu_panel_info_buffer_allotment = TotalBufferSize(panel_info_buffer);
            ResizePanelInfoBuffer();
        }
        
        ModifyPanelInfoBuffer(w->GetPanelInfoBuffer());
        w->CleanPanelInfoBuffer();
    }
    
    
    /* compiled panel buffers */
    Buffer **window_bufs = w->GetCompiledPanelBuffers();
    
    for (int i = 0; i < PNL_NUM_OUTBUFS; i++) {
        if (!w->IsCompiledPanelBufferDirty(i)) { continue; }
        
        if (gpu_compiled_panel_buffer_allotments[i] != TotalBufferSize(window_bufs[i])) {
            gpu_compiled_panel_buffer_allotments[i] = TotalBufferSize(window_bufs[i]);
            ResizePanelBuffer(i);
        }
        
        ModifyPanelBuffer(i, window_bufs[i], 0, gpu_compiled_panel_buffer_allotments[i]);
        w->CleanCompiledPanelBuffer(i);
    }
    
    
    /* compute (output) buffers */
    Buffer **compute_bufs = w->GetComputeBuffers();
    
    for (int i = 0; i < CPT_NUM_OUTBUFS; i++) {
        if (gpu_compute_buffer_capacities[i] != TotalBufferSize(compute_bufs[i])) {
            gpu_compute_buffer_capacities[i] = TotalBufferSize(compute_bufs[i]);
            ResizeComputeBuffer(i);
        }
    }
}

void ComputePipeline::Compute(Window *w) {
    BeginCompute();
    
    /* call kernels */
    Buffer **panel_bufs = w->GetCompiledPanelBuffers();
    
    /* model rendering kernels */
    // calculate nodes (scene and control) in world space from model space
    unsigned long num_nodes = panel_bufs[PNL_NODE_OUTBUF_IDX]->size;
    RunKernel(
        CPT_TRANSFORMS_KRN_IDX,
        num_nodes,
        false,
        {},
        { PNL_NODE_OUTBUF_IDX, PNL_NODEMODELID_OUTBUF_IDX, PNL_MODELTRANS_OUTBUF_IDX }
    );
    
    // calculate vertices (scene and control) in world space from node-ish space
    unsigned long num_vertices = panel_bufs[PNL_NODEVERTEXLNK_OUTBUF_IDX]->size / 2;
    RunKernel(
        CPT_VERTEX_KRN_IDX,
        num_vertices,
        false,
        { CPT_COMPMODELVERTEX_OUTBUF_IDX },
        { PNL_NODEVERTEXLNK_OUTBUF_IDX, PNL_NODE_OUTBUF_IDX }
    );
    
    // calculate projected vertices from world space vertices
    RunKernel(
        CPT_PROJ_VERTEX_KRN_IDX,
        num_vertices,
        { CPT_COMPCOMPVERTEX_OUTBUF_IDX, CPT_COMPMODELVERTEX_OUTBUF_IDX },
        { PNL_CAMERA_OUTBUF_IDX }
    );
    
    // calculate vertex squares from projected vertices if needed
    // TODO: should_render
    RunKernel(
        CPT_VERTEX_SQR_KRN_IDX,
        num_vertices,
        { CPT_COMPCOMPVERTEX_OUTBUF_IDX, CPT_COMPCOMPFACE_OUTBUF_IDX },
        {}
    );
    
    // calculate projected scene nodes if needed
    // TODO: should_render
    RunKernel(
        CPT_PROJ_NODE_KRN_IDX,
        num_nodes,
        { CPT_COMPCOMPVERTEX_OUTBUF_IDX, CPT_COMPMODELVERTEX_OUTBUF_IDX },
        { PNL_NODE_OUTBUF_IDX, PNL_CAMERA_OUTBUF_IDX }
    );
    
    // if lighting is enabled calculate scene face lighting
    // TODO: lighting
    
    
    /* slice rendering kernels */
    // TODO: edit slice "scheme"
    
    // project dots
    unsigned long num_dots = panel_bufs[PNL_SLICEDOT_OUTBUF_IDX]->size;
    RunKernel(
        CPT_PROJ_DOT_KRN_IDX,
        num_dots,
        { CPT_COMPCOMPVERTEX_OUTBUF_IDX, CPT_COMPCOMPFACE_OUTBUF_IDX },
        { PNL_SLICEDOT_OUTBUF_IDX, PNL_SLICETRANS_OUTBUF_IDX, PNL_CAMERA_OUTBUF_IDX, PNL_DOTSLICEID_OUTBUF_IDX }
    );
    
    // make slice plates
    unsigned long num_slices = panel_bufs[PNL_SLICETRANS_OUTBUF_IDX]->size;
    RunKernel(
        CPT_SLICE_PLATE_KRN_IDX,
        num_slices,
        { CPT_COMPCOMPVERTEX_OUTBUF_IDX, CPT_COMPCOMPFACE_OUTBUF_IDX },
        { PNL_SLICETRANS_OUTBUF_IDX, PNL_SLICEATTR_OUTBUF_IDX, PNL_CAMERA_OUTBUF_IDX }
    );
    
    
    /* ui rendering kernels */
    // "project" ui vertices
    unsigned long num_ui_vertices = panel_bufs[PNL_UIVERTEX_OUTBUF_IDX]->size;
    RunKernel(
        CPT_UI_VERTEX_KRN_IDX,
        num_ui_vertices,
        { CPT_COMPCOMPVERTEX_OUTBUF_IDX },
        { PNL_UIVERTEX_OUTBUF_IDX, PNL_UIELEMID_OUTBUF_IDX, PNL_UITRANS_OUTBUF_IDX }
    );
    
    EndCompute();
}
