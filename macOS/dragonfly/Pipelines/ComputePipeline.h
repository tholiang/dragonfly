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

class ComputePipeline {
private:
    id <MTLDevice> device;
    id <MTLCommandQueue> command_queue;
    id <MTLLibrary> library;
    
    id <MTLComputePipelineState> compute_reset_state;
    id <MTLComputePipelineState> compute_transforms_pipeline_state;
    id <MTLComputePipelineState> compute_vertex_pipeline_state;
    id <MTLComputePipelineState> compute_projected_vertices_pipeline_state;
    id <MTLComputePipelineState> compute_projected_nodes_pipeline_state;
    id <MTLComputePipelineState> compute_lighting_pipeline_state;
    id <MTLComputePipelineState> compute_scaled_dots_pipeline_state;
    
    // buffers for scene compute
    id <MTLBuffer> camera_buffer;
    
    id <MTLBuffer> scene_light_buffer;
    
    id <MTLBuffer> scene_vertex_buffer;
    id <MTLBuffer> scene_projected_vertex_buffer;
    id <MTLBuffer> scene_face_buffer;
    id <MTLBuffer> scene_lit_face_buffer;
    
    id <MTLBuffer> scene_dot_buffer;
    id <MTLBuffer> scene_projected_dot_buffer;
    id <MTLBuffer> scene_line_buffer;

    id <MTLBuffer> scene_node_model_id_buffer;

    std::vector<Node> scene_node_array;
    std::vector<Vertex> scene_empty_projected_nodes;
    id <MTLBuffer> scene_node_buffer;
    id <MTLBuffer> scene_projected_node_buffer;
    id <MTLBuffer> scene_nvlink_buffer;

    id <MTLBuffer> scene_transform_uniforms_buffer;
    id <MTLBuffer> scene_vertex_render_uniforms_buffer;
    id <MTLBuffer> scene_selected_vertices_buffer;
    id <MTLBuffer> scene_node_render_uniforms_buffer;
    
    id <MTLBuffer> scene_slice_attributes_buffer;
    
    // buffers for controls models compute
    id <MTLBuffer> controls_vertex_buffer;
    id <MTLBuffer> controls_projected_vertex_buffer;
    id <MTLBuffer> controls_faces_buffer;
    
    id <MTLBuffer> controls_node_model_id_buffer;
    
    std::vector<Node> controls_node_array;
    id <MTLBuffer> controls_node_buffer;
    id <MTLBuffer> controls_nvlink_buffer;
    
    id <MTLBuffer> controls_transform_uniforms_buffer;
    
    // scheme and scheme variables
    Scheme *scheme;
    unsigned int num_scene_vertices = 0;
    unsigned int num_scene_faces = 0;
    unsigned int num_controls_vertices = 0;
    unsigned int num_controls_faces = 0;
    
    unsigned int num_scene_dots = 0;
    unsigned int num_scene_lines = 0;
public:
    void init();
    void SetScheme(Scheme *sch);
    
    void SetPipeline();
    
    void SetEmptyBuffers();
    void ResetStaticBuffers();
    void ResetDynamicBuffers();
    
    void Compute();
    void SendDataToRenderer(RenderPipeline *renderer);
    void SendDataToScheme();
};

#endif /* ComputePipeline_h */
