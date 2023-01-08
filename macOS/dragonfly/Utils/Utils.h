//
//  Utils.h
//  dragonfly
//
//  Created by Thomas Liang on 7/5/22.
//

#ifndef Utils_h
#define Utils_h

#include <stdio.h>
#include <vector>
#include <string>
#include <sstream>

#include <simd/SIMD.h>

#include "imgui.h"

namespace DragonflyUtils {
bool isFloat( std::string str );
bool isUnsignedLong( std::string str );
std::vector<float> splitStringToFloats (std::string str);
simd_float3 TriAvg (simd_float3 p1, simd_float3 p2, simd_float3 p3);
simd_float3 BiAvg (simd_float3 p1, simd_float3 p2);
float sign2D (simd_float2 p1, simd_float2 p2, simd_float2 p3);
float sign (simd_float2 p1, simd_float3 p2, simd_float3 p3);
float dist2to3 (simd_float2 p1, simd_float3 p2);
float dist3to3 (simd_float3 p1, simd_float3 p2);
float WeightedZ (simd_float2 click, simd_float3 p1, simd_float3 p2, simd_float3 p3);
simd_float3 CrossProduct (simd_float3 p1, simd_float3 p2);
bool InTriangle2D(vector_float2 point, simd_float2 v1, simd_float2 v2, simd_float2 v3);
bool InTriangle(vector_float2 point, simd_float3 v1, simd_float3 v2, simd_float3 v3);
bool InRectangle(vector_float2 top_left, vector_float2 size, vector_float2 loc);
simd_float3 RotateAround (simd_float3 point, simd_float3 origin, simd_float3 angle);
std::string TextField(std::string input, std::string name);
}

#endif /* Utils_h */
