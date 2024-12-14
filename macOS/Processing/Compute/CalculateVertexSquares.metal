//
//  CalculateVertexSquares.metal
//  dragonfly
//
//  Created by Thomas Liang on 12/14/24.
//

#include <metal_stdlib>
using namespace metal;
#include "../MetalUtil.h"


// calculate vertex squares from scene model projected vertices
// operate per projected vertex - output 4 vertices for each input vertex
kernel void CalculateVertexSquares(
    device Vertex *compiled_vertices [[buffer(0)]],
    device Face *compiled_faces [[buffer(1)]],
    const constant CompiledBufferKeyIndices *key_indices [[buffer(2)]],
    const constant WindowAttributes *window_attributes [[buffer(3)]],
    unsigned int vid [[thread_position_in_grid]]
) {
    // get current projected vertex
    vec_float3 currentVertex = compiled_vertices[key_indices->compiled_vertex_scene_start+vid];
    
    // find index of the start of the 4 corner indices
    unsigned int square_vertex_start_index = key_indices->compiled_vertex_vertex_square_start+(vid*4);
    float screen_ratio = (float) window_attributes->height / window_attributes->width;
    
    // add to compiled vertices
    compiled_vertices[square_vertex_start_index+0] = vec_make_float3(currentVertex.x-0.007, currentVertex.y - 0.007/screen_ratio, currentVertex.z-0.01);
    compiled_vertices[square_vertex_start_index+1] = vec_make_float3(currentVertex.x-0.007, currentVertex.y + 0.007/screen_ratio, currentVertex.z-0.01);
    compiled_vertices[square_vertex_start_index+2] = vec_make_float3(currentVertex.x+0.007, currentVertex.y - 0.007/screen_ratio, currentVertex.z-0.01);
    compiled_vertices[square_vertex_start_index+3] = vec_make_float3(currentVertex.x+0.007, currentVertex.y + 0.007/screen_ratio, currentVertex.z-0.01);
    
    // add to compiled faces
    unsigned int square_face_start_index = key_indices->compiled_face_vertex_square_start+(vid*2);
    
    Face f1;
    f1.color = vec_make_float4(0,1,0,1);
    f1.vertices[0] = square_vertex_start_index+0;
    f1.vertices[1] = square_vertex_start_index+1;
    f1.vertices[2] = square_vertex_start_index+2;
    compiled_faces[square_face_start_index+0] = f1;

    Face f2;
    f2.color = vec_make_float4(0,1,0,1);
    f2.vertices[0] = square_vertex_start_index+1;
    f2.vertices[1] = square_vertex_start_index+2;
    f2.vertices[2] = square_vertex_start_index+3;
    compiled_faces[square_face_start_index+1] = f2;
}
