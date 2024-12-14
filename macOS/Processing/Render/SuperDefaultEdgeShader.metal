//
//  SuperDefaultEdgeShader.metal
//  dragonfly
//
//  Created by Thomas Liang on 12/14/24.
//

#include <metal_stdlib>
using namespace metal;
#include "../MetalUtil.h"


struct VertexOut {
    vector_float4 pos [[position]];
    vector_float4 color;
};

// default vertex shader for edges with set color (blue)
// operates per face * 4 - need 4 vertices for the 3 edges in a face
// outputs vertex location exactly
vertex VertexOut SuperDefaultEdgeShader (
     const constant vec_float3 *vertex_array [[buffer(0)]],
     const constant vec_int2 *edge_array[[buffer(1)]],
     unsigned int vid [[vertex_id]]
 ) {
     // get current edge - 2 vertices to each edge
     vec_int2 current_edge = edge_array[vid/2];
     
     // get vertex and output
     Vertex currentVertex;
     if (vid % 2 == 0) currentVertex = vertex_array[current_edge.x];
     else currentVertex = vertex_array[current_edge.y];
     VertexOut output;
     output.pos = vector_float4(currentVertex.x, currentVertex.y, currentVertex.z+0.099, 1);
     output.color = vector_float4(0, 0, 1, 1);
     return output;
}
