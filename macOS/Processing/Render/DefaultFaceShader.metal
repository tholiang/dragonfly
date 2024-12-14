//
//  DefaultFaceShader.metal
//  dragonfly
//
//  Created by Thomas Liang on 12/14/24.
//

#include <metal_stdlib>
using namespace metal;
#include "util.h"


// default vertex shader for faces
// operates per each vertex index given in every face
// outputs vertex location exactly and with face color
vertex VertexOut DefaultFaceShader (
    const constant vec_float3 *vertex_array [[buffer(0)]],
    const constant Face *face_array[[buffer(1)]],
    unsigned int vid [[vertex_id]]
) {
    // get current face - 3 vertices per face
    Face currentFace = face_array[vid/3];
    // get current vertex in face
    vec_float3 currentVertex = vertex_array[currentFace.vertices[vid%3]];
    
    // make and return output vertex
    VertexOut output;
    output.pos = vector_float4(currentVertex.x, currentVertex.y, currentVertex.z, 1);
    output.color = vector_float4(currentFace.color.x, currentFace.color.y, currentFace.color.z, currentFace.color.w);
    output.pos.z += 0.1;
    return output;
}
