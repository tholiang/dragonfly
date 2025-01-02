//
//  CalculateUIVertices.metal
//  dragonfly
//
//  Created by Thomas Liang on 12/14/24.
//

#include <metal_stdlib>
using namespace metal;
#include "../MetalUtil.h"
#include "../MetalBufferUtil.h"

/*
 output converted and scaled vertex to compiled vertex buffer
 operate per ui vertex
 args:
 1. panel_info_buffer - single Buffer object containing PanelBufferInfo objects
 2. window_attributes - WindowAttributes object
 3. comp_vertices - Buffer of packed per-panel vertices to render
 4. ui_vertices - Buffer of packed per-panel ui vertices
 5. element_ids - Buffer of packed per-panel element ids
 6. element_transforms - Buffer of packed per-panel element transforms
 */
kernel void CalculateUIVertices (
    const constant Buffer *panel_info_buffer [[buffer(0)]],
    const constant WindowAttributes *window_attributes [[buffer(1)]],
    device Buffer *comp_vertices [[buffer(2)]],
    const constant Buffer *ui_vertices[[buffer(3)]],
    const constant Buffer *element_ids[[buffer(4)]],
    const constant Buffer *element_transforms[[buffer(5)]],
    unsigned int vid [[thread_position_in_grid]]
) {
    vec_int2 pid_rvid = GlobalToCompiledBufIdx(panel_info_buffer, CPT_COMPCOMPVERTEX_OUTBUF_IDX, CBKI_V_UI_START_IDX, vid, sizeof(Vertex));
    int pid = pid_rvid.x;
    int rvid = pid_rvid.y;
    
    // get ui vertex
    constant UIVertex *v = (constant UIVertex *) GetConstantPanelBufElementFromRelIdx(panel_info_buffer, ui_vertices, PNL_UIVERTEX_OUTBUF_IDX, pid, rvid, sizeof(UIVertex));
    // get transform
    constant unsigned long *eid = (constant unsigned long *) GetConstantPanelBufElementFromRelIdx(panel_info_buffer, element_ids, PNL_UIELEMID_OUTBUF_IDX, pid, rvid, sizeof(unsigned long));
    constant UIElementTransform *et = (constant UIElementTransform *) GetConstantPanelBufElementFromRelIdx(panel_info_buffer, element_transforms, PNL_UITRANS_OUTBUF_IDX, pid, *eid, sizeof(UIElementTransform));
    // create vertex and set to start of element transform space (in world space)
    Vertex ret;
    ret.x = et->position.x;
    ret.y = et->position.y;
    ret.z = float(et->position.z + v->z)/100;
    
    // transform to vertex location (account for rotated element with right and up vectors)
    ret.x += et->right.x * v->x + et->up.x * v->y;
    ret.y += et->right.y * v->x + et->up.y * v->y;

    // convert to screen coords
    ret.x /= window_attributes->width/2;
    ret.y /= window_attributes->height/2;
    
    // set in compiled vertex buffer
    unsigned long r_ui_vertex_idx = SourceToPanelCompiledIndex(panel_info_buffer, pid, CBKI_V_UI_START_IDX, rvid);
    device Vertex *outv = (device Vertex *) GetDeviceComputeBufElementFromRelIdx(panel_info_buffer, comp_vertices, CPT_COMPCOMPVERTEX_OUTBUF_IDX, pid, r_ui_vertex_idx, sizeof(Vertex));
    *outv = ret;
}
