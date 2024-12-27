// TODO: updating slices
/*
 //
 //  CalculateProjectedDots.metal
 //  dragonfly
 //
 //  Created by Thomas Liang on 12/14/24.
 //
 
 #include <metal_stdlib>
 using namespace metal;
 #include "../MetalUtil.h"
 
 
 // operate per dot
 // output both projected dot value and corner values to compiled vertex
 kernel void CalculateProjectedDots(
 device Vertex *compiled_vertices [[buffer(0)]],
 device Face *compiled_faces [[buffer(1)]],
 const constant Dot *dots[[buffer(2)]],
 const constant ModelTransform *slice_transforms[[buffer(3)]],
 constant Camera &camera [[buffer(4)]],
 const constant unsigned int *dot_slice_ids[[buffer(5)]],
 const constant WindowAttributes *window_attr [[buffer(6)]],
 const constant CompiledBufferKeyIndices *key_indices [[buffer(7)]],
 unsigned int did [[thread_position_in_grid]]
 ) {
 // project dot to vertex
 Dot d = dots[did];
 Vertex dot3d; // need to make intermediate vertex to call function
 dot3d.x = d.x;
 dot3d.y = d.y;
 dot3d.z = 0;
 
 int sid = dot_slice_ids[did];
 dot3d = TranslatePointToStandard(slice_transforms[sid].b, dot3d);
 
 // set dot in cvb
 unsigned long cvb_dot_idx = key_indices->compiled_vertex_dot_start + did;
 Vertex proj_dot;
 
 proj_dot = PointToPixel(dot3d, camera);
 proj_dot.z -= 0.01;
 compiled_vertices[cvb_dot_idx] = proj_dot;
 
 // set (4) dot square corners in cvb
 float screen_ratio = (float) window_attr->height / window_attr->width;
 unsigned long cvb_dot_corner_idx = key_indices->compiled_vertex_dot_square_start + did*4;
 compiled_vertices[cvb_dot_corner_idx+0] = vec_make_float3(proj_dot.x-0.007, proj_dot.y-0.007 * screen_ratio, proj_dot.z+0.01);
 compiled_vertices[cvb_dot_corner_idx+1] = vec_make_float3(proj_dot.x-0.007, proj_dot.y+0.007 * screen_ratio, proj_dot.z+0.01);
 compiled_vertices[cvb_dot_corner_idx+2] = vec_make_float3(proj_dot.x+0.007, proj_dot.y-0.007 * screen_ratio, proj_dot.z+0.01);
 compiled_vertices[cvb_dot_corner_idx+3] = vec_make_float3(proj_dot.x+0.007, proj_dot.y+0.007 * screen_ratio, proj_dot.z+0.01);
 
 // set (2) dot square faces in cfb
 unsigned long cfb_dot_square_idx = key_indices->compiled_face_dot_square_start + did*2;
 Face f1;
 f1.color = vec_make_float4(0, 1, 0, 1);
 f1.vertices[0] = cvb_dot_corner_idx+0;
 f1.vertices[1] = cvb_dot_corner_idx+1;
 f1.vertices[2] = cvb_dot_corner_idx+2;
 compiled_faces[cfb_dot_square_idx+0] = f1;
 
 Face f2;
 f2.color = vec_make_float4(0, 1, 0, 1);
 f2.vertices[0] = cvb_dot_corner_idx+1;
 f2.vertices[1] = cvb_dot_corner_idx+2;
 f2.vertices[2] = cvb_dot_corner_idx+3;
 compiled_faces[cfb_dot_square_idx+1] = f2;
 }
 */
