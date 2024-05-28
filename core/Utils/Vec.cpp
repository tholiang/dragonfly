#include "Vec.h"

Vec::vec_float3 Vec::vec_float3::operator+(Vec::vec_float3 other) {
    return vec_make_float3(other.x + x, other.y + y, other.z + z);
}

Vec::vec_float3 Vec::vec_float3::operator-(Vec::vec_float3 other) {
    return vec_make_float3(x - other.x, y - other.y, z - other.z);
}

Vec::vec_float2 Vec::vec_make_float2(float x, float y) {
	Vec::vec_float2 ret;
	ret.x = x;
	ret.y = y;
	return ret;
}

Vec::vec_float3 Vec::vec_make_float3(float x, float y, float z) {
	Vec::vec_float3 ret;
	ret.x = x;
	ret.y = y;
	ret.z = z;
	return ret;
}

Vec::vec_float4 Vec::vec_make_float4(float x, float y, float z, int w) {
	Vec::vec_float4 ret;
	ret.x = x;
	ret.y = y;
	ret.z = z;
	ret.w = w;
	return ret;
}

Vec::vec_int2 Vec::vec_make_int2(int x, int y) {
	Vec::vec_int2 ret;
	ret.x = x;
	ret.y = y;
	return ret;
}

Vec::vec_int3 Vec::vec_make_int3(int x, int y, int z) {
	Vec::vec_int3 ret;
	ret.x = x;
	ret.y = y;
	ret.z = z;
	return ret;
}

Vec::vec_int4 Vec::vec_make_int4(int x, int y, int z, int w) {
	Vec::vec_int4 ret;
	ret.x = x;
	ret.y = y;
	ret.z = z;
	ret.w = w;
	return ret;
}
