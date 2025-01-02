//
//  SuperDefaultEdgeShader.metal
//  dragonfly
//
//  Created by Thomas Liang on 12/14/24.
//

#include <metal_stdlib>
using namespace metal;
#include "../MetalBufferUtil.h"

/*
 default vertex shader for edges with set color (blue)
 operates per face * 4 - need 4 vertices for the 3 edges in a face
 outputs vertex location exactly
 */
vertex VertexOut SuperDefaultEdgeShader (
     const constant Buffer *vertices [[buffer(0)]],
     const constant Buffer *edges[[buffer(1)]],
     unsigned int vid [[vertex_id]]
 ) {
     // get current edge - 2 vertices to each edge
     constant vec_int2 *ce = (constant vec_int2 *) _GetConstantBufferElement(edges, 0, vid/2, sizeof(vec_int2));
     
     // get vertex and output
     unsigned long cvid;
     if (vid % 2 == 0) cvid = ce->x;
     else cvid = ce->y;
     constant Vertex *cv = (constant Vertex *) _GetConstantBufferElement(vertices, 0, cvid, sizeof(Vertex));
     VertexOut output;
     output.pos = vector_float4(cv->x, cv->y, cv->z+0.099, 1);
     output.color = vector_float4(0, 0, 1, 1);
     return output;
}
