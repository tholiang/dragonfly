//
//  CalculateSlicePlates.metal
//  dragonfly
//
//  Created by Thomas Liang on 12/14/24.
//

#include <metal_stdlib>
using namespace metal;
#include "../MetalUtil.h"


// operate per slice
// output (4) corner vertices to compiled vertex buffer and (2) plate faces to compiled face buffer
kernel void CalculateSlicePlates (
    device Vertex *compiled_vertices [[buffer(0)]],
    device Face *compiled_faces [[buffer(1)]],
    const constant ModelTransform *slice_transforms[[buffer(2)]],
    const constant SliceAttributes *attr[[buffer(3)]],
    constant Camera &camera [[buffer(4)]],
    const constant CompiledBufferKeyIndices *key_indices[[buffer(5)]],
    unsigned int sid [[thread_position_in_grid]]
) {
    // get slice attributes and transform
    SliceAttributes sa = attr[sid];
    ModelTransform st = slice_transforms[sid];
    
    // calculate vertices in slice space
    Vertex v1 = vec_make_float3(sa.width/2, sa.height/2, 0);
    Vertex v2 = vec_make_float3(sa.width/2, -sa.height/2, 0);
    Vertex v3 = vec_make_float3(-sa.width/2, sa.height/2, 0);
    Vertex v4 = vec_make_float3(-sa.width/2, -sa.height/2, 0);
    
    // translate to world space from slice transform
    v1 = TranslatePointToStandard(st.b, v1);
    v2 = TranslatePointToStandard(st.b, v2);
    v3 = TranslatePointToStandard(st.b, v3);
    v4 = TranslatePointToStandard(st.b, v4);
    
    // project vertices
    v1 = PointToPixel(v1, camera);
    v1.z += 0.1;
    v2 = PointToPixel(v2, camera);
    v2.z += 0.1;
    v3 = PointToPixel(v3, camera);
    v3.z += 0.1;
    v4 = PointToPixel(v4, camera);
    v4.z += 0.1;
    
    // add vertices to cvb
    unsigned long cvb_slice_plate_idx = key_indices->compiled_vertex_slice_plate_start+sid*4;
    compiled_vertices[cvb_slice_plate_idx+0] = v1;
    compiled_vertices[cvb_slice_plate_idx+1] = v2;
    compiled_vertices[cvb_slice_plate_idx+2] = v3;
    compiled_vertices[cvb_slice_plate_idx+3] = v4;
    
    // add faces to cfb
    unsigned long cfb_slice_plate_idx = key_indices->compiled_face_slice_plate_start+sid*2;
    Face f1;
    f1.color = vec_make_float4(0.7, 0.7, 0.7, 1);
    f1.vertices[0] = cvb_slice_plate_idx+0;
    f1.vertices[1] = cvb_slice_plate_idx+1;
    f1.vertices[2] = cvb_slice_plate_idx+2;
    compiled_faces[cfb_slice_plate_idx+0] = f1;
    
    Face f2;
    f2.color = vec_make_float4(0.7, 0.7, 0.7, 1);
    f2.vertices[0] = cvb_slice_plate_idx+1;
    f2.vertices[1] = cvb_slice_plate_idx+2;
    f2.vertices[2] = cvb_slice_plate_idx+3;
    compiled_faces[cfb_slice_plate_idx+1] = f2;
}
