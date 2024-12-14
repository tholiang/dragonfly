//
//  SuperDefaultVertexShader.metal
//  dragonfly
//
//  Created by Thomas Liang on 12/14/24.
//

#include <metal_stdlib>
using namespace metal;
#include "util.h"


// vertex shader with set color (white)
// takes 3D vertex and outputs location exactly
vertex VertexOut SuperDefaultVertexShader (
    const constant vec_float3 *vertex_array [[buffer(0)]],
    unsigned int vid [[vertex_id]]
) {
    vec_float3 currentVertex = vertex_array[vid];
    VertexOut output;
    output.pos = vector_float4(currentVertex.x, currentVertex.y, currentVertex.z, 1);
    output.color = vector_float4(1, 1, 1, 1);
    return output;
}
