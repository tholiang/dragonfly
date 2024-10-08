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

void ComputePipelineMetalSDL::init() {
    device = MTLCreateSystemDefaultDevice();
    command_queue = [device newCommandQueue];
    library = [device newDefaultLibrary];
    
    // create kernel pipelines and set them to set Metal kernels
    compute_transforms_pipeline_state = [device newComputePipelineStateWithFunction:[library newFunctionWithName:@"CalculateModelNodeTransforms"] error:nil];
    compute_vertex_pipeline_state = [device newComputePipelineStateWithFunction:[library newFunctionWithName:@"CalculateVertices"] error:nil];
    compute_projected_vertices_pipeline_state = [device newComputePipelineStateWithFunction:[library newFunctionWithName:@"CalculateProjectedVertices"] error:nil];
    compute_vertex_squares_pipeline_state = [device newComputePipelineStateWithFunction:[library newFunctionWithName:@"CalculateVertexSquares"] error:nil];
    compute_scaled_dots_pipeline_state = [device newComputePipelineStateWithFunction:[library newFunctionWithName:@"CalculateScaledDots"] error:nil];
    compute_projected_dots_pipeline_state = [device newComputePipelineStateWithFunction:[library newFunctionWithName:@"CalculateProjectedDots"] error:nil];
    compute_projected_nodes_pipeline_state = [device newComputePipelineStateWithFunction:[library newFunctionWithName:@"CalculateProjectedNodes"] error:nil];
    compute_lighting_pipeline_state = [device newComputePipelineStateWithFunction:[library newFunctionWithName:@"CalculateFaceLighting"] error:nil];
    compute_slice_plates_state = [device newComputePipelineStateWithFunction:[library newFunctionWithName:@"CalculateSlicePlates"] error:nil];
    compute_ui_vertices_pipeline_state = [device newComputePipelineStateWithFunction:[library newFunctionWithName:@"CalculateUIVertices"] error:nil];
}

void ComputePipelineMetalSDL::CreateBuffers() {
    ComputePipeline::SetScheme(scheme);
    
    // ---COMPUTE DATA BUFFERS---
    window_attributes_buffer = [device newBufferWithBytes:scheme->GetWindowAttributes() length:(sizeof(WindowAttributes)) options:MTLResourceStorageModeShared];
    compiled_buffer_key_indices_buffer = [device newBufferWithBytes:&compiled_buffer_key_indices length:(sizeof(CompiledBufferKeyIndices)) options:MTLResourceStorageModeManaged];
    
    
    // ---COMPILED BUFFERS---
    // create compiled vertex buffer - all data to be set by gpu
    std::vector<Vertex> compiled_vertices(compiled_vertex_size());
    compiled_vertex_buffer = [device newBufferWithBytes:compiled_vertices.data() length:(compiled_vertices.size() * sizeof(Vertex)) options:MTLResourceStorageModeManaged];
    
    // create compiled face buffer
    std::vector<Face> compiled_faces(compiled_face_size());
    compiled_face_buffer = [device newBufferWithBytes:compiled_faces.data() length:(compiled_faces.size() * sizeof(Face)) options:MTLResourceStorageModeManaged];
    
    // create compiled edge buffer
    std::vector<vec_int2> compiled_edges(compiled_edge_size());
    compiled_edge_buffer = [device newBufferWithBytes:compiled_edges.data() length:(compiled_edges.size() * sizeof(vec_int2)) options:MTLResourceStorageModeManaged];
    
    
    // ---GENERAL BUFFERS---
    // create camera buffer
    camera_buffer = [device newBufferWithBytes:scheme->GetCamera() length:(sizeof(Camera)) options:MTLResourceStorageModeShared];
    
    // create light buffer
    std::vector<SimpleLight> scene_lights(scheme->NumSceneLights());
    scene_light_buffer = [device newBufferWithBytes:scene_lights.data() length:scene_lights.size()*sizeof(SimpleLight) options:MTLResourceStorageModeManaged];
    
    
    // ---MODEL BUFFERS---
    // create model face buffer - separate from compiled to calculate face lighting
    std::vector<Face> model_faces(num_scene_faces);
    scene_model_face_buffer = [device newBufferWithBytes:model_faces.data() length:(model_faces.size() * sizeof(Face)) options:MTLResourceStorageModeManaged];
    
    // create model node buffer
    std::vector<Node> model_nodes(num_scene_nodes+num_controls_nodes);
    model_node_buffer = [device newBufferWithBytes:model_nodes.data() length:(model_nodes.size() * sizeof(Node)) options:MTLResourceStorageModeManaged];
    
    // create node to model id buffer
    std::vector<uint32_t> node_modelid(num_scene_nodes+num_controls_nodes);
    node_model_id_buffer = [device newBufferWithBytes:node_modelid.data() length:(node_modelid.size() * sizeof(uint32_t)) options:MTLResourceStorageModeManaged];
    
    // create node vertex link buffer
    std::vector<NodeVertexLink> nvlinks(num_scene_vertices*2+num_controls_vertices*2);
    model_nvlink_buffer = [device newBufferWithBytes:nvlinks.data() length:(nvlinks.size() * sizeof(NodeVertexLink)) options:MTLResourceStorageModeManaged];
    
    // create model vertex buffer - intermediate: data calculated by kernel
    std::vector<Vertex> model_vertices(num_scene_vertices+num_controls_vertices);
    model_vertex_buffer = [device newBufferWithBytes:model_vertices.data() length:(model_vertices.size() * sizeof(Vertex)) options:MTLResourceStorageModeManaged];
    
    // create model transform buffer
    std::vector<ModelTransform> model_uniforms(num_scene_models+num_controls_models);
    model_transform_buffer = [device newBufferWithBytes:model_uniforms.data() length:(model_uniforms.size() * sizeof(ModelTransform)) options:MTLResourceStorageModeManaged];
    
    
    // ---SLICE BUFFERS---
    // create dot vertex buffer
    std::vector<Dot> slice_dots(num_scene_dots);
    slice_dot_buffer = [device newBufferWithBytes:slice_dots.data() length:(slice_dots.size() * sizeof(Dot)) options:MTLResourceStorageModeManaged];
    
    // create slice attributes buffer
    std::vector<SliceAttributes> slice_attributes(num_scene_slices);
    slice_attributes_buffer = [device newBufferWithBytes:slice_attributes.data() length:(slice_attributes.size() * sizeof(SliceAttributes)) options:MTLResourceStorageModeManaged];
    
    // create slice transform buffer
    std::vector<ModelTransform> slice_uniforms(num_scene_slices);
    slice_transform_buffer = [device newBufferWithBytes:slice_uniforms.data() length:(slice_uniforms.size() * sizeof(ModelTransform)) options:MTLResourceStorageModeManaged];
    
    // create slice edit window buffer
    vec_float4 slice_edit_window;
    slice_edit_window_buffer = [device newBufferWithBytes: &slice_edit_window length:(sizeof(vec_float4)) options:MTLResourceStorageModeManaged];
    
    
    // ---UI BUFFERS---
    // create ui vertex buffer
    std::vector<UIVertex> ui_vertices(num_ui_vertices);
    ui_vertex_buffer = [device newBufferWithBytes:ui_vertices.data() length:(ui_vertices.size() * sizeof(UIVertex)) options:MTLResourceStorageModeManaged];
    
    // create ui transform buffer
    std::vector<UIElementTransform> ui_element_transforms(num_ui_elements);
    ui_element_transform_buffer = [device newBufferWithBytes:ui_element_transforms.data() length:(ui_element_transforms.size() * sizeof(UIElementTransform)) options:MTLResourceStorageModeManaged];
    
    // create ui element id buffer
    std::vector<uint32_t> ui_element_ids(num_ui_vertices);
    ui_vertex_element_id_buffer = [device newBufferWithBytes:ui_element_ids.data() length:(ui_element_ids.size() * sizeof(uint32_t)) options:MTLResourceStorageModeManaged];
}

void ComputePipelineMetalSDL::UpdateBufferCapacities() {
    ComputePipeline::SetScheme(scheme);
    CompiledBufferKeyIndices *key_indices_contents = (CompiledBufferKeyIndices *) compiled_buffer_key_indices_buffer.contents;
    *key_indices_contents = compiled_buffer_key_indices;
    [compiled_buffer_key_indices_buffer didModifyRange: NSMakeRange(0, sizeof(CompiledBufferKeyIndices))];
    
    
    // ---COMPILED BUFFERS---
    if (compiled_vertex_size() > compiled_vertex_buffer_capacity) {
        compiled_vertex_buffer_capacity = compiled_vertex_size()*2;
        std::vector<Vertex> compiled_vertices(compiled_vertex_buffer_capacity);
        compiled_vertex_buffer = [device newBufferWithBytes:compiled_vertices.data() length:(compiled_vertex_buffer_capacity * sizeof(Vertex)) options:MTLResourceStorageModeManaged];
    }
    if (compiled_face_size() > compiled_face_buffer_capacity) {
        compiled_face_buffer_capacity = compiled_face_size()*2;
        
        std::vector<Face> compiled_faces(compiled_face_buffer_capacity);
        compiled_face_buffer = [device newBufferWithBytes:compiled_faces.data() length:(compiled_face_buffer_capacity * sizeof(Face)) options:MTLResourceStorageModeManaged];
    }
    
    if (compiled_edge_size() > compiled_edge_buffer_capacity) {
        compiled_edge_buffer_capacity = compiled_edge_size()*2;
        
        std::vector<vec_int2> compiled_edges(compiled_edge_buffer_capacity);
        compiled_edge_buffer = [device newBufferWithBytes:compiled_edges.data() length:(compiled_edge_buffer_capacity * sizeof(vec_int2)) options:MTLResourceStorageModeManaged];
    }
    
    // ---GENERAL BUFFERS---
    if (num_scene_lights > light_buffer_capacity) {
        light_buffer_capacity = num_scene_lights*2;
        
        std::vector<SimpleLight> scene_lights(light_buffer_capacity);
        scene_light_buffer = [device newBufferWithBytes:scene_lights.data() length:light_buffer_capacity*sizeof(SimpleLight) options:MTLResourceStorageModeManaged];
    }
    
    // ---MODEL BUFFERS---
    if (num_scene_faces > scene_model_face_buffer_capacity) {
        scene_model_face_buffer_capacity = num_scene_faces*2;
        
        std::vector<Face> model_faces(scene_model_face_buffer_capacity);
        scene_model_face_buffer = [device newBufferWithBytes:model_faces.data() length:(scene_model_face_buffer_capacity * sizeof(Face)) options:MTLResourceStorageModeManaged];
    }
    if (num_scene_nodes+num_controls_nodes > model_node_buffer_capacity) {
        model_node_buffer_capacity = (num_scene_nodes+num_controls_nodes)*2;
        
        std::vector<Node> model_nodes(model_node_buffer_capacity);
        model_node_buffer = [device newBufferWithBytes:model_nodes.data() length:(model_node_buffer_capacity * sizeof(Node)) options:MTLResourceStorageModeManaged];
    
        
        std::vector<uint32_t> node_modelid(model_node_buffer_capacity);
        node_model_id_buffer = [device newBufferWithBytes:node_modelid.data() length:(model_node_buffer_capacity * sizeof(uint32_t)) options:MTLResourceStorageModeManaged];
    }
    
    if (num_scene_vertices+num_controls_vertices > model_vertex_buffer_capacity) {
        model_vertex_buffer_capacity = (num_scene_vertices+num_controls_vertices)*2;
        std::vector<NodeVertexLink> nvlinks(model_vertex_buffer_capacity*2);
        model_nvlink_buffer = [device newBufferWithBytes:nvlinks.data() length:(model_vertex_buffer_capacity * 2 * sizeof(NodeVertexLink)) options:MTLResourceStorageModeManaged];
    
        std::vector<Vertex> model_vertices(model_vertex_buffer_capacity);
        model_vertex_buffer = [device newBufferWithBytes:model_vertices.data() length:(model_vertex_buffer_capacity * sizeof(Vertex)) options:MTLResourceStorageModeManaged];
    
    }
    if (num_scene_models+num_controls_models > model_buffer_capacity) {
        model_buffer_capacity = num_scene_models+num_controls_models;
        std::vector<ModelTransform> model_uniforms(model_buffer_capacity);
        model_transform_buffer = [device newBufferWithBytes:model_uniforms.data() length:(model_buffer_capacity * sizeof(ModelTransform)) options:MTLResourceStorageModeManaged];
    }
    
    // ---SLICE BUFFERS---
    if (num_scene_dots > slice_dot_buffer_capacity) {
        slice_dot_buffer_capacity = num_scene_dots*2;
        std::vector<Dot> slice_dots(slice_dot_buffer_capacity);
        slice_dot_buffer = [device newBufferWithBytes:slice_dots.data() length:(slice_dot_buffer_capacity * sizeof(Dot)) options:MTLResourceStorageModeManaged];
    }
    
    if (num_scene_slices > slice_buffer_capacity) {
        slice_buffer_capacity = num_scene_slices*2;
        std::vector<SliceAttributes> slice_attributes(slice_buffer_capacity);
        slice_attributes_buffer = [device newBufferWithBytes:slice_attributes.data() length:(slice_buffer_capacity * sizeof(SliceAttributes)) options:MTLResourceStorageModeManaged];
        
        std::vector<ModelTransform> slice_uniforms(slice_buffer_capacity);
        slice_transform_buffer = [device newBufferWithBytes:slice_uniforms.data() length:(slice_buffer_capacity * sizeof(ModelTransform)) options:MTLResourceStorageModeManaged];
    }
    
    
    // ---UI BUFFERS---
    if (num_ui_vertices > ui_vertex_buffer_capacity) {
        ui_vertex_buffer_capacity = num_ui_vertices*2;
        std::vector<UIVertex> ui_vertices(ui_vertex_buffer_capacity);
        ui_vertex_buffer = [device newBufferWithBytes:ui_vertices.data() length:(ui_vertex_buffer_capacity * sizeof(UIVertex)) options:MTLResourceStorageModeManaged];
        
        
        std::vector<uint32_t> ui_element_ids(ui_vertex_buffer_capacity);
        ui_vertex_element_id_buffer = [device newBufferWithBytes:ui_element_ids.data() length:(ui_vertex_buffer_capacity * sizeof(uint32_t)) options:MTLResourceStorageModeManaged];
    }
    
    if (num_ui_elements > ui_element_buffer_capacity) {
        ui_element_buffer_capacity = num_ui_elements*2;
        
        std::vector<UIElementTransform> ui_element_transforms(ui_element_buffer_capacity);
        ui_element_transform_buffer = [device newBufferWithBytes:ui_element_transforms.data() length:(ui_element_buffer_capacity * sizeof(UIElementTransform)) options:MTLResourceStorageModeManaged];
    }
}

void ComputePipelineMetalSDL::ResetStaticBuffers() {
    // assume all counts are accurate
    CompiledBufferKeyIndices *key_indices_contents = (CompiledBufferKeyIndices *) compiled_buffer_key_indices_buffer.contents;
    *key_indices_contents = compiled_buffer_key_indices;
    [compiled_buffer_key_indices_buffer didModifyRange: NSMakeRange(0, sizeof(CompiledBufferKeyIndices))];
    
    // ---COMPILED BUFFERS---
    // add data to compiled face buffer
    Face *cfb_contents = (Face *) compiled_face_buffer.contents;
    scheme->SetSceneFaceBuffer(cfb_contents + compiled_face_scene_start(), compiled_vertex_scene_start()); // scene faces
    scheme->SetControlFaceBuffer(cfb_contents + compiled_face_control_start(), compiled_vertex_control_start()); // control faces
    scheme->SetUIFaceBuffer(cfb_contents + compiled_face_ui_start(), compiled_vertex_ui_start()); // ui faces
    // rest will be set by GPU
    [compiled_face_buffer didModifyRange: NSMakeRange(0, compiled_face_size() * sizeof(Face))]; // alert gpu about what was modified
    
    // add data to compiled edge buffer
    vec_int2 *ceb_contents = (vec_int2 *) compiled_edge_buffer.contents;
    if (scheme->ShouldRenderEdges()) scheme->SetSceneEdgeBuffer(ceb_contents + compiled_edge_scene_start(), compiled_vertex_scene_start()); // scene edges
    scheme->SetSliceLineBuffer(ceb_contents + compiled_edge_line_start(), compiled_vertex_dot_start()); // slice lines
    [compiled_edge_buffer didModifyRange: NSMakeRange(0, compiled_edge_size() * sizeof(vec_int2))]; // alert gpu about what was modified
    
    
    // ---GENERAL BUFFERS---
    // add data to light buffer
    SimpleLight *scene_light_content = (SimpleLight *) scene_light_buffer.contents;
    scheme->SetSceneLightBuffer(scene_light_content);
    [scene_light_buffer didModifyRange: NSMakeRange(0, num_scene_lights * sizeof(SimpleLight))];
    
    
    // ---MODEL BUFFERS---
    // add data to scene model face buffer
    Face *smfb_contents = (Face *) scene_model_face_buffer.contents;
    scheme->SetSceneFaceBuffer(smfb_contents, compiled_vertex_scene_start()); // scene faces
    [scene_model_face_buffer didModifyRange: NSMakeRange(0, num_scene_faces*sizeof(Face))]; // alert gpu about what was modified
    
    // add data to node to model id buffer
    uint32_t *node_model_id_contents = (uint32_t *) node_model_id_buffer.contents;
    scheme->SetSceneNodeModelIDBuffer(node_model_id_contents, 0); // scene nodes
    scheme->SetControlNodeModelIDBuffer(node_model_id_contents+num_scene_nodes, num_scene_models); // controls nodes
    [node_model_id_buffer didModifyRange: NSMakeRange(0, (num_scene_nodes + num_controls_nodes)*sizeof(uint32_t))]; // alert gpu about what was modified
    
    // add data to node vertex link buffer
    NodeVertexLink *nvlink_contents = (NodeVertexLink *) model_nvlink_buffer.contents;
    scheme->SetSceneNodeVertexLinkBuffer(nvlink_contents, 0); // scene nvlinks
    scheme->SetControlNodeVertexLinkBuffer(nvlink_contents+num_scene_vertices*2, num_scene_nodes); // controls nvlinks
    [model_nvlink_buffer didModifyRange: NSMakeRange(0, 2*(num_scene_vertices + num_controls_vertices)*sizeof(NodeVertexLink))]; // alert gpu about what was modified
    
    
    // ---SLICE BUFFERS---
    // add data to dot buffer
    Dot *dot_contents = (Dot *) slice_dot_buffer.contents;
    scheme->SetSliceDotBuffer(dot_contents); // dots
    [slice_dot_buffer didModifyRange: NSMakeRange(0, num_scene_dots*sizeof(Dot))]; // alert gpu about what was modified
    
    // add data to slice attributes buffer
    SliceAttributes *sa_contents = (SliceAttributes *) slice_attributes_buffer.contents;
    scheme->SetSliceAttributesBuffer(sa_contents); // slice attributes
    [slice_attributes_buffer didModifyRange: NSMakeRange(0, num_scene_slices*sizeof(SliceAttributes))]; // alert gpu about what was modified

    // add data to slice edit window buffer
    *((vec_float4 *)slice_edit_window_buffer.contents) = scheme->GetEditWindow();
    [slice_edit_window_buffer didModifyRange: NSMakeRange(0, sizeof(vec_float4))]; // alert gpu about what was modified
    
    
    // ---UI BUFFERS---
    // add data to ui vertex buffer
    UIVertex *ui_vertex_contents = (UIVertex *) ui_vertex_buffer.contents;
    scheme->SetUIVertexBuffer(ui_vertex_contents);
    [ui_vertex_buffer didModifyRange: NSMakeRange(0, num_ui_vertices*sizeof(UIVertex))]; // alert gpu about what was modified
    
    // add data to ui element id buffer
    uint32_t *ui_element_id_contents = (uint32_t *) ui_vertex_element_id_buffer.contents;
    scheme->SetUIElementIDBuffer(ui_element_id_contents);
    [ui_vertex_element_id_buffer didModifyRange: NSMakeRange(0, num_ui_vertices*sizeof(uint32_t))]; // alert gpu about what was modified
}

void ComputePipelineMetalSDL::ResetDynamicBuffers() {
    // assume all counts are accurate
    
    // ---COMPUTE DATA BUFFERS---
    // add data to window attribute buffer
    *((WindowAttributes *)window_attributes_buffer.contents) = *scheme->GetWindowAttributes();
    [window_attributes_buffer didModifyRange: NSMakeRange(0, sizeof(WindowAttributes))]; // alert gpu about what was modified
    
    
    // ---GENERAL BUFFERS---
    // add data to camera buffer
    *((Camera *)camera_buffer.contents) = *scheme->GetCamera();
    [camera_buffer didModifyRange: NSMakeRange(0, sizeof(Camera))]; // alert gpu about what was modified
    
    
    // ---MODEL BUFFERS---
    // add data to model node buffer
    Node *model_node_content = (Node *) model_node_buffer.contents;
    scheme->SetSceneNodeBuffer(model_node_content); // scene nodes
    scheme->SetControlNodeBuffer(model_node_content+num_scene_nodes); // controls nodes
    [model_node_buffer didModifyRange: NSMakeRange(0, (num_scene_nodes+num_controls_nodes)*sizeof(Node))]; // alert gpu about what was modified
    
    // add data to model transform buffer
    ModelTransform *model_transform_content = (ModelTransform *) model_transform_buffer.contents;
    scheme->SetSceneModelTransformBuffer(model_transform_content); // scene transforms
    scheme->SetControlModelTransformBuffer(model_transform_content+num_scene_models); // controls transforms
    [model_transform_buffer didModifyRange: NSMakeRange(0, (num_scene_models+num_controls_models)*sizeof(ModelTransform))]; // alert gpu about what was modified
    
    
    // ---SLICE BUFFERS---
    // add data to slice transform buffer
    ModelTransform *slice_transform_content = (ModelTransform *) slice_transform_buffer.contents;
    scheme->SetSliceTransformBuffer(slice_transform_content);
    [slice_transform_buffer didModifyRange: NSMakeRange(0, (num_scene_slices)*sizeof(ModelTransform))]; // alert gpu about what was modified
    
    
    // ---UI BUFFERS---
    // add data to ui element transform buffer
    UIElementTransform *ui_element_transform_content = (UIElementTransform *) ui_element_transform_buffer.contents;
    scheme->SetUITransformBuffer(ui_element_transform_content);
    [ui_element_transform_buffer didModifyRange: NSMakeRange(0, (num_ui_elements)*sizeof(UIElementTransform))]; // alert gpu about what was modified
}

void ComputePipelineMetalSDL::Compute() {
    // TODO: MOVE THIS OUT?
    id<MTLCommandBuffer> compute_command_buffer = [command_queue commandBuffer];
    id<MTLComputeCommandEncoder> compute_encoder = [compute_command_buffer computeCommandEncoder];
    
    // thread size variables - change for each kernel
    MTLSize gridsize;
    NSUInteger numthreads;
    MTLSize threadgroupsize;
    
    // if any models to display, calculate values from kernel
    if (num_scene_vertices > 0 && num_scene_faces > 0 && num_scene_nodes > 0) {
        // calculate nodes (scene and control) in world space from model space
        [compute_encoder setComputePipelineState: compute_transforms_pipeline_state];
        // set buffers
        [compute_encoder setBuffer: model_node_buffer offset:0 atIndex:0];
        [compute_encoder setBuffer: node_model_id_buffer offset:0 atIndex:1];
        [compute_encoder setBuffer: model_transform_buffer offset:0 atIndex:2];
        // set thread size variables - per scene and control node
        gridsize = MTLSizeMake(num_scene_nodes+num_controls_nodes, 1, 1);
        numthreads = compute_transforms_pipeline_state.maxTotalThreadsPerThreadgroup;
        if (numthreads > num_scene_nodes+num_controls_nodes) numthreads = num_scene_nodes+num_controls_nodes;
        threadgroupsize = MTLSizeMake(numthreads, 1, 1);
        // execute
        [compute_encoder dispatchThreads:gridsize threadsPerThreadgroup:threadgroupsize];
        
        // calculate vertices (scene and control) in world space from node-ish space
        [compute_encoder setComputePipelineState:compute_vertex_pipeline_state];
        // set buffers
        [compute_encoder setBuffer: model_vertex_buffer offset:0 atIndex:0];
        [compute_encoder setBuffer: model_nvlink_buffer offset:0 atIndex:1];
        [compute_encoder setBuffer: model_node_buffer offset:0 atIndex:2];
        // set thread size variables - per output scene and control vertex
        gridsize = MTLSizeMake(num_scene_vertices+num_controls_vertices, 1, 1);
        numthreads = compute_vertex_pipeline_state.maxTotalThreadsPerThreadgroup;
        if (numthreads > num_scene_vertices+num_controls_vertices) numthreads = num_scene_vertices+num_controls_vertices;
        threadgroupsize = MTLSizeMake(numthreads, 1, 1);
        // execute
        [compute_encoder dispatchThreads:gridsize threadsPerThreadgroup:threadgroupsize];
        
        // calculate projected vertices from world space vertices
        [compute_encoder setComputePipelineState: compute_projected_vertices_pipeline_state];
        // set buffers
        [compute_encoder setBuffer: compiled_vertex_buffer offset:0 atIndex:0];
        [compute_encoder setBuffer: model_vertex_buffer offset:0 atIndex:1];
        [compute_encoder setBuffer: camera_buffer offset:0 atIndex:2];
        [compute_encoder setBuffer: compiled_buffer_key_indices_buffer offset:0 atIndex:3];
        // set thread size variables - per scene and control vertex
        gridsize = MTLSizeMake(num_scene_vertices+num_controls_vertices, 1, 1);
        numthreads = compute_projected_vertices_pipeline_state.maxTotalThreadsPerThreadgroup;
        if (numthreads > num_scene_vertices+num_controls_vertices) numthreads = num_scene_vertices+num_controls_vertices;
        threadgroupsize = MTLSizeMake(numthreads, 1, 1);
        // execute
        [compute_encoder dispatchThreads:gridsize threadsPerThreadgroup:threadgroupsize];
        
        // calculate vertex squares from projected vertices if needed
        if (scheme->ShouldRenderVertices()) {
            [compute_encoder setComputePipelineState: compute_vertex_squares_pipeline_state];
            // set buffers
            [compute_encoder setBuffer: compiled_vertex_buffer offset:0 atIndex:0];
            [compute_encoder setBuffer: compiled_face_buffer offset:0 atIndex:1];
            [compute_encoder setBuffer: compiled_buffer_key_indices_buffer offset:0 atIndex:2];
            [compute_encoder setBuffer: window_attributes_buffer offset:0 atIndex:3];
            // set thread size variables - per scene vertex
            gridsize = MTLSizeMake(num_scene_vertices, 1, 1);
            numthreads = compute_projected_vertices_pipeline_state.maxTotalThreadsPerThreadgroup;
            if (numthreads > num_scene_vertices) numthreads = num_scene_vertices;
            threadgroupsize = MTLSizeMake(numthreads, 1, 1);
            // execute
            [compute_encoder dispatchThreads:gridsize threadsPerThreadgroup:threadgroupsize];
        }
        
        // calculate projected scene nodes if needed
        if (scheme->ShouldRenderNodes()) {
            [compute_encoder setComputePipelineState: compute_projected_nodes_pipeline_state];
            [compute_encoder setBuffer: compiled_vertex_buffer offset:0 atIndex:0];
            [compute_encoder setBuffer: compiled_face_buffer offset:0 atIndex:1];
            [compute_encoder setBuffer: model_node_buffer offset:0 atIndex:2];
            [compute_encoder setBuffer: camera_buffer offset:0 atIndex:3];
            [compute_encoder setBuffer: window_attributes_buffer offset:0 atIndex:4];
            [compute_encoder setBuffer: compiled_buffer_key_indices_buffer offset:0 atIndex:5];
            // set thread size variables - per scene nodes
            gridsize = MTLSizeMake(num_scene_nodes, 1, 1);
            numthreads = compute_projected_nodes_pipeline_state.maxTotalThreadsPerThreadgroup;
            if (numthreads > num_scene_nodes) numthreads = num_scene_nodes;
            threadgroupsize = MTLSizeMake(numthreads, 1, 1);
            // execute
            [compute_encoder dispatchThreads:gridsize threadsPerThreadgroup:threadgroupsize];
        }
        
        // if lighting is enabled calculate scene face lighting
        if (scheme->LightingEnabled() && num_scene_lights > 0) {
            [compute_encoder setComputePipelineState: compute_lighting_pipeline_state];
            // set buffers
            [compute_encoder setBuffer: compiled_face_buffer offset:0 atIndex:0];
            [compute_encoder setBuffer: scene_model_face_buffer offset:0 atIndex:1];
            [compute_encoder setBuffer: model_vertex_buffer offset:0 atIndex:2];
            [compute_encoder setBytes: &num_scene_lights length:sizeof(uint32_t) atIndex:3];
            [compute_encoder setBuffer: scene_light_buffer offset:0 atIndex:4];
            [compute_encoder setBuffer: compiled_buffer_key_indices_buffer offset:0 atIndex:5];
            // set thread size variables - per scene face
            gridsize = MTLSizeMake(num_scene_faces, 1, 1);
            numthreads = compute_projected_vertices_pipeline_state.maxTotalThreadsPerThreadgroup;
            if (numthreads > num_scene_faces) numthreads = num_scene_faces;
            threadgroupsize = MTLSizeMake(numthreads, 1, 1);
            // execute
            [compute_encoder dispatchThreads:gridsize threadsPerThreadgroup:threadgroupsize];
        }
    }
    
    // if any slices to display, calculate values from kernel
    if (num_scene_dots > 0) {
        if (scheme->GetType() == SchemeType::EditSlice) {
            // scale dots if editing slice
            [compute_encoder setComputePipelineState: compute_scaled_dots_pipeline_state];
            // set buffers
            [compute_encoder setBuffer: compiled_vertex_buffer offset:0 atIndex:0];
            [compute_encoder setBuffer: compiled_face_buffer offset:0 atIndex:1];
            [compute_encoder setBuffer: slice_dot_buffer offset:0 atIndex:2];
            [compute_encoder setBuffer: slice_attributes_buffer offset:0 atIndex:3];
            [compute_encoder setBuffer: window_attributes_buffer offset:0 atIndex:4];
            [compute_encoder setBuffer: slice_edit_window_buffer offset:0 atIndex:5];
            [compute_encoder setBuffer: compiled_buffer_key_indices_buffer offset:0 atIndex:6];
            // set thread size variables - per dot
            gridsize = MTLSizeMake(num_scene_dots, 1, 1);
            numthreads = compute_scaled_dots_pipeline_state.maxTotalThreadsPerThreadgroup;
            if (numthreads > num_scene_dots) numthreads = num_scene_dots;
            threadgroupsize = MTLSizeMake(numthreads, 1, 1);
            // execute
            [compute_encoder dispatchThreads:gridsize threadsPerThreadgroup:threadgroupsize];
        } else {
            // project dots otherwise
            [compute_encoder setComputePipelineState: compute_projected_dots_pipeline_state];
            // set buffers
            [compute_encoder setBuffer: compiled_vertex_buffer offset:0 atIndex:0];
            [compute_encoder setBuffer: compiled_face_buffer offset:0 atIndex:1];
            [compute_encoder setBuffer: slice_dot_buffer offset:0 atIndex:2];
            [compute_encoder setBuffer: slice_transform_buffer offset:0 atIndex:3];
            [compute_encoder setBuffer: camera_buffer offset:0 atIndex:4];
            [compute_encoder setBuffer: dot_slice_id_buffer offset:0 atIndex:5];
            [compute_encoder setBuffer: window_attributes_buffer offset:0 atIndex:6];
            [compute_encoder setBuffer: compiled_buffer_key_indices_buffer offset:0 atIndex:7];
            // set thread size varialbes - per dot
            gridsize = MTLSizeMake(num_scene_dots, 1, 1);
            numthreads = compute_projected_dots_pipeline_state.maxTotalThreadsPerThreadgroup;
            if (numthreads > num_scene_dots) numthreads = num_scene_dots;
            threadgroupsize = MTLSizeMake(numthreads, 1, 1);
            // execute
            [compute_encoder dispatchThreads:gridsize threadsPerThreadgroup:threadgroupsize];
            
            // make slice plates
            [compute_encoder setComputePipelineState: compute_slice_plates_state];
            [compute_encoder setBuffer: compiled_vertex_buffer offset:0 atIndex:0];
            [compute_encoder setBuffer: compiled_face_buffer offset:0 atIndex:1];
            [compute_encoder setBuffer: slice_transform_buffer offset:0 atIndex:2];
            [compute_encoder setBuffer: slice_attributes_buffer offset:0 atIndex:3];
            [compute_encoder setBuffer: camera_buffer offset:0 atIndex:4];
            [compute_encoder setBuffer: compiled_buffer_key_indices_buffer offset:0 atIndex:5];
            // set thread size variables - per slice
            gridsize = MTLSizeMake(num_scene_slices, 1, 1);
            numthreads = compute_projected_dots_pipeline_state.maxTotalThreadsPerThreadgroup;
            if (numthreads > num_scene_slices) numthreads = num_scene_slices;
            threadgroupsize = MTLSizeMake(numthreads, 1, 1);
            // execute
            [compute_encoder dispatchThreads:gridsize threadsPerThreadgroup:threadgroupsize];
        }
    }
    
    if (num_ui_vertices > 0) {
        // make ui vertices
        [compute_encoder setComputePipelineState: compute_ui_vertices_pipeline_state];
        [compute_encoder setBuffer: compiled_vertex_buffer offset:0 atIndex:0];
        [compute_encoder setBuffer: ui_vertex_buffer offset:0 atIndex:1];
        [compute_encoder setBuffer: ui_vertex_element_id_buffer offset:0 atIndex:2];
        [compute_encoder setBuffer: ui_element_transform_buffer offset:0 atIndex:3];
        [compute_encoder setBuffer: window_attributes_buffer offset:0 atIndex:4];
        [compute_encoder setBuffer: compiled_buffer_key_indices_buffer offset:0 atIndex:5];
        // set thread size variables - per slice
        gridsize = MTLSizeMake(num_ui_vertices, 1, 1);
        numthreads = compute_ui_vertices_pipeline_state.maxTotalThreadsPerThreadgroup;
        if (numthreads > num_ui_vertices) numthreads = num_ui_vertices;
        threadgroupsize = MTLSizeMake(numthreads, 1, 1);
        // execute
        [compute_encoder dispatchThreads:gridsize threadsPerThreadgroup:threadgroupsize];
    }
    
    [compute_encoder endEncoding];
    
    // Synchronize the managed buffers for scheme
    id <MTLBlitCommandEncoder> blit_command_encoder = [compute_command_buffer blitCommandEncoder];
    [blit_command_encoder synchronizeResource: compiled_vertex_buffer];
    [blit_command_encoder synchronizeResource: compiled_face_buffer];
    [blit_command_encoder synchronizeResource: model_vertex_buffer];
    [blit_command_encoder synchronizeResource: model_node_buffer];
    [blit_command_encoder endEncoding];
    
    [compute_command_buffer commit];
    [compute_command_buffer waitUntilCompleted];
}


void ComputePipelineMetalSDL::SendDataToRenderer(RenderPipeline *renderer) {
    RenderPipelineMetalSDL *renderer_metalsdl = (RenderPipelineMetalSDL *) renderer;
    renderer_metalsdl->SetBuffers(compiled_vertex_buffer, compiled_face_buffer, compiled_edge_buffer, compiled_face_size(), compiled_edge_size());
}

void ComputePipelineMetalSDL::SendDataToScheme() {
    Vertex *ccv = (Vertex *) compiled_vertex_buffer.contents;
    Face *ccf = (Face *) compiled_face_buffer.contents;
    Vertex *cmv = (Vertex *) model_vertex_buffer.contents;
    Node *cmn = (Node *) model_node_buffer.contents;
    
    scheme->SetBufferContents(&compiled_buffer_key_indices, ccv, ccf, cmv, cmn);
}
