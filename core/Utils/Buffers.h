#ifndef Buffers_h
#define Buffers_h

#include <stdio.h>
#include <iostream>
#include <cmath>

#include "Utils.h"
#include "Constants.h"
#include "Vec.h"

namespace DragonflyUtils {
struct Buffer {
    unsigned long capacity = 0;
    unsigned long size = 0; // in bytes
    // include all the data here - malloc (bad c++ practice whatever)
    // all data elements should be of the same type (and size)
};

// return a pointer to an element in a Buffer object, given an index and the size of each element in the buffer
void *GetBufferElement(Buffer *buf, unsigned long idx, unsigned int obj_size) {
    assert(idx < buf->size);

    void *data = ((void *) buf) + 2*sizeof(unsigned long);
    return data + (idx * obj_size);
}

// get total size of a buffer object (including attributes)
unsigned long TotalBufferSize(Buffer *buf) {
    return sizeof(Buffer) + buf->capacity;
}

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

struct PanelInfoBuffer {
    vec_float4 borders;
    unsigned long panel_buffer_starts[PNL_NUM_OUTBUFS]; // byte start
    unsigned long compute_buffer_starts[CPT_NUM_OUTBUFS]; // byte start
    CompiledBufferKeyIndices compiled_key_indices;
};

}

#endif // Buffers_h