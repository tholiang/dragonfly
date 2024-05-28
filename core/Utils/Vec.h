#pragma once
#ifndef Vec_h
#define Vec_h

#include <stdio.h>
#include <vector>
#include <string>
#include <sstream>
#include <iostream>

#include "imgui.h"

namespace Vec {
	struct vec_float2 {
		float x;
		float y;
	};

	struct vec_float3 {
		float x;
		float y;
		float z;
        vec_float3 operator+(vec_float3 other);
        vec_float3 operator-(vec_float3 other);
	};

	struct vec_float4 {
		float x;
		float y;
		float z;
		float w;
	};

	struct vec_int2 {
		int x;
		int y;
	};

	struct vec_int3 {
		int x;
		int y;
		int z;
	};

	struct vec_int4 {
		int x;
		int y;
		int z;
		int w;
	};

	vec_float2 vec_make_float2(float x, float y);
	vec_float3 vec_make_float3(float x, float y, float z);
	vec_float4 vec_make_float4(float x, float y, float z, int w);
	vec_int2 vec_make_int2(int x, int y);
	vec_int3 vec_make_int3(int x, int y, int z);
	vec_int4 vec_make_int4(int x, int y, int z, int w);
}

#endif
