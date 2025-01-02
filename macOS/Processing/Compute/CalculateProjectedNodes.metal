//
//  CalculateProjectedNodes.metal
//  dragonfly
//
//  Created by Thomas Liang on 12/14/24.
//

#include <metal_stdlib>
using namespace metal;
#include "../MetalBufferUtil.h"

/*
 output projected node circle vertices and faces
 operate per node
 args:
 1. panel_info_buffer - single Buffer object containing PanelBufferInfo objects
 2. window_attributes - WindowAttributes object
 3. comp_vertices - Buffer of packed per-panel vertices to render
 4. comp_faces - Buffer of packed per-panel faces to render
 5. nodes - Buffer of packed per-panel nodes - translated to world basis
 6. cameras - Buffer of packed per-panel cameras
 */
kernel void CalculateProjectedNodes(
    const constant Buffer *panel_info_buffer [[buffer(0)]],
    const constant WindowAttributes *window_attributes [[buffer(1)]],
    device Buffer *compiled_vertices [[buffer(2)]],
    device Buffer *compiled_faces [[buffer(3)]],
    device Buffer *nodes [[buffer(4)]],
    const constant Buffer *cameras [[buffer(5)]],
    unsigned int nid [[thread_position_in_grid]]
) {
    vec_int2 pid_rnid = GlobalToCompiledBufIdx(panel_info_buffer, CPT_COMPMODELNODE_OUTBUF_IDX, CBKI_V_NCIRCLE_START_IDX, nid*9, sizeof(Vertex));
    int pid = pid_rnid.x;
    int rnid = pid_rnid.y/9;
    
    // get projected node vertex
    device Node *node = (device Node *) GetDeviceComputeBufElementFromRelIdx(panel_info_buffer, nodes, CPT_COMPMODELNODE_OUTBUF_IDX, pid, rnid, sizeof(Node));
    constant Camera *camera = (constant Camera *) GetConstantPanelBufElementFromRelIdx(panel_info_buffer, cameras, PNL_CAMERA_OUTBUF_IDX, pid, 0, sizeof(Camera));
    Vertex proj_node_center = PointToPixel(node->b.pos, camera);
    
    // add circle vertices to cvb abd faces to cfb
    unsigned long r_v_node_circle_start_index = SourceToPanelCompiledIndex(panel_info_buffer, pid, CBKI_V_NCIRCLE_START_IDX, rnid*9);
    unsigned long g_v_node_circle_start_index = RelComputeToGlobalIdx(panel_info_buffer, CPT_COMPCOMPVERTEX_OUTBUF_IDX, pid, r_v_node_circle_start_index, sizeof(Vertex));
    unsigned long r_f_node_circle_start_index = SourceToPanelCompiledIndex(panel_info_buffer, pid, CBKI_F_NCIRCLE_START_IDX, rnid*8);
    
    // center
    device Vertex *cv0 = (device Vertex *) GetDeviceComputeBufElementFromRelIdx(panel_info_buffer, compiled_vertices, CPT_COMPCOMPVERTEX_OUTBUF_IDX, pid, r_v_node_circle_start_index+0, sizeof(Vertex));
    *cv0 = proj_node_center;
    
    // circle vertices and faces
    float screen_ratio = (float) window_attributes->height / window_attributes->width;
    for (int i = 0; i < 8; i++) {
        // make radius smaller the farther away
        float radius = 1/(500*proj_node_center.z);
        // get angle from index
        float angle = i*pi/4;
        
        // calculate value (with trig) and add to cvb
        device Vertex *cv = (device Vertex *) GetDeviceComputeBufElementFromRelIdx(panel_info_buffer, compiled_vertices, CPT_COMPCOMPVERTEX_OUTBUF_IDX, pid, r_v_node_circle_start_index+1+i, sizeof(Vertex));
        *cv = vec_make_float3(proj_node_center.x + radius * cos(angle), proj_node_center.y + (radius * sin(angle) / screen_ratio), proj_node_center.z+0.02);
        
        // add face to cfb
        device Face *f = (device Face *) GetDeviceComputeBufElementFromRelIdx(panel_info_buffer, compiled_faces, CPT_COMPCOMPFACE_OUTBUF_IDX, pid, r_f_node_circle_start_index+i, sizeof(Face));
        f->color = vec_make_float4(0.8, 0.8, 0.9, 1);
        f->vertices[0] = g_v_node_circle_start_index; // center
        f->vertices[1] = g_v_node_circle_start_index+1+i; // just added vertex
        f->vertices[2] = g_v_node_circle_start_index+(1+(1+i)%8); // next vertex (or first added if at the end)
    }
}
