//
//  MetalUtil.h
//  dragonfly
//
//  Created by Thomas Liang on 12/14/24.
//

#ifndef MetalUtil_h
#define MetalUtil_h
#include "MetalDatatypes.h"

// ---HELPER FUNCTIONS---
// vec
vec_float2 vec_make_float2(float x, float y);

vec_float3 vec_make_float3(float x, float y, float z);

vec_float4 vec_make_float4(float x, float y, float z, int w);

vec_int2 vec_make_int2(int x, int y);

vec_int3 vec_make_int3(int x, int y, int z);

vec_int4 vec_make_int4(int x, int y, int z, int w);

// add two 3D vectors
vec_float3 AddVectors(vec_float3 v1, vec_float3 v2);

// subtract two 3D vectors
vec_float3 SubtractVectors(vec_float3 v1, vec_float3 v2);

// calculate cross product of 3D triangle
vec_float3 cross_product (vec_float3 p1, vec_float3 p2, vec_float3 p3);

// calculate cross product of 3D vectors
vec_float3 cross_vectors(vec_float3 p1, vec_float3 p2);

// calculate projection
float projection (vec_float3 v1, vec_float3 v2);

vec_float3 unit_vector(vec_float3 v);

// calculate average of three 3D points
vec_float3 TriAvg (vec_float3 p1, vec_float3 p2, vec_float3 p3);

// idk what this is tbh
float acos2(vec_float3 v1, vec_float3 v2);

// calculate angle between 3D vectors
float angle_between (vec_float3 v1, vec_float3 v2);

// convert a 3d point to a pixel (vertex) value
vec_float3 PointToPixel (vec_float3 point, constant Camera *camera);

// rotate a point around a point
vec_float3 RotateAround (vec_float3 point, vec_float3 origin, vec_float3 angle);

// translate point from given basis to standard basis
vec_float3 TranslatePointToStandard(Basis b, vec_float3 point);

// translate point from standard basis to given basis
vec_float3 TranslatePointToBasis(Basis b, vec_float3 point);

// rotate point from given basis to standard basis (ignore basis translation offset)
vec_float3 RotatePointToStandard(Basis b, vec_float3 point);

#endif /* MetalUtil_h */
