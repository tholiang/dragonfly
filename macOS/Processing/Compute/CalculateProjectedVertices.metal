//
//  CalculateProjectedVertices.metal
//  dragonfly
//
//  Created by Thomas Liang on 12/14/24.
//

#include <metal_stdlib>
using namespace metal;
#include "../MetalUtil.h"
#include "../MetalBufferUtil.h"


/*
 calculate projected vertices from model (scene + control) vertices
 operate per input/output vertex
 args:
 1. panel_info_buffer - single Buffer object containing PanelBufferInfo objects
 2. comp_vertices - Buffer of packed per-panel vertices to render
 3. cpt_vertices - Buffer of packed per-panel data of world space vertices
 4. cameras - Buffer of packed per-panel cameras (max 1 per panel)
 */
kernel void CalculateProjectedVertices(
    const constant Buffer *panel_info_buffer [[buffer(0)]],
    device Buffer *compiled_vertices [[buffer(1)]],
    device Buffer *cpt_vertices [[buffer(2)]],
    const constant Buffer *cameras [[buffer(3)]],
    unsigned int vid [[thread_position_in_grid]]
) {
    vec_int2 pid_rvid = GlobalToComputeBufIdx(panel_info_buffer, CPT_COMPMODELVERTEX_OUTBUF_IDX, vid, sizeof(Vertex));
    int pid = pid_rvid.x;
    int rvid = pid_rvid.y;
    
    device Vertex *v = (device Vertex *) GetDeviceComputeBufElementFromRelIdx(panel_info_buffer, cpt_vertices, CPT_COMPMODELVERTEX_OUTBUF_IDX, pid, rvid, sizeof(Vertex));
    constant Camera *c = (constant Camera *) GetConstantPanelBufElementFromRelIdx(panel_info_buffer, cameras, PNL_CAMERA_OUTBUF_IDX, pid, 0, sizeof(Camera)); // overkill, but need clean code!!
    
    // calculate projected vertices and place into compiled buffer
    unsigned long crvid = TranslateSourceToPanelIndex(panel_info_buffer, pid, CBKI_V_SCENE_START_IDX, rvid);
    device Vertex *outv = (device Vertex *) GetDeviceComputeBufElementFromRelIdx(panel_info_buffer, compiled_vertices, CPT_COMPCOMPVERTEX_OUTBUF_IDX, pid, crvid, sizeof(Vertex));
    *outv = PointToPixel(*v, c);
    outv->z += 0.05;
    
    // TODO: using CBKI_V_SCENE_START_IDX but this also sets control projections - works for now because these are stored contiguously
}
