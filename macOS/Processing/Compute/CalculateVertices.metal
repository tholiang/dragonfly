//
//  CalculateVertices.metal
//  dragonfly
//
//  Created by Thomas Liang on 12/14/24.
//

#include <metal_stdlib>
using namespace metal;
#include "../MetalUtil.h"

/*
 calculate model (scene + control) vertices in world space from node data and node vertex link data
 operate per output vertex - two nvlinks for each output vertex
 args:
 1. panel_info_buffer - single Buffer object containing PanelInfoBuffer objects
 2. cpt_vertices - packed per-panel Buffers of world space vertices to write to
 3. nvlinks - packed per-panel Buffers of nvlinks to read from
 4. cpt_nodes - packet per-panel Buffers of world space nodes
 */
kernel void CalculateVertices(
    const constant Buffer *panel_info_buffer [[buffer(0)]],
    device char *cpt_vertices [[buffer(1)]],
    const constant char *nvlinks [[buffer(2)]],
    const constant char *cpt_nodes [[buffer(3)]],
    unsigned int vid [[thread_position_in_grid]]
) {
    vec_int2 pid_rvid = GetPanelFromIndex(panel_info_buffer, cpt_vertices, PNL_NODE_OUTBUF_IDX, nid, sizeof(Node));
    int pid = pid_rvid.x;
    int rvid = pid_rvid.y;
    
    Vertex v = vec_make_float3(0,0,0);
    
    NodeVertexLink *link1 = nvlinks[vid*2];
    NodeVertexLink *link2 = nvlinks[vid*2 + 1];
    
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
