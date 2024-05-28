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
#include <cmath>

#include "Utils/Vec.h"
using namespace Vec;

#include "imgui.h"

namespace DragonflyUtils {
bool InIntVector(std::vector<int> &vec, int a);
bool isInt( std::string str );
bool isFloat( std::string str );
bool isUnsignedLong( std::string str );
std::vector<float> splitStringToFloats (std::string str);
vec_float3 TriAvg (vec_float3 p1, vec_float3 p2, vec_float3 p3);
vec_float3 BiAvg (vec_float3 p1, vec_float3 p2);
float sign2D (vec_float2 p1, vec_float2 p2, vec_float2 p3);
float sign (vec_float2 p1, vec_float3 p2, vec_float3 p3);
float dist2to3 (vec_float2 p1, vec_float3 p2);
float dist3to3 (vec_float3 p1, vec_float3 p2);
vec_float3 unit_vector(vec_float3 v);
float acos2(vec_float3 v1, vec_float3 v2);
float WeightedZ (vec_float2 click, vec_float3 p1, vec_float3 p2, vec_float3 p3);
float Magnitude (vec_float3 v);
vec_float3 CrossProduct (vec_float3 p1, vec_float3 p2);
float DotProduct (vec_float3 p1, vec_float3 p2);
vec_float3 ScaleVector (vec_float3 v, float k);
vec_float3 AddVectors (vec_float3 v1, vec_float3 v2);
float Projection (vec_float3 v1, vec_float3 v2);
float PointToPlane (vec_float3 orig, vec_float3 n, vec_float3 p);
bool InTriangle2D(vec_float2 point, vec_float2 v1, vec_float2 v2, vec_float2 v3);
bool InTriangle3D(vec_float3 point, vec_float3 v1, vec_float3 v2, vec_float3 v3, float sep);
bool InTriangle(vec_float2 point, vec_float3 v1, vec_float3 v2, vec_float3 v3);
bool InRectangle(vec_float2 top_left, vec_float2 size, vec_float2 loc);
vec_float3 RotateAround (vec_float3 point, vec_float3 origin, vec_float3 angle);
vec_float3 GetNormal(vec_float3 p1, vec_float3 p2, vec_float3 p3);
vec_float4 PlaneEquation(vec_float3 p1, vec_float3 p2, vec_float3 p3);
float LineAndPlane(vec_float3 start, vec_float3 vector, vec_float4 plane);
float TriangleArea(vec_float3 p1, vec_float3 p2, vec_float3 p3);
vec_float3 DistancePolynomial(vec_float3 start, vec_float3 vector, vec_float3 origin); // at ^ 2 + bt + c
float AngleBetween(vec_float3 v1, vec_float3 v2);
float GetAcute(float angle);
float QuadraticEquation(vec_float3 coeff);
std::string TextField(std::string input, std::string name);
}

#endif /* Utils_h */
