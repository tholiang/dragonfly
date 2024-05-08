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
	struct vector_float2 {
		float x;
		float y;
	};

	struct vector_float3 {
		float x;
		float y;
		float z;
	};

	struct vector_float4 {
		float x;
		float y;
		float z;
		float w;
	};

	struct vector_int2 {
		int x;
		int y;
	};

	struct vector_int3 {
		int x;
		int y;
		int z;
	};

	struct vector_int4 {
		int x;
		int y;
		int z;
		int w;
	};

	vector_float2 vector_make_float2(float x, float y);
	vector_float3 vector_make_float3(float x, float y, float z);
	vector_float4 vector_make_float4(float x, float y, float z, int w);
	vector_int2 vector_make_int2(int x, int y);
	vector_int3 vector_make_int3(int x, int y, int z);
	vector_int4 vector_make_int4(int x, int y, int z, int w);
}

#endif
