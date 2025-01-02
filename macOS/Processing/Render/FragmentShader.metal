//
//  FragmentShader.metal
//  dragonfly
//
//  Created by Thomas Liang on 12/14/24.
//

#include <metal_stdlib>
using namespace metal;
#include "../MetalUtil.h"


// fragment shader - return interpolated color exactly
fragment vector_float4 FragmentShader(
    VertexOut interpolated [[stage_in]]
) {
    return interpolated.color;
}
