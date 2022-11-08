//
//  ComputePipeline.m
//  dragonfly
//
//  Created by Thomas Liang on 7/5/22.
//

#import <Foundation/Foundation.h>
#include "ComputePipeline.h"
#include <iostream>

void ComputePipeline::init() {
    device = MTLCreateSystemDefaultDevice();
    command_queue = [device newCommandQueue];
    library = [device newDefaultLibrary];
    
    SetPipeline();
}

void ComputePipeline::SetScheme(Scheme *sch) {
    scheme = sch;
    
    num_scene_vertices = scheme->NumSceneVertices();
    num_scene_faces = scheme->NumSceneFaces();
    num_controls_vertices = scheme->NumControlsVertices();
    num_controls_faces = scheme->NumControlsFaces();
}

void ComputePipeline::SetPipeline() {
    compute_reset_state = [device newComputePipelineStateWithFunction:[library newFunctionWithName:@"ResetVertices"] error:nil];
    compute_transforms_pipeline_state = [device newComputePipelineStateWithFunction:[library newFunctionWithName:@"CalculateModelNodeTransforms"] error:nil];
    compute_vertex_pipeline_state = [device newComputePipelineStateWithFunction:[library newFunctionWithName:@"CalculateVertices"] error:nil];
    compute_projected_vertices_pipeline_state = [device newComputePipelineStateWithFunction:[library newFunctionWithName:@"CalculateProjectedVertices"] error:nil];
    compute_projected_nodes_pipeline_state = [device newComputePipelineStateWithFunction:[library newFunctionWithName:@"CalculateProjectedNodes"] error:nil];
}

void ComputePipeline::SetEmptyBuffers() {
    num_scene_vertices = scheme->NumSceneVertices();
    num_scene_faces = scheme->NumSceneFaces();
    num_controls_vertices = scheme->NumControlsVertices();
    num_controls_faces = scheme->NumControlsFaces();
    
    std::vector<Vertex> empty_scene_vertices;
    for (int i = 0; i < num_scene_vertices; i++) {
        empty_scene_vertices.push_back(simd_make_float3(0, 0, 0));
    }
    
    std::vector<Vertex> empty_controls_vertices;
    for (int i = 0; i < num_scene_faces; i++) {
        empty_controls_vertices.push_back(simd_make_float3(0, 0, 0));
    }
    
    scene_vertex_buffer = [device newBufferWithBytes:empty_scene_vertices.data() length:(num_scene_vertices * sizeof(Vertex)) options:MTLResourceStorageModeShared];
    scene_projected_vertex_buffer = [device newBufferWithBytes:empty_scene_vertices.data() length:(num_scene_vertices * sizeof(Vertex)) options:MTLResourceStorageModeShared];
    
    controls_vertex_buffer = [device newBufferWithBytes:empty_controls_vertices.data() length:(num_controls_vertices * sizeof(Vertex)) options:MTLResourceStorageModeShared];
    controls_projected_vertex_buffer = [device newBufferWithBytes:empty_controls_vertices.data() length:(num_controls_vertices * sizeof(Vertex)) options:MTLResourceStorageModeShared];
}

void ComputePipeline::ResetStaticBuffers() {
    std::vector<Model *> *controls_models = scheme->GetControlsModels();
    std::vector<Model *> *models = scheme->GetScene()->GetModels();
    
    std::vector<Face> controls_faces;
    std::vector<NodeVertexLink> controls_nvlinks;
    std::vector<uint32_t> controls_node_modelIDs;
    controls_node_array.clear();
    
    num_controls_vertices = 0;
    
    for (std::size_t i = 0; i < controls_models->size(); i++) {
        controls_models->at(i)->AddToBuffers(controls_faces, controls_node_array, controls_nvlinks, controls_node_modelIDs, num_controls_vertices);
    }
    num_controls_faces = controls_faces.size();
    
    std::vector<Face> scene_faces;
    std::vector<NodeVertexLink> nvlinks;
    std::vector<uint32_t> node_modelIDs;
    scene_node_array.clear();
    
    num_scene_vertices = 0;
    
    for (std::size_t i = 0; i < models->size(); i++) {
        models->at(i)->AddToBuffers(scene_faces, scene_node_array, nvlinks, node_modelIDs, num_scene_vertices);
    }
    
    scene_empty_projected_nodes.clear();
    for (int i = 0; i < scene_node_array.size(); i++) {
        scene_empty_projected_nodes.push_back(simd_make_float3(0, 0, 0));
    }
    
    num_scene_faces = scene_faces.size();
    
    scene_face_buffer = [device newBufferWithBytes:scene_faces.data() length:(scene_faces.size() * sizeof(Face)) options:MTLResourceStorageModeShared];
    scene_nvlink_buffer = [device newBufferWithBytes:nvlinks.data() length:(nvlinks.size() * sizeof(NodeVertexLink)) options:MTLResourceStorageModeShared];
    scene_node_model_id_buffer = [device newBufferWithBytes:node_modelIDs.data() length:(node_modelIDs.size() * sizeof(uint32)) options:MTLResourceStorageModeShared];
    
    scene_projected_node_buffer = [device newBufferWithBytes:scene_empty_projected_nodes.data() length:(scene_empty_projected_nodes.size() * sizeof(Vertex)) options:MTLResourceStorageModeShared];
    
    controls_faces_buffer = [device newBufferWithBytes:controls_faces.data() length:(controls_faces.size() * sizeof(Face)) options:MTLResourceStorageModeShared];
    controls_nvlink_buffer = [device newBufferWithBytes:controls_nvlinks.data() length:(controls_nvlinks.size() * sizeof(NodeVertexLink)) options:MTLResourceStorageModeShared];
    controls_node_model_id_buffer = [device newBufferWithBytes:controls_node_modelIDs.data() length:(controls_node_modelIDs.size() * sizeof(uint32)) options:MTLResourceStorageModeShared];
}

void ComputePipeline::ResetDynamicBuffers() {
    std::vector<ModelUniforms> *controls_transforms = scheme->GetControlsModelUniforms();
    std::vector<ModelUniforms> *scene_transforms = scheme->GetScene()->GetAllModelUniforms();
    
    std::vector<Model *> *models = scheme->GetScene()->GetModels();
    for (std::size_t i = 0; i < models->size(); i++) {
        models->at(i)->UpdateNodeBuffers(scene_node_array);
    }
    
    std::vector<Model *> *controls_models = scheme->GetControlsModels();
    for (std::size_t i = 0; i < controls_models->size(); i++) {
        controls_models->at(i)->UpdateNodeBuffers(controls_node_array);
    }
    
    camera_buffer = [device newBufferWithBytes:scheme->GetCamera() length:sizeof(Camera) options:{}];
    scene_transform_uniforms_buffer = [device newBufferWithBytes: scene_transforms->data() length:(scene_transforms->size() * sizeof(ModelUniforms)) options:{}];
    scene_vertex_render_uniforms_buffer = [device newBufferWithBytes: scheme->GetVertexRenderUniforms() length:(sizeof(VertexRenderUniforms)) options:{}];
    scene_node_render_uniforms_buffer = [device newBufferWithBytes: scheme->GetNodeRenderUniforms() length:(sizeof(NodeRenderUniforms)) options:{}];
    scene_node_buffer = [device newBufferWithBytes: scene_node_array.data() length:(scene_node_array.size() * sizeof(Node)) options:MTLResourceStorageModeShared];
    
    controls_transform_uniforms_buffer = [device newBufferWithBytes: controls_transforms->data() length:(controls_transforms->size() * sizeof(ModelUniforms)) options:{}];
    controls_node_buffer = [device newBufferWithBytes:controls_node_array.data() length:(controls_node_array.size() * sizeof(Node)) options:MTLResourceStorageModeShared];
}

void ComputePipeline::Compute() {
    id<MTLCommandBuffer> compute_command_buffer = [command_queue commandBuffer];
    id<MTLComputeCommandEncoder> compute_encoder = [compute_command_buffer computeCommandEncoder];
    
    unsigned long num_scene_vertices = scheme->NumSceneVertices();
    unsigned long num_scene_faces = scheme->NumSceneFaces();
    unsigned long num_scene_nodes = scheme->NumSceneNodes();
    
    if (num_scene_vertices > 0 && num_scene_faces > 0 && num_scene_nodes > 0) {
        // reset vertices to 0
        [compute_encoder setComputePipelineState: compute_reset_state];
        [compute_encoder setBuffer: scene_vertex_buffer offset:0 atIndex:0];
        MTLSize gridSize = MTLSizeMake(num_scene_vertices, 1, 1);
        NSUInteger threadGroupSize = compute_reset_state.maxTotalThreadsPerThreadgroup;
        if (threadGroupSize > num_scene_vertices) threadGroupSize = num_scene_vertices;
        MTLSize threadgroupSize = MTLSizeMake(threadGroupSize, 1, 1);
        [compute_encoder dispatchThreads:gridSize threadsPerThreadgroup:threadgroupSize];
        
        // calculate rotated/transformed nodes
        [compute_encoder setComputePipelineState: compute_transforms_pipeline_state];
        [compute_encoder setBuffer: scene_node_buffer offset:0 atIndex:0];
        [compute_encoder setBuffer: scene_node_model_id_buffer offset:0 atIndex:1];
        [compute_encoder setBuffer: scene_transform_uniforms_buffer offset:0 atIndex:2];
        gridSize = MTLSizeMake(num_scene_nodes, 1, 1);
        threadGroupSize = compute_transforms_pipeline_state.maxTotalThreadsPerThreadgroup;
        if (threadGroupSize > num_scene_nodes) threadGroupSize = num_scene_nodes;
        threadgroupSize = MTLSizeMake(threadGroupSize, 1, 1);
        [compute_encoder dispatchThreads:gridSize threadsPerThreadgroup:threadgroupSize];
        
        // calculate vertices from nodes
        [compute_encoder setComputePipelineState:compute_vertex_pipeline_state];
        [compute_encoder setBuffer: scene_vertex_buffer offset:0 atIndex:0];
        [compute_encoder setBuffer: scene_nvlink_buffer offset:0 atIndex:1];
        [compute_encoder setBuffer: scene_node_buffer offset:0 atIndex:2];
        gridSize = MTLSizeMake(num_scene_vertices, 1, 1);
        threadGroupSize = compute_vertex_pipeline_state.maxTotalThreadsPerThreadgroup;
        if (threadGroupSize > num_scene_vertices) threadGroupSize = num_scene_vertices;
        threadgroupSize = MTLSizeMake(threadGroupSize, 1, 1);
        [compute_encoder dispatchThreads:gridSize threadsPerThreadgroup:threadgroupSize];
        
        // calculate projected vertex in kernel function
        [compute_encoder setComputePipelineState: compute_projected_vertices_pipeline_state];
        [compute_encoder setBuffer: scene_projected_vertex_buffer offset:0 atIndex:0];
        [compute_encoder setBuffer: scene_vertex_buffer offset:0 atIndex:1];
        [compute_encoder setBuffer: camera_buffer offset:0 atIndex:2];
        gridSize = MTLSizeMake(num_scene_vertices, 1, 1);
        threadGroupSize = compute_projected_vertices_pipeline_state.maxTotalThreadsPerThreadgroup;
        if (threadGroupSize > num_scene_vertices) threadGroupSize = num_scene_vertices;
        [compute_encoder dispatchThreads:gridSize threadsPerThreadgroup:threadgroupSize];
        
        // calculate projected nodes in kernel function
        [compute_encoder setComputePipelineState: compute_projected_nodes_pipeline_state];
        [compute_encoder setBuffer: scene_projected_node_buffer offset:0 atIndex:0];
        [compute_encoder setBuffer: scene_node_buffer offset:0 atIndex:1];
        [compute_encoder setBuffer: camera_buffer offset:0 atIndex:2];
        int nodes_length = (int) num_scene_nodes;
        gridSize = MTLSizeMake(nodes_length, 1, 1);
        threadGroupSize = compute_projected_nodes_pipeline_state.maxTotalThreadsPerThreadgroup;
        if (threadGroupSize > nodes_length) threadGroupSize = nodes_length;
        [compute_encoder dispatchThreads:gridSize threadsPerThreadgroup:threadgroupSize];
    }
    
    unsigned long num_controls_vertices = scheme->NumControlsVertices();
    unsigned long num_controls_faces = scheme->NumControlsFaces();
    unsigned long num_controls_nodes = scheme->NumControlsNodes();
    
    if (num_controls_vertices > 0 && num_controls_faces > 0 && num_controls_nodes > 0) {
        // reset vertices to 0
        [compute_encoder setComputePipelineState: compute_reset_state];
        [compute_encoder setBuffer: controls_vertex_buffer offset:0 atIndex:0];
        MTLSize gridSize = MTLSizeMake(num_controls_vertices, 1, 1);
        NSUInteger threadGroupSize = compute_reset_state.maxTotalThreadsPerThreadgroup;
        if (threadGroupSize > num_controls_vertices) threadGroupSize = num_controls_vertices;
        MTLSize threadgroupSize = MTLSizeMake(threadGroupSize, 1, 1);
        [compute_encoder dispatchThreads:gridSize threadsPerThreadgroup:threadgroupSize];
        
        // calculate rotated/transformed nodes
         [compute_encoder setComputePipelineState: compute_transforms_pipeline_state];
        [compute_encoder setBuffer: controls_node_buffer offset:0 atIndex:0];
        [compute_encoder setBuffer: controls_node_model_id_buffer offset:0 atIndex:1];
        [compute_encoder setBuffer: controls_transform_uniforms_buffer offset:0 atIndex:2];
        gridSize = MTLSizeMake(num_controls_nodes, 1, 1);
        threadGroupSize = compute_transforms_pipeline_state.maxTotalThreadsPerThreadgroup;
        if (threadGroupSize > num_controls_nodes) threadGroupSize = num_controls_nodes;
        threadgroupSize = MTLSizeMake(threadGroupSize, 1, 1);
        [compute_encoder dispatchThreads:gridSize threadsPerThreadgroup:threadgroupSize];
        
        // calculate vertices from nodes
        [compute_encoder setComputePipelineState: compute_vertex_pipeline_state];
        [compute_encoder setBuffer: controls_vertex_buffer offset:0 atIndex:0];
        [compute_encoder setBuffer: controls_nvlink_buffer offset:0 atIndex:1];
        [compute_encoder setBuffer: controls_node_buffer offset:0 atIndex:2];
        gridSize = MTLSizeMake(num_controls_vertices, 1, 1);
        threadGroupSize = compute_vertex_pipeline_state.maxTotalThreadsPerThreadgroup;
        if (threadGroupSize > num_controls_vertices) threadGroupSize = num_controls_vertices;
        threadgroupSize = MTLSizeMake(threadGroupSize, 1, 1);
        [compute_encoder dispatchThreads:gridSize threadsPerThreadgroup:threadgroupSize];
        
        // calculate projected vertex in kernel function
        [compute_encoder setComputePipelineState: compute_projected_vertices_pipeline_state];
        [compute_encoder setBuffer: controls_projected_vertex_buffer offset:0 atIndex:0];
        [compute_encoder setBuffer: controls_vertex_buffer offset:0 atIndex:1];
        [compute_encoder setBuffer: camera_buffer offset:0 atIndex:2];
        gridSize = MTLSizeMake(num_controls_vertices, 1, 1);
        threadGroupSize = compute_projected_vertices_pipeline_state.maxTotalThreadsPerThreadgroup;
        if (threadGroupSize > num_controls_vertices) threadGroupSize = num_controls_vertices;
        [compute_encoder dispatchThreads:gridSize threadsPerThreadgroup:threadgroupSize];
    }
    
    [compute_encoder endEncoding];
    [compute_command_buffer commit];
    [compute_command_buffer waitUntilCompleted];
}


void ComputePipeline::SendDataToRenderer(RenderPipeline *renderer) {
    renderer->SetBuffers(scene_projected_vertex_buffer, scene_face_buffer, scene_projected_node_buffer, scene_vertex_render_uniforms_buffer, scene_node_render_uniforms_buffer, controls_projected_vertex_buffer, controls_faces_buffer);
}

void ComputePipeline::SendDataToScheme() {
    Vertex *svb = (Vertex *) scene_vertex_buffer.contents;
    Vertex *spvb = (Vertex *) scene_projected_vertex_buffer.contents;
    Face *sfb = (Face *) scene_face_buffer.contents;
    Node *snb = (Node *) scene_node_buffer.contents;
    Vertex *spnb = (Vertex *) scene_projected_node_buffer.contents;
    Vertex *cvb = (Vertex *) controls_vertex_buffer.contents;
    Vertex *cpvb = (Vertex *) controls_projected_vertex_buffer.contents;
    Face *cfb = (Face *) controls_faces_buffer.contents;
    
    scheme->SetBufferContents(svb, spvb, sfb, snb, spnb, cvb, cpvb, cfb);
}
