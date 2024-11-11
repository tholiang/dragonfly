#ifndef Buffers_h
#define Buffers_h

#include <stdio.h>
#include <iostream>
#include <cmath>

#include "Utils.h"
#include "Vec.h"

namespace DragonflyUtils {
struct Buffer {
    unsigned long size = 0; // in bytes
    void *data = NULL;
};

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


}

#endif // Buffers_h