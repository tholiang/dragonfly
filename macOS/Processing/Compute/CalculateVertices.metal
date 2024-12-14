//
//  CalculateVertices.metal
//  dragonfly
//
//  Created by Thomas Liang on 12/14/24.
//

#include <metal_stdlib>
using namespace metal;
#include "util.h"


// calculate model (scene + control) vertices in world space from node data and node vertex link data
// operate per output vertex - two nvlinks for each output vertex
kernel void CalculateVertices(
    device Vertex *vertices [[buffer(0)]],
    const constant NodeVertexLink *nvlinks [[buffer(1)]],
    const constant Node *nodes [[buffer(2)]],
    unsigned int vid [[thread_position_in_grid]]
) {
    Vertex v = vec_make_float3(0,0,0);
    
    NodeVertexLink link1 = nvlinks[vid*2];
    NodeVertexLink link2 = nvlinks[vid*2 + 1];
    
    if (link1.nid != -1) {
        Node n = nodes[link1.nid];
        Vertex desired1 = TranslatePointToStandard(n.b, link1.vector);
        
        v.x += link1.weight*desired1.x;
        v.y += link1.weight*desired1.y;
        v.z += link1.weight*desired1.z;
    }
    
    if (link2.nid != -1) {
        Node n = nodes[link2.nid];
        Vertex desired2 = TranslatePointToStandard(n.b, link2.vector);
        
        v.x += link2.weight*desired2.x;
        v.y += link2.weight*desired2.y;
        v.z += link2.weight*desired2.z;
    }
    
    vertices[vid] = v;
}
