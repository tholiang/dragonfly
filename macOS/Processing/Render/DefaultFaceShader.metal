//
//  DefaultFaceShader.metal
//  dragonfly
//
//  Created by Thomas Liang on 12/14/24.
//

#include <metal_stdlib>
using namespace metal;
#include "../MetalBufferUtil.h"


/*
 default vertex shader for faces
 outputs vertex location exactly and with face color
 operates per each vertex index given in every face
 */
vertex VertexOut DefaultFaceShader (
    const constant Buffer *vertices [[buffer(0)]],
    const constant Buffer *faces [[buffer(1)]],
    unsigned int vid [[vertex_id]]
) {
    // get current face - 3 vertices per face
    constant Face *cf = (constant Face *) _GetConstantBufferElement(faces, 0, vid/3, sizeof(Face));
    // get current vertex in face
    unsigned long cvid = cf->vertices[vid%3];
    constant Vertex *cv = (constant Vertex *) _GetConstantBufferElement(vertices, 0, cvid, sizeof(Vertex));
    
    // make and return output vertex
    VertexOut output;
    output.pos = vector_float4(cv->x, cv->y, cv->z, 1);
    output.color = vector_float4(cf->color.x, cf->color.y, cf->color.z, cf->color.w);
    output.pos.z += 0.1;
    return output;
}
