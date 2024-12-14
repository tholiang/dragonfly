//
//  CalculateFaceLighting.metal
//  dragonfly
//
//  Created by Thomas Liang on 12/14/24.
//

#include <metal_stdlib>
using namespace metal;
#include "util.h"


// operate per face (of scene models only)
// output lit faces into compiled face buffer
kernel void CalculateFaceLighting(
   device Face *compiled_faces [[buffer(0)]],
   const constant Face *faces[[buffer(1)]],
   const constant Vertex *vertices [[buffer(2)]],
   constant unsigned int& num_lights [[buffer(3)]],
   const constant SimpleLight *lights[[buffer(4)]],
   const constant CompiledBufferKeyIndices *key_indices[[buffer(5)]],
   unsigned int fid[[thread_position_in_grid]]
) {
    // get scene face and calculate normal
    Face f = faces[fid];
    vec_float3 f_norm = cross_product(vertices[f.vertices[0]], vertices[f.vertices[1]], vertices[f.vertices[2]]);
    if (f.normal_reversed != 0) {
        f_norm.x *= -1;
        f_norm.y *= -1;
        f_norm.z *= -1;
    }
    
    // get angle between normal and light
    Vertex center = TriAvg(vertices[f.vertices[0]], vertices[f.vertices[1]], vertices[f.vertices[2]]);
    
    vec_float4 endcolor = vec_make_float4(0, 0, 0, f.color.w);
    for (unsigned int i = 0; i < num_lights; i++) {
        // get light intensity at face point
        vec_float3 light_basis_point = TranslatePointToBasis(lights[i].b, center);
        float d = 1 / sqrt(pow(light_basis_point.x, 2) + pow(light_basis_point.y, 2) + pow(light_basis_point.z, 2));
        float a = 1 / angle_between(light_basis_point, vec_make_float3(1, 0, 0));
        float dmod = lights[i].distance_falloff.x * pow(d, 2) + lights[i].distance_falloff.y * d + lights[i].distance_falloff.z;
        float amod = lights[i].angle_falloff.x * pow(a, 2) + lights[i].angle_falloff.y * a + lights[i].angle_falloff.z;
        float intens = lights[i].max_intensity * dmod * amod;

        // get angle between normal and light
        vec_float3 rev_dir = unit_vector(SubtractVectors(lights[i].b.pos, center));
        float ang = 1 - abs(angle_between(f_norm, rev_dir)) / pi;
        intens *= ang * f.shading_multiplier;

        // get color
        endcolor.x += f.color.x * intens * lights[i].color.x;
        endcolor.y += f.color.y * intens * lights[i].color.y;
        endcolor.z += f.color.z * intens * lights[i].color.z;
    }
    
    // set face in compiled face buffer
    f.color = endcolor;
    unsigned int cfb_scene_face_idx = key_indices->compiled_face_scene_start+fid;
    compiled_faces[cfb_scene_face_idx] = f;
}
