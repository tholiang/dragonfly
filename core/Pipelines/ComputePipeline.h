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

#include "../Panels/Window.h"
#include "RenderPipeline.h"

class ComputePipeline {
protected:
    Window *window_;
public:
    virtual ~ComputePipeline();
    virtual void init() = 0;

    // set window
    void SetWindow(Window *w);
    
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
