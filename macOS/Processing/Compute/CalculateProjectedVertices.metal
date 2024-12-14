//
//  CalculateProjectedVertices.metal
//  dragonfly
//
//  Created by Thomas Liang on 12/14/24.
//

#include <metal_stdlib>
using namespace metal;
#include "util.h"


// calculate projected vertices from model (scene + control) vertices
// operate per input/output vertex
kernel void CalculateProjectedVertices(
    device Vertex *compiled_vertices [[buffer(0)]],
    const constant Vertex *vertices [[buffer(1)]],
    constant Camera &camera [[buffer(2)]],
    const constant CompiledBufferKeyIndices *key_indices [[buffer(3)]],
    unsigned int vid [[thread_position_in_grid]]
) {
    // calculate projected vertices and place into compiled buffer
    compiled_vertices[vid+key_indices->compiled_vertex_scene_start] = PointToPixel(vertices[vid], camera);
    compiled_vertices[vid+key_indices->compiled_vertex_scene_start].z += 0.05;
}
