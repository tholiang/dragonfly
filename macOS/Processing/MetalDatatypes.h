//
//  MetalDatatypes.h
//  dragonfly
//
//  Created by Thomas Liang on 12/14/24.
//
#ifndef MetalDatatypes_h
#define MetalDatatypes_h
#include "MetalConstants.h"

struct vec_float2 {
    float x;
    float y;
};

struct vec_float3 {
    float x;
    float y;
    float z;
};

struct vec_float4 {
    float x;
    float y;
    float z;
    float w;
};

struct vec_int2 {
    int x;
    int y;
};

struct vec_int3 {
    int x;
    int y;
    int z;
};

struct vec_int4 {
    int x;
    int y;
    int z;
    int w;
};

typedef vec_float3 Vertex;
typedef vec_int3 UIVertex;
typedef vec_float2 Dot;

struct WindowAttributes {
    unsigned int width = 1280;
    unsigned int height = 720;
};

struct Buffer {
    unsigned long capacity = 0;
    unsigned long size = 0; // in bytes
    // include all the data here - malloc (bad c++ practice whatever)
    // all data elements should be of the same type (and size)
};

struct CompiledBufferKeyIndices {
    unsigned int compiled_vertex_size = 0;
    unsigned int compiled_vertex_scene_start = 0;
    unsigned int compiled_vertex_control_start = 0;
    unsigned int compiled_vertex_dot_start = 0;
    unsigned int compiled_vertex_node_circle_start = 0;
    unsigned int compiled_vertex_vertex_square_start = 0;
    unsigned int compiled_vertex_dot_square_start = 0;
    unsigned int compiled_vertex_slice_plate_start = 0;
    unsigned int compiled_vertex_ui_start = 0;
    
    unsigned int compiled_face_size = 0;
    unsigned int compiled_face_scene_start = 0;
    unsigned int compiled_face_control_start = 0;
    unsigned int compiled_face_node_circle_start = 0;
    unsigned int compiled_face_vertex_square_start = 0;
    unsigned int compiled_face_dot_square_start = 0;
    unsigned int compiled_face_slice_plate_start = 0;
    unsigned int compiled_face_ui_start = 0;
    
    unsigned int compiled_edge_size = 0;
    unsigned int compiled_edge_scene_start = 0;
    unsigned int compiled_edge_line_start = 0;
};

struct PanelInfoBuffer {
    vec_float4 borders;
    unsigned long panel_buffer_starts[PNL_NUM_OUTBUFS]; // byte start
    unsigned long compute_buffer_starts[CPT_NUM_OUTBUFS]; // byte start
    CompiledBufferKeyIndices compiled_key_indices;
};

struct Basis {
    vec_float3 pos;
    // angles
    vec_float3 x;
    vec_float3 y;
    vec_float3 z;
};

struct Camera {
    vec_float3 pos;
    vec_float3 vector;
    vec_float3 upVector;
    vec_float2 FOV;
};

struct Face {
    unsigned int vertices[3];
    vec_float4 color;
    
    unsigned int normal_reversed;
    vec_float3 lighting_offset; // if there were a light source directly in front of the face, this is the rotation to get to its brightest orientation
    float shading_multiplier;
};

struct UIElementTransform {
    vec_int3 position;
    vec_float3 up;
    vec_float3 right;
};

struct Node {
    int locked_to;
    Basis b;
};

struct NodeVertexLink {
    int nid;
    vec_float3 vector;
    float weight;
};

struct ModelTransform {
    vec_float3 rotate_origin;
    Basis b;
};

struct SliceAttributes {
    float width;
    float height;
};

struct SimpleLight {
    Basis b;
    float max_intensity;
    vec_float4 color;
    vec_float3 distance_falloff;
    vec_float3 angle_falloff;
};



#endif /* MetalDatatypes_h */
