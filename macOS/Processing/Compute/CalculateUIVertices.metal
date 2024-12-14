//
//  CalculateUIVertices.metal
//  dragonfly
//
//  Created by Thomas Liang on 12/14/24.
//

#include <metal_stdlib>
using namespace metal;
#include "../MetalUtil.h"


// operate per ui vertex
// output converted and scaled vertex to compiled vertex buffer
kernel void CalculateUIVertices (
    device Vertex *compiled_vertices [[buffer(0)]],
    const constant UIVertex *ui_vertices[[buffer(1)]],
    const constant unsigned int *element_ids[[buffer(2)]],
    const constant UIElementTransform *element_transforms[[buffer(3)]],
    const constant WindowAttributes *window_attr[[buffer(4)]],
    const constant CompiledBufferKeyIndices *key_indices[[buffer(5)]],
    unsigned int vid [[thread_position_in_grid]]
) {
    // get ui vertex
    UIVertex v = ui_vertices[vid];
    // get transform
    UIElementTransform et = element_transforms[element_ids[vid]];
    // create vertex and set to start of element transform space (in world space)
    Vertex ret;
    ret.x = et.position.x;
    ret.y = et.position.y;
    ret.z = float(et.position.z + v.z)/100;
    
    // transform to vertex location (account for rotated element with right and up vectors)
    ret.x += et.right.x * v.x + et.up.x * v.y;
    ret.y += et.right.y * v.x + et.up.y * v.y;

    // convert to screen coords
    ret.x /= window_attr->width/2;
    ret.y /= window_attr->height/2;
    
    // set in compiled vertex buffer
    unsigned long cvb_ui_start = key_indices->compiled_vertex_ui_start+vid;
    compiled_vertices[cvb_ui_start] = ret;
}
