//
//  ComputePipeline.h
//  dragonfly
//
//  Created by Thomas Liang on 7/5/22.
//

#ifndef ComputePipeline_h
#define ComputePipeline_h

#include <stdio.h>
#include <vector>
#include <string>

#include <simd/SIMD.h>

#import <Metal/Metal.h>
#import <QuartzCore/QuartzCore.h>

#import "../Schemes/Scheme.h"
#import "RenderPipeline.h"

struct CompiledBufferKeyIndices {
    uint32_t compiled_vertex_size = 0;
    uint32_t compiled_vertex_scene_start = 0;
    uint32_t compiled_vertex_control_start = 0;
    uint32_t compiled_vertex_dot_start = 0;
    uint32_t compiled_vertex_node_circle_start = 0;
    uint32_t compiled_vertex_vertex_square_start = 0;
    uint32_t compiled_vertex_dot_square_start = 0;
    uint32_t compiled_vertex_slice_plate_start = 0;
    uint32_t compiled_vertex_ui_start = 0;
    
    uint32_t compiled_face_size = 0;
    uint32_t compiled_face_scene_start = 0;
    uint32_t compiled_face_control_start = 0;
    uint32_t compiled_face_node_circle_start = 0;
    uint32_t compiled_face_vertex_square_start = 0;
    uint32_t compiled_face_dot_square_start = 0;
    uint32_t compiled_face_slice_plate_start = 0;
    uint32_t compiled_face_ui_start = 0;
    
    uint32_t compiled_edge_size = 0;
    uint32_t compiled_edge_scene_start = 0;
    uint32_t compiled_edge_line_start = 0;
};

class ComputePipeline {
private:
    // data for gpu
    CompiledBufferKeyIndices compiled_buffer_key_indices;
    
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
    
    
    // ---SCHEME AND SCHEME COUNTS---
    Scheme *scheme;
    unsigned long num_scene_models = 0;
    unsigned long num_scene_vertices = 0;
    unsigned long num_scene_faces = 0;
    unsigned long num_scene_edges = 0;
    unsigned long num_scene_nodes = 0;
    
    unsigned long num_controls_models = 0;
    unsigned long num_controls_vertices = 0;
    unsigned long num_controls_nodes = 0;
    unsigned long num_controls_faces = 0;
    
    unsigned long num_scene_slices = 0;
    unsigned long num_scene_dots = 0;
    unsigned long num_scene_lines = 0;
    
    unsigned long num_ui_elements = 0;
    unsigned long num_ui_vertices = 0;
    unsigned long num_ui_faces = 0;
public:
    void init();
    void SetScheme(Scheme *sch);
    
    // set scheme and counts
    void SetKernelPipelines();
    
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
    
    // helper functions for compiled buffers
    uint32_t compiled_vertex_size();
    uint32_t compiled_vertex_scene_start();
    uint32_t compiled_vertex_control_start();
    uint32_t compiled_vertex_dot_start();
    uint32_t compiled_vertex_node_circle_start();
    uint32_t compiled_vertex_vertex_square_start();
    uint32_t compiled_vertex_dot_square_start();
    uint32_t compiled_vertex_slice_plate_start();
    uint32_t compiled_vertex_ui_start();
    
    uint32_t compiled_face_size();
    uint32_t compiled_face_scene_start();
    uint32_t compiled_face_control_start();
    uint32_t compiled_face_node_circle_start();
    uint32_t compiled_face_vertex_square_start();
    uint32_t compiled_face_dot_square_start();
    uint32_t compiled_face_slice_plate_start();
    uint32_t compiled_face_ui_start();
    
    uint32_t compiled_edge_size();
    uint32_t compiled_edge_scene_start();
    uint32_t compiled_edge_line_start();
};

#endif /* ComputePipeline_h */
