//
//  CalculateScaledDots.metal
//  dragonfly
//
//  Created by Thomas Liang on 12/14/24.
//

#include <metal_stdlib>
using namespace metal;
#include "../MetalUtil.h"


// operate per dot
// output both scaled dot value and corner values to compiled vertex
kernel void CalculateScaledDots(
    device Vertex *compiled_vertices [[buffer(0)]],
    device Face *compiled_faces [[buffer(1)]],
    const constant Dot *dots[[buffer(2)]],
    const constant SliceAttributes *attr[[buffer(3)]],
    const constant WindowAttributes *window_attr[[buffer(4)]],
    const constant vec_float4 *edit_window [[buffer(5)]],
    const constant CompiledBufferKeyIndices *key_indices[[buffer(6)]],
    unsigned int did [[thread_position_in_grid]]
) {
    float scale = attr->height / 2;
    if (attr->height < attr->width) {
        scale = attr->width / 2;
    }
    
    // set dot in cvb
    float screen_ratio = (float) window_attr->height / window_attr->width;
    float eratio = edit_window->z / edit_window->w * screen_ratio;
    unsigned long cvb_dot_idx = key_indices->compiled_vertex_dot_start + did;
    Vertex scaled_dot;
    if (eratio < 1) {
        scaled_dot.x = dots[did].x / scale;
        scaled_dot.y = eratio * dots[did].y / scale;
    } else {
        scaled_dot.x = (dots[did].x / scale) / eratio;
        scaled_dot.y =  dots[did].y / scale;
    }
    scaled_dot.z = 0.5;
    
    scaled_dot.x *= edit_window->z;
    scaled_dot.y *= edit_window->w;
    scaled_dot.x += edit_window->x;
    scaled_dot.y += edit_window->y;
    compiled_vertices[cvb_dot_idx] = scaled_dot;
    
    
    // set (4) dot square corners in cvb
    unsigned long cvb_dot_corner_idx = key_indices->compiled_vertex_dot_square_start + did*4;
    compiled_vertices[cvb_dot_corner_idx+0] = vec_make_float3(scaled_dot.x-0.007, scaled_dot.y-0.007 * screen_ratio, scaled_dot.z-0.01);
    compiled_vertices[cvb_dot_corner_idx+1] = vec_make_float3(scaled_dot.x-0.007, scaled_dot.y+0.007 * screen_ratio, scaled_dot.z-0.01);
    compiled_vertices[cvb_dot_corner_idx+2] = vec_make_float3(scaled_dot.x+0.007, scaled_dot.y-0.007 * screen_ratio, scaled_dot.z-0.01);
    compiled_vertices[cvb_dot_corner_idx+3] = vec_make_float3(scaled_dot.x+0.007, scaled_dot.y+0.007 * screen_ratio, scaled_dot.z-0.01);
    
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
    
    // TODO: SET SPECIAL COLOR FOR SELECTED DOTS
}
