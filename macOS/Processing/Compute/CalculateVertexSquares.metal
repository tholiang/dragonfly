//
//  CalculateVertexSquares.metal
//  dragonfly
//
//  Created by Thomas Liang on 12/14/24.
//

#include <metal_stdlib>
using namespace metal;
#include "../MetalBufferUtil.h"


/*
 calculate vertex squares from scene model projected vertices
 operate per projected vertex - output 4 vertices for each input vertex
 args:
 1. panel_info_buffer - single Buffer object containing PanelBufferInfo objects
 2. window_attributes - WindowAttributes object
 3. comp_vertices - Buffer of packed per-panel vertices to render
 4. comp_faces - Buffer of packed per-panel faces to render
 */
kernel void CalculateVertexSquares(
    const constant Buffer *panel_info_buffer [[buffer(0)]],
    const constant WindowAttributes *window_attributes [[buffer(1)]],
    device Buffer *compiled_vertices [[buffer(2)]],
    device Buffer *compiled_faces [[buffer(3)]],
    unsigned int vid [[thread_position_in_grid]]
) {
    vec_int2 pid_svid = GlobalToCompiledBufIdx(panel_info_buffer, CPT_COMPCOMPVERTEX_OUTBUF_IDX, CBKI_V_VSQUARE_START_IDX, vid*4, sizeof(Buffer));
    int pid = pid_svid.x;
    int svid = pid_svid.y/4;
    unsigned long rpvid = SourceToPanelCompiledIndex(panel_info_buffer, pid, CBKI_V_SCENE_START_IDX, svid); // vid for projected vertex
    
    // get current projected vertex
    device Vertex *currentVertex = (device Vertex *) GetDeviceComputeBufElementFromRelIdx(panel_info_buffer, compiled_vertices, CPT_COMPCOMPFACE_OUTBUF_IDX, pid, rpvid, sizeof(Vertex));
    
    // find index of the start of the 4 corner indices
    float screen_ratio = (float) window_attributes->height / window_attributes->width;
    unsigned long r_square_vertex_start_index = SourceToPanelCompiledIndex(panel_info_buffer, pid, CBKI_V_VSQUARE_START_IDX, svid*4);
    
    // add to compiled vertices
    device Vertex *sv0 = (device Vertex *) GetDeviceComputeBufElementFromRelIdx(panel_info_buffer, compiled_vertices, CPT_COMPCOMPVERTEX_OUTBUF_IDX, pid, r_square_vertex_start_index+0, sizeof(Vertex));
    device Vertex *sv1 = (device Vertex *) GetDeviceComputeBufElementFromRelIdx(panel_info_buffer, compiled_vertices, CPT_COMPCOMPVERTEX_OUTBUF_IDX, pid, r_square_vertex_start_index+1, sizeof(Vertex));
    device Vertex *sv2 = (device Vertex *) GetDeviceComputeBufElementFromRelIdx(panel_info_buffer, compiled_vertices, CPT_COMPCOMPVERTEX_OUTBUF_IDX, pid, r_square_vertex_start_index+2, sizeof(Vertex));
    device Vertex *sv3 = (device Vertex *) GetDeviceComputeBufElementFromRelIdx(panel_info_buffer, compiled_vertices, CPT_COMPCOMPVERTEX_OUTBUF_IDX, pid, r_square_vertex_start_index+3, sizeof(Vertex));
    *sv0 = vec_make_float3(currentVertex->x-0.007, currentVertex->y-0.007/screen_ratio, currentVertex->z-0.01);
    *sv1 = vec_make_float3(currentVertex->x-0.007, currentVertex->y+0.007/screen_ratio, currentVertex->z-0.01);
    *sv2 = vec_make_float3(currentVertex->x+0.007, currentVertex->y-0.007/screen_ratio, currentVertex->z-0.01);
    *sv3 = vec_make_float3(currentVertex->x+0.007, currentVertex->y+0.007/screen_ratio, currentVertex->z-0.01);
    
    
    // add to compiled faces
    unsigned long r_square_face_start_index = SourceToPanelCompiledIndex(panel_info_buffer, pid, CBKI_F_VSQUARE_START_IDX, svid*2);
    unsigned long g_square_vertex_start_index = RelComputeToGlobalIdx(panel_info_buffer, CPT_COMPCOMPVERTEX_OUTBUF_IDX, pid, r_square_vertex_start_index, sizeof(Vertex));
    
    device Face *f0 = (device Face *) GetDeviceComputeBufElementFromRelIdx(panel_info_buffer, compiled_faces, CPT_COMPCOMPFACE_OUTBUF_IDX, pid, r_square_face_start_index+0, sizeof(Face));
    f0->color = vec_make_float4(0,1,0,1);
    f0->vertices[0] = g_square_vertex_start_index+0;
    f0->vertices[1] = g_square_vertex_start_index+1;
    f0->vertices[2] = g_square_vertex_start_index+2;

    device Face *f1 = (device Face *) GetDeviceComputeBufElementFromRelIdx(panel_info_buffer, compiled_faces, CPT_COMPCOMPFACE_OUTBUF_IDX, pid, r_square_face_start_index+1, sizeof(Face));
    f1->color = vec_make_float4(0,1,0,1);
    f1->vertices[0] = g_square_vertex_start_index+1;
    f1->vertices[1] = g_square_vertex_start_index+2;
    f1->vertices[2] = g_square_vertex_start_index+3;
}
