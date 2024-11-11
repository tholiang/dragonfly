//
//  ComputePipeline.h
//  dragonfly
//
//  Created by Thomas Liang on 3/9/24.
//

#ifndef ComputePipeline_h
#define ComputePipeline_h

#include <stdio.h>
#include <vector>
#include <string>
#include <stdint.h>

#include "Utils/Buffers.h"
using namespace DragonflyUtils;
#include "Utils/Vec.h"
using namespace Vec;

#include "../Schemes/Scheme.h"
#include "RenderPipeline.h"

class ComputePipeline {
protected:
    // data for gpu
    CompiledBufferKeyIndices compiled_buffer_key_indices;
    
    // ---SCHEME AND SCHEME COUNTS---
    Scheme *scheme;
    unsigned long num_scene_models = 0;
    unsigned long num_scene_vertices = 0;
    unsigned long num_scene_faces = 0;
    unsigned long num_scene_edges = 0;
    unsigned long num_scene_nodes = 0;
    unsigned long num_scene_lights = 0;
    
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

    // ---BUFFER CAPACITIES---
    unsigned long light_buffer_capacity = 0;
    unsigned long scene_model_face_buffer_capacity = 0;
    unsigned long model_node_buffer_capacity = 0; // for node and node model id buffers
    unsigned long model_vertex_buffer_capacity = 0; // for vertex and nvlink buffers
    unsigned long model_buffer_capacity = 0;
    unsigned long slice_dot_buffer_capacity = 0; // for dot and dot slice id buffers
    unsigned long slice_buffer_capacity = 0; // for slice attributes and transforms buffers
    unsigned long ui_vertex_buffer_capacity = 0; // for ui vertex and vertex element id buffers
    unsigned long ui_element_buffer_capacity = 0;

    unsigned long compiled_vertex_buffer_capacity = 0;
    unsigned long compiled_face_buffer_capacity = 0;
    unsigned long compiled_edge_buffer_capacity = 0;
public:
    virtual ~ComputePipeline();
    virtual void init() = 0;

    // set scheme and counts
    void SetScheme(Scheme *sch);
    
    // call on start, when scheme changes, or when counts change
    // does not set any values, only creates buffers and sets size
    virtual void CreateBuffers() = 0;
    virtual void UpdateBufferCapacities() = 0;
    
    // call when static data changes
    virtual void ResetStaticBuffers() = 0;
    
    // call every frame
    virtual void ResetDynamicBuffers() = 0;
    
    // pipeline
    virtual void Compute() = 0;
    virtual void SendDataToRenderer(RenderPipeline *renderer) = 0;
    virtual void SendDataToScheme() = 0;
    
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
