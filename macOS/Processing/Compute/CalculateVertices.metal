//
//  CalculateVertices.metal
//  dragonfly
//
//  Created by Thomas Liang on 12/14/24.
//

#include <metal_stdlib>
using namespace metal;
#include "../MetalUtil.h"
#include "../MetalBufferUtil.h"

/*
 calculate model (scene + control) vertices in world space from node data and node vertex link data
 operate per output vertex - two nvlinks for each output vertex
 args:
 1. panel_info_buffer - single Buffer object containing PanelBufferInfo objects
 2. cpt_vertices - Buffer of packed per-panel data of world space vertices to write to
 3. nvlinks - Buffer of packed per-panel data of nvlinks to read from
 4. cpt_nodes - Buffer of packed per-panel data of world space nodes
 */
kernel void CalculateVertices(
    const constant Buffer *panel_info_buffer [[buffer(0)]],
    device Buffer *cpt_vertices [[buffer(1)]],
    const constant Buffer *nvlinks [[buffer(2)]],
    const constant Buffer *cpt_nodes [[buffer(3)]],
    unsigned int vid [[thread_position_in_grid]]
) {
    vec_int2 pid_rvid = GlobalToPanelBufIdx(panel_info_buffer, PNL_NODE_OUTBUF_IDX, vid, sizeof(Node));
    int pid = pid_rvid.x;
    int rvid = pid_rvid.y;
    
    Vertex v = vec_make_float3(0,0,0);
    
    constant NodeVertexLink *link1 = (constant NodeVertexLink *) GetConstantPanelBufElementFromRelIdx(panel_info_buffer, nvlinks, PNL_NODEVERTEXLNK_OUTBUF_IDX, pid, rvid*2, sizeof(NodeVertexLink));
    constant NodeVertexLink *link2 = (constant NodeVertexLink *) GetConstantPanelBufElementFromRelIdx(panel_info_buffer, nvlinks, PNL_NODEVERTEXLNK_OUTBUF_IDX, pid, (rvid*2)+1, sizeof(NodeVertexLink));
    
    if (link1->nid != -1) {
        constant Node *n = (constant Node *) GetConstantPanelBufElementFromRelIdx(panel_info_buffer, cpt_nodes, PNL_NODE_OUTBUF_IDX, pid, link1->nid, sizeof(Node));
        Vertex desired1 = TranslatePointToStandard(n->b, link1->vector);
        
        v.x += link1->weight*desired1.x;
        v.y += link1->weight*desired1.y;
        v.z += link1->weight*desired1.z;
    }
    
    if (link2->nid != -1) {
        constant Node *n = (constant Node *) GetConstantPanelBufElementFromRelIdx(panel_info_buffer, cpt_nodes, PNL_NODE_OUTBUF_IDX, pid, link2->nid, sizeof(Node));
        Vertex desired2 = TranslatePointToStandard(n->b, link2->vector);
        
        v.x += link2->weight*desired2.x;
        v.y += link2->weight*desired2.y;
        v.z += link2->weight*desired2.z;
    }
    
    device Vertex *cpt_v = (device Vertex *) GetDeviceComputeBufElementFromRelIdx(panel_info_buffer, cpt_vertices, CPT_COMPMODELVERTEX_OUTBUF_IDX, pid, rvid, sizeof(Vertex));
    *cpt_v = v;
}
