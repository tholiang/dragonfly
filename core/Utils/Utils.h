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
vector_float3 TriAvg (vector_float3 p1, vector_float3 p2, vector_float3 p3);
vector_float3 BiAvg (vector_float3 p1, vector_float3 p2);
float sign2D (vector_float2 p1, vector_float2 p2, vector_float2 p3);
float sign (vector_float2 p1, vector_float3 p2, vector_float3 p3);
float dist2to3 (vector_float2 p1, vector_float3 p2);
float dist3to3 (vector_float3 p1, vector_float3 p2);
float acos2(vector_float3 v1, vector_float3 v2);
float WeightedZ (vector_float2 click, vector_float3 p1, vector_float3 p2, vector_float3 p3);
float Magnitude (vector_float3 v);
vector_float3 CrossProduct (vector_float3 p1, vector_float3 p2);
float DotProduct (vector_float3 p1, vector_float3 p2);
vector_float3 ScaleVector (vector_float3 v, float k);
vector_float3 AddVectors (vector_float3 v1, vector_float3 v2);
float Projection (vector_float3 v1, vector_float3 v2);
bool InTriangle2D(vector_float2 point, vector_float2 v1, vector_float2 v2, vector_float2 v3);
bool InTriangle(vector_float2 point, vector_float3 v1, vector_float3 v2, vector_float3 v3);
bool InRectangle(vector_float2 top_left, vector_float2 size, vector_float2 loc);
vector_float3 RotateAround (vector_float3 point, vector_float3 origin, vector_float3 angle);
vector_float3 GetNormal(vector_float3 p1, vector_float3 p2, vector_float3 p3);
vector_float4 PlaneEquation(vector_float3 p1, vector_float3 p2, vector_float3 p3);
float LineAndPlane(vector_float3 start, vector_float3 vector, vector_float4 plane);
float TriangleArea(vector_float3 p1, vector_float3 p2, vector_float3 p3);
vector_float3 DistancePolynomial(vector_float3 start, vector_float3 vector, vector_float3 origin); // at ^ 2 + bt + c
float AngleBetween(vector_float3 v1, vector_float3 v2);
float GetAcute(float angle);
float QuadraticEquation(vector_float3 coeff);
std::string TextField(std::string input, std::string name);
}

#endif /* Utils_h */
