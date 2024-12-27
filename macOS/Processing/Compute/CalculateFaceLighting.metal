//
//  CalculateFaceLighting.metal
//  dragonfly
//
//  Created by Thomas Liang on 12/14/24.
//

#include <metal_stdlib>
using namespace metal;
#include "../MetalUtil.h"
#include "../MetalBufferUtil.h"

/*
 output lit faces into compiled face buffer
 operate per face (of scene models only)
 args:
 1. panel_info_buffer - single Buffer object containing PanelBufferInfo objects
 2. comp_faces - Buffer of packed per-panel faces to render
 3. cpt_vertices - Buffer of packed per-panel calculated vertices
 3. scene_faces - Buffer of packed per-panel faces for scene models
 5. lights - Buffer of packed per-panel lights
 6. cameras - Buffer of packed per-panel cameras
 */
kernel void CalculateFaceLighting(
    const constant Buffer *panel_info_buffer [[buffer(0)]],
    device Buffer *comp_faces [[buffer(1)]],
    device Buffer *cpt_vertices [[buffer(2)]],
    const constant Buffer *scene_faces [[buffer(3)]],
    const constant Buffer *lights [[buffer(4)]],
   unsigned int fid[[thread_position_in_grid]]
) {
    vec_int2 pid_rfid = GlobalToPanelBufIdx(panel_info_buffer, PNL_FACE_OUTBUF_IDX, fid, sizeof(Face));
    int pid = pid_rfid.x;
    int rfid = pid_rfid.y;
    
    // get scene face and calculate normal
    constant Face *f = (constant Face *) GetConstantPanelBufElementFromRelIdx(panel_info_buffer, scene_faces, PNL_FACE_OUTBUF_IDX, pid, rfid, sizeof(Face));
    unsigned long fv_offset = ComputeBufOffset(panel_info_buffer, CPT_COMPMODELVERTEX_OUTBUF_IDX, pid); // panel vertex start
    device Vertex *v0 = (device Vertex *) GetDeviceComputeBufElementFromRelIdx(panel_info_buffer, cpt_vertices, CPT_COMPMODELVERTEX_OUTBUF_IDX, pid, f->vertices[0]+fv_offset, sizeof(Vertex));
    device Vertex *v1 = (device Vertex *) GetDeviceComputeBufElementFromRelIdx(panel_info_buffer, cpt_vertices, CPT_COMPMODELVERTEX_OUTBUF_IDX, pid, f->vertices[0]+fv_offset, sizeof(Vertex));
    device Vertex *v2 = (device Vertex *) GetDeviceComputeBufElementFromRelIdx(panel_info_buffer, cpt_vertices, CPT_COMPMODELVERTEX_OUTBUF_IDX, pid, f->vertices[0]+fv_offset, sizeof(Vertex));
    vec_float3 f_norm = cross_product(*v0, *v1, *v2);
    if (f->normal_reversed != 0) {
        f_norm.x *= -1;
        f_norm.y *= -1;
        f_norm.z *= -1;
    }
    
    // get angle between normal and light
    Vertex center = TriAvg(*v0, *v1, *v2);
    
    vec_float4 endcolor = vec_make_float4(0, 0, 0, f->color.w);
    for (unsigned int i = 0; i < GetPanelSubBufferHeader(panel_info_buffer, PNL_LIGHT_OUTBUF_IDX, pid).size; i++) {
        constant SimpleLight *light = (constant SimpleLight *) GetConstantPanelBufElementFromRelIdx(panel_info_buffer, lights, PNL_LIGHT_OUTBUF_IDX, pid, i, sizeof(SimpleLight));
        
        // get light intensity at face point
        vec_float3 light_basis_point = TranslatePointToBasis(light->b, center);
        float d = 1 / sqrt(pow(light_basis_point.x, 2) + pow(light_basis_point.y, 2) + pow(light_basis_point.z, 2));
        float a = 1 / angle_between(light_basis_point, vec_make_float3(1, 0, 0));
        float dmod = light->distance_falloff.x * pow(d, 2) + light->distance_falloff.y * d + light->distance_falloff.z;
        float amod = light->angle_falloff.x * pow(a, 2) + light->angle_falloff.y * a + light->angle_falloff.z;
        float intens = light->max_intensity * dmod * amod;

        // get angle between normal and light
        vec_float3 rev_dir = unit_vector(SubtractVectors(light->b.pos, center));
        float ang = 1 - abs(angle_between(f_norm, rev_dir)) / pi;
        intens *= ang * f->shading_multiplier;

        // get color
        endcolor.x += f->color.x * intens * light->color.x;
        endcolor.y += f->color.y * intens * light->color.y;
        endcolor.z += f->color.z * intens * light->color.z;
    }
    
    // set face in compiled face buffer
    unsigned long rcfid = SourceToPanelCompiledIndex(panel_info_buffer, pid, CBKI_F_SCENE_START_IDX, rfid);
    device Face *outf = (device Face *) GetDeviceComputeBufElementFromRelIdx(panel_info_buffer, comp_faces, CPT_COMPCOMPFACE_OUTBUF_IDX, pid, rcfid, sizeof(Face)); // other data should already be set
    outf->color = endcolor;
}
