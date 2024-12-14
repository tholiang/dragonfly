//
//  CalculateModelNodeTransforms.metal
//  dragonfly
//
//  Created by Thomas Liang on 12/14/24.
//

#include <metal_stdlib>
using namespace metal;
#include "util.h"

// transform list of model (scene + control) nodes in Model Space to World Space
// operate per node
kernel void CalculateModelNodeTransforms(
    device Node *nodes [[buffer(0)]],
    const constant unsigned int *modelIDs [[buffer(1)]],
    const constant ModelTransform *uniforms [[buffer(2)]],
    unsigned int nid [[thread_position_in_grid]]
) {
    ModelTransform uniform = uniforms[modelIDs[nid]];
    nodes[nid].b.pos = TranslatePointToStandard(uniform.b, nodes[nid].b.pos);
    nodes[nid].b.x = RotatePointToStandard(uniform.b, nodes[nid].b.x);
    nodes[nid].b.y = RotatePointToStandard(uniform.b, nodes[nid].b.y);
    nodes[nid].b.z = RotatePointToStandard(uniform.b, nodes[nid].b.z);
}
