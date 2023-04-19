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
#include <iostream>

#include <simd/SIMD.h>

#include "imgui.h"

namespace DragonflyUtils {
bool InIntVector(std::vector<int> &vec, int a);
bool isInt( std::string str );
bool isFloat( std::string str );
bool isUnsignedLong( std::string str );
std::vector<float> splitStringToFloats (std::string str);
simd_float3 TriAvg (simd_float3 p1, simd_float3 p2, simd_float3 p3);
simd_float3 BiAvg (simd_float3 p1, simd_float3 p2);
float sign2D (simd_float2 p1, simd_float2 p2, simd_float2 p3);
float sign (simd_float2 p1, simd_float3 p2, simd_float3 p3);
float dist2to3 (simd_float2 p1, simd_float3 p2);
float dist3to3 (simd_float3 p1, simd_float3 p2);
float acos2(simd_float3 v1, simd_float3 v2);
float WeightedZ (simd_float2 click, simd_float3 p1, simd_float3 p2, simd_float3 p3);
float Magnitude (simd_float3 v);
simd_float3 CrossProduct (simd_float3 p1, simd_float3 p2);
float DotProduct (simd_float3 p1, simd_float3 p2);
simd_float3 ScaleVector (simd_float3 v, float k);
simd_float3 AddVectors (simd_float3 v1, simd_float3 v2);
float Projection (simd_float3 v1, simd_float3 v2);
bool InTriangle2D(vector_float2 point, simd_float2 v1, simd_float2 v2, simd_float2 v3);
bool InTriangle(vector_float2 point, simd_float3 v1, simd_float3 v2, simd_float3 v3);
bool InRectangle(vector_float2 top_left, vector_float2 size, vector_float2 loc);
simd_float3 RotateAround (simd_float3 point, simd_float3 origin, simd_float3 angle);
simd_float3 GetNormal(simd_float3 p1, simd_float3 p2, simd_float3 p3);
simd_float4 PlaneEquation(simd_float3 p1, simd_float3 p2, simd_float3 p3);
float LineAndPlane(simd_float3 start, simd_float3 vector, simd_float4 plane);
float TriangleArea(simd_float3 p1, simd_float3 p2, simd_float3 p3);
simd_float3 DistancePolynomial(simd_float3 start, simd_float3 vector, simd_float3 origin); // at ^ 2 + bt + c
float AngleBetween(simd_float3 v1, simd_float3 v2);
float GetAcute(float angle);
float QuadraticEquation(simd_float3 coeff);
std::string TextField(std::string input, std::string name);
}

#endif /* Utils_h */
