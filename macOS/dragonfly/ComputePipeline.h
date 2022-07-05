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

class ComputePipeline {
private:
    id <MTLComputePipelineState> scene_compute_reset_state;
    id <MTLComputePipelineState> scene_compute_transforms_pipeline_state;
    id <MTLComputePipelineState> scene_compute_vertex_pipeline_state;
    id <MTLComputePipelineState> scene_compute_projected_vertices_pipeline_state;
    id <MTLComputePipelineState> scene_compute_projected_nodes_pipeline_state;
    
    id <MTLBuffer> scene_vertex_buffer;
    id <MTLBuffer> projected_vertex_buffer;
    id <MTLBuffer> scene_face_buffer;

    id <MTLBuffer> scene_node_model_id_buffer;

    id <MTLBuffer> scene_node_buffer;
    id <MTLBuffer> scene_nvlink_buffer;

    id <MTLBuffer> scene_camera_buffer;

    id <MTLBuffer> rotate_uniforms_buffer;
    id <MTLBuffer> vertex_render_uniforms_buffer;
    id <MTLBuffer> node_render_uniforms_buffer;
    
    Scene *scene;
public:
    void SetEmptyBuffers();
    void ResetStaticBuffers();
    void ResetDynamicBuffers();
}

#endif /* ComputePipeline_h */
