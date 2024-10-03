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

void ComputePipeline::SetScheme(Scheme *sch) {
    scheme = sch;
    
    
    if (scheme->GetType() == SchemeType::EditSlice) {
        num_scene_models = 0;
        num_scene_vertices = 0;
        num_scene_faces = 0;
        num_scene_edges = 0;
        num_scene_nodes = 0;
        num_scene_lights = 0;
        
        num_scene_slices = 1;
        num_scene_dots = scheme->NumSceneDots();
        num_scene_lines = scheme->NumSceneLines();
        
        num_controls_models = 0;
        num_controls_vertices = 0;
        num_controls_faces = 0;
        num_controls_nodes = 0;
        
        num_ui_elements = 0;
        num_ui_vertices = 0;
        num_ui_faces = 0;
    } else {
        num_scene_models = scheme->GetScene()->NumModels();
        num_scene_vertices = scheme->NumSceneVertices();
        num_scene_faces = scheme->NumSceneFaces();
        num_scene_edges = num_scene_faces*3;
        num_scene_nodes = scheme->NumSceneNodes();
        num_scene_lights = scheme->NumSceneLights();
        
        num_scene_slices = scheme->GetScene()->NumSlices();
        num_scene_dots = scheme->NumSceneDots();
        num_scene_lines = scheme->NumSceneLines();
        
        num_controls_models = scheme->NumControlsModels();
        num_controls_vertices = scheme->NumControlsVertices();
        num_controls_faces = scheme->NumControlsFaces();
        num_controls_nodes = scheme->NumControlsNodes();
        
        num_ui_elements = scheme->NumUIElements();
        num_ui_vertices = scheme->NumUIVertices();
        num_ui_faces = scheme->NumUIFaces();
    }
    
    // set compiled buffer key indices
    compiled_buffer_key_indices.compiled_vertex_size = compiled_vertex_size();
    compiled_buffer_key_indices.compiled_vertex_scene_start = compiled_vertex_scene_start();
    compiled_buffer_key_indices.compiled_vertex_scene_start = compiled_vertex_scene_start();
    compiled_buffer_key_indices.compiled_vertex_control_start = compiled_vertex_control_start();
    compiled_buffer_key_indices.compiled_vertex_dot_start = compiled_vertex_dot_start();
    compiled_buffer_key_indices.compiled_vertex_node_circle_start = compiled_vertex_node_circle_start();
    compiled_buffer_key_indices.compiled_vertex_vertex_square_start = compiled_vertex_vertex_square_start();
    compiled_buffer_key_indices.compiled_vertex_dot_square_start = compiled_vertex_dot_square_start();
    compiled_buffer_key_indices.compiled_vertex_slice_plate_start = compiled_vertex_slice_plate_start();
    compiled_buffer_key_indices.compiled_vertex_ui_start = compiled_vertex_ui_start();
    
    compiled_buffer_key_indices.compiled_face_size = compiled_face_size();
    compiled_buffer_key_indices.compiled_face_scene_start = compiled_face_scene_start();
    compiled_buffer_key_indices.compiled_face_control_start = compiled_face_control_start();
    compiled_buffer_key_indices.compiled_face_node_circle_start = compiled_face_node_circle_start();
    compiled_buffer_key_indices.compiled_face_vertex_square_start = compiled_face_vertex_square_start();
    compiled_buffer_key_indices.compiled_face_dot_square_start = compiled_face_dot_square_start();
    compiled_buffer_key_indices.compiled_face_slice_plate_start = compiled_face_slice_plate_start();
    compiled_buffer_key_indices.compiled_face_ui_start = compiled_face_ui_start();
    
    compiled_buffer_key_indices.compiled_edge_size = compiled_edge_size();
    compiled_buffer_key_indices.compiled_edge_scene_start = compiled_edge_scene_start();
    compiled_buffer_key_indices.compiled_edge_line_start = compiled_edge_line_start();
}

uint32_t ComputePipeline::compiled_vertex_size() {
    if (scheme->GetType() == SchemeType::EditSlice) return num_scene_dots + num_scene_dots*4;
    
    uint32_t size = 0;
    size += num_scene_vertices;
    size += num_controls_vertices;
    size += num_scene_dots;
    if (scheme->ShouldRenderNodes()) size += num_scene_nodes * 9; // 8 triangles per node
    if (scheme->ShouldRenderVertices()) size += num_scene_vertices * 4;
    size += num_scene_dots * 4; // always render dot squares
    if (scheme->GetType() != SchemeType::EditSlice) size += num_scene_slices * 4;
    size += num_ui_vertices;
    return size;
}

uint32_t ComputePipeline::compiled_vertex_scene_start() {
    if (scheme->GetType() == SchemeType::EditSlice) return 0;
    
    uint32_t size = 0;
    return size;
}
uint32_t ComputePipeline::compiled_vertex_control_start() {
    if (scheme->GetType() == SchemeType::EditSlice) return 0;
    
    uint32_t size = compiled_vertex_scene_start();
    size += num_scene_vertices;
    return size;
}
uint32_t ComputePipeline::compiled_vertex_dot_start() {
    if (scheme->GetType() == SchemeType::EditSlice) return 0;
    
    uint32_t size = compiled_vertex_control_start();
    size += num_controls_vertices;
    return size;
}
uint32_t ComputePipeline::compiled_vertex_node_circle_start() {
    if (scheme->GetType() == SchemeType::EditSlice) return num_scene_dots;
    
    uint32_t size = compiled_vertex_dot_start();
    size += num_scene_dots;
    return size;
}
uint32_t ComputePipeline::compiled_vertex_vertex_square_start() {
    if (scheme->GetType() == SchemeType::EditSlice) return num_scene_dots;
    
    uint32_t size = compiled_vertex_node_circle_start();
    if (scheme->ShouldRenderNodes()) size += num_scene_nodes * 9;
    return size;
}
uint32_t ComputePipeline::compiled_vertex_dot_square_start() {
    if (scheme->GetType() == SchemeType::EditSlice) return num_scene_dots;
    
    uint32_t size = compiled_vertex_vertex_square_start();
    if (scheme->ShouldRenderVertices()) size += num_scene_vertices * 4;
    return size;
}
uint32_t ComputePipeline::compiled_vertex_slice_plate_start() {
    if (scheme->GetType() == SchemeType::EditSlice) return num_scene_dots + num_scene_dots*4;
    
    uint32_t size = compiled_vertex_dot_square_start();
    size += num_scene_dots * 4;
    return size;
}
uint32_t ComputePipeline::compiled_vertex_ui_start() {
    if (scheme->GetType() == SchemeType::EditSlice) return num_scene_dots + num_scene_dots*4;
    
    uint32_t size = compiled_vertex_slice_plate_start();
    if (scheme->GetType() != SchemeType::EditSlice) size += num_scene_slices * 4;
    return size;
}

uint32_t ComputePipeline::compiled_face_size() {
    if (scheme->GetType() == SchemeType::EditSlice) return num_scene_dots*2;
    
    uint32_t size = 0;
    if (scheme->ShouldRenderFaces()) size += num_scene_faces;
    size += num_controls_faces;
    if (scheme->ShouldRenderNodes()) size += num_scene_nodes * 8;
    if (scheme->ShouldRenderVertices()) size += num_scene_vertices*2;
    size += num_scene_dots*2;
    size += num_scene_slices*2;
    size += num_ui_faces;
    return size;
}
uint32_t ComputePipeline::compiled_face_scene_start() {
    if (scheme->GetType() == SchemeType::EditSlice) return 0;
    
    uint32_t size = 0;
    return size;
}
uint32_t ComputePipeline::compiled_face_control_start() {
    if (scheme->GetType() == SchemeType::EditSlice) return 0;
    
    uint32_t size = compiled_face_scene_start();
    if (scheme->ShouldRenderFaces()) size += num_scene_faces;
    return size;
}
uint32_t ComputePipeline::compiled_face_node_circle_start() {
    if (scheme->GetType() == SchemeType::EditSlice) return 0;
    
    uint32_t size = compiled_face_control_start();
    size += num_controls_faces;
    return size;
}
uint32_t ComputePipeline::compiled_face_vertex_square_start() {
    if (scheme->GetType() == SchemeType::EditSlice) return 0;
    
    uint32_t size = compiled_face_node_circle_start();
    if (scheme->ShouldRenderNodes()) size += num_scene_nodes * 8;
    return size;
}
uint32_t ComputePipeline::compiled_face_dot_square_start() {
    if (scheme->GetType() == SchemeType::EditSlice) return 0;
    
    uint32_t size = compiled_face_vertex_square_start();
    if (scheme->ShouldRenderVertices()) size += num_scene_vertices*2;
    return size;
}
uint32_t ComputePipeline::compiled_face_slice_plate_start() {
    if (scheme->GetType() == SchemeType::EditSlice) return num_scene_dots*2;
    
    uint32_t size = compiled_face_dot_square_start();
    size += num_scene_dots*2;
    return size;
}
uint32_t ComputePipeline::compiled_face_ui_start() {
    if (scheme->GetType() == SchemeType::EditSlice) return num_scene_dots*2;
    
    uint32_t size = compiled_face_slice_plate_start();
    size += num_scene_slices*2;
    return size;
}

uint32_t ComputePipeline::compiled_edge_size() {
    if (scheme->GetType() == SchemeType::EditSlice) return num_scene_lines;
    
    uint32_t size = 0;
    if (scheme->ShouldRenderEdges()) size += num_scene_edges;
    size += num_scene_lines;
    return size;
}
uint32_t ComputePipeline::compiled_edge_scene_start() {
    if (scheme->GetType() == SchemeType::EditSlice) return 0;
    
    uint32_t size = 0;
    return size;
}
uint32_t ComputePipeline::compiled_edge_line_start() {
    if (scheme->GetType() == SchemeType::EditSlice) return 0;
    
    uint32_t size = 0;
    if (scheme->ShouldRenderEdges()) size += num_scene_edges;
    return size;
}
