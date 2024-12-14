//
//  CalculateProjectedNodes.metal
//  dragonfly
//
//  Created by Thomas Liang on 12/14/24.
//

#include <metal_stdlib>
using namespace metal;
#include "util.h"


// operate per node
// output projected node circle vertices and faces
kernel void CalculateProjectedNodes(
    device Vertex *compiled_vertices [[buffer(0)]],
    device Face *compiled_faces [[buffer(1)]],
    const constant Node *nodes [[buffer(2)]],
    constant Camera &camera [[buffer(3)]],
    const constant WindowAttributes *window_attr [[buffer(4)]],
    const constant CompiledBufferKeyIndices *key_indices [[buffer(5)]],
    unsigned int nid [[thread_position_in_grid]]
) {
    float screen_ratio = (float) window_attr->height / window_attr->width;
    
    // get projected node vertex
    Vertex proj_node_center = PointToPixel(nodes[nid].b.pos, camera);
    
    // add circle vertices to cvb abd faces to cfb
    unsigned long cvb_node_circle_idx = key_indices->compiled_vertex_node_circle_start+nid*9;
    unsigned long cfb_node_circle_idx = key_indices->compiled_face_node_circle_start+nid*8;
    
    // center
    compiled_vertices[cvb_node_circle_idx+0] = proj_node_center;
    
    // circle vertices and faces
    for (int i = 0; i < 8; i++) {
        // make radius smaller the farther away
        float radius = 1/(500*proj_node_center.z);
        // get angle from index
        float angle = i*pi/4;
        
        // calculate value (with trig) and add to cvb
        compiled_vertices[cvb_node_circle_idx+1+i] = vec_make_float3(proj_node_center.x + radius * cos(angle), proj_node_center.y + (radius * sin(angle) / screen_ratio), proj_node_center.z+0.02);
        
        // add face to cfb
        Face f;
        f.color = vec_make_float4(0.8, 0.8, 0.9, 1);
        f.vertices[0] = cvb_node_circle_idx; // center
        f.vertices[1] = cvb_node_circle_idx+1+i; // just added vertex
        f.vertices[2] = cvb_node_circle_idx+(1+(1+i)%8); // next vertex (or first added if at the end)
        compiled_faces[cfb_node_circle_idx+i] = f;
    }
}
