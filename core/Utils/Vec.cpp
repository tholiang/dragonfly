#include "Vec.h"

Vec::vector_float2 Vec::vector_make_float2(float x, float y) {
	Vec::vector_float2 ret;
	ret.x = x;
	ret.y = y;
	return ret;
}

Vec::vector_float3 Vec::vector_make_float3(float x, float y, float z) {
	Vec::vector_float3 ret;
	ret.x = x;
	ret.y = y;
	ret.z = z;
	return ret;
}

Vec::vector_float4 Vec::vector_make_float4(float x, float y, float z, int w) {
	Vec::vector_float4 ret;
	ret.x = x;
	ret.y = y;
	ret.z = z;
	ret.w = w;
	return ret;
}

Vec::vector_int2 Vec::vector_make_int2(int x, int y) {
	Vec::vector_int2 ret;
	ret.x = x;
	ret.y = y;
	return ret;
}

Vec::vector_int3 Vec::vector_make_int3(int x, int y, int z) {
	Vec::vector_int3 ret;
	ret.x = x;
	ret.y = y;
	ret.z = z;
	return ret;
}

Vec::vector_int4 Vec::vector_make_int4(int x, int y, int z, int w) {
	Vec::vector_int4 ret;
	ret.x = x;
	ret.y = y;
	ret.z = z;
	ret.w = w;
	return ret;
}