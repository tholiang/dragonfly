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

#include <simd/SIMD.h>

#import <Metal/Metal.h>
#import <QuartzCore/QuartzCore.h>

#import "ComputePipeline.h"
#import "RenderPipelineMetalSDL.h"

class ComputePipelineMetalSDL : public ComputePipeline {
private:
    // metal specifics
    id <MTLDevice> device;
    id <MTLCommandQueue> command_queue;
    id <MTLLibrary> library;
    
    // ---PIPELINE STATES FOR GPU COMPUTE KERNELS---
    id <MTLComputePipelineState> compute_transforms_pipeline_state;
    id <MTLComputePipelineState> compute_vertex_pipeline_state;
    id <MTLComputePipelineState> compute_projected_vertices_pipeline_state;
    id <MTLComputePipelineState> compute_vertex_squares_pipeline_state;
    id <MTLComputePipelineState> compute_scaled_dots_pipeline_state;
    id <MTLComputePipelineState> compute_projected_dots_pipeline_state;
    id <MTLComputePipelineState> compute_projected_nodes_pipeline_state;
    id <MTLComputePipelineState> compute_lighting_pipeline_state;
    id <MTLComputePipelineState> compute_slice_plates_state;
    id <MTLComputePipelineState> compute_ui_vertices_pipeline_state;
    
    // ---BUFFERS FOR SCENE COMPUTE---
    // compute data
    id <MTLBuffer> window_attributes_buffer;
    id <MTLBuffer> compiled_buffer_key_indices_buffer;
    
    // general scene data
    id <MTLBuffer> camera_buffer;
    id <MTLBuffer> scene_light_buffer;
    
    // model data (from both scene and controls models)
    id <MTLBuffer> scene_model_face_buffer; // only scene (not controls) models - buffer is only used for lighting
    id <MTLBuffer> model_node_buffer;
    id <MTLBuffer> model_nvlink_buffer;
    id <MTLBuffer> model_vertex_buffer;
    id <MTLBuffer> node_model_id_buffer;
    id <MTLBuffer> model_transform_buffer;
    
    // slice data
    id <MTLBuffer> slice_dot_buffer;
    id <MTLBuffer> slice_attributes_buffer;
    id <MTLBuffer> slice_transform_buffer;
    id <MTLBuffer> slice_edit_window_buffer;
    // TODO: DOT SLICE ID BUFFER (uint32_t)
    id <MTLBuffer> dot_slice_id_buffer;
    
    // ui data
    id <MTLBuffer> ui_vertex_buffer;
    id <MTLBuffer> ui_element_transform_buffer;
    id <MTLBuffer> ui_render_uniforms_buffer;
    id <MTLBuffer> ui_vertex_element_id_buffer;
    
    // ---COMPILED BUFFERS TO SEND TO RENDERER---
    id <MTLBuffer> compiled_vertex_buffer;
    id <MTLBuffer> compiled_face_buffer;
    id <MTLBuffer> compiled_edge_buffer;
public:
    ~ComputePipelineMetalSDL();
    void init();
    
    // call on start, when scheme changes, or when counts change
    // does not set any values, only creates buffers and sets size
    void CreateBuffers();
    
    // call when static data changes
    void ResetStaticBuffers();
    
    // call every frame
    void ResetDynamicBuffers();
    
    // pipeline
    void Compute();
    void SendDataToRenderer(RenderPipeline *renderer);
    void SendDataToScheme();
};

#endif /* ComputePipelineMetalSDL_h */
