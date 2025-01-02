//
//  MetalUtil.metal
//  dragonfly
//
//  Created by Thomas Liang on 1/2/25.
//

#include <metal_stdlib>
using namespace metal;
#include "MetalUtil.h"

vec_float2 vec_make_float2(float x, float y) {
    vec_float2 ret;
    ret.x = x;
    ret.y = y;
    return ret;
}

vec_float3 vec_make_float3(float x, float y, float z) {
    vec_float3 ret;
    ret.x = x;
    ret.y = y;
    ret.z = z;
    return ret;
}

vec_float4 vec_make_float4(float x, float y, float z, int w) {
    vec_float4 ret;
    ret.x = x;
    ret.y = y;
    ret.z = z;
    ret.w = w;
    return ret;
}

vec_int2 vec_make_int2(int x, int y) {
    vec_int2 ret;
    ret.x = x;
    ret.y = y;
    return ret;
}

vec_int3 vec_make_int3(int x, int y, int z) {
    vec_int3 ret;
    ret.x = x;
    ret.y = y;
    ret.z = z;
    return ret;
}

vec_int4 vec_make_int4(int x, int y, int z, int w) {
    vec_int4 ret;
    ret.x = x;
    ret.y = y;
    ret.z = z;
    ret.w = w;
    return ret;
}

vec_float3 AddVectors(vec_float3 v1, vec_float3 v2) {
    vec_float3 ret;
    ret.x = v1.x + v2.x;
    ret.y = v1.y + v2.y;
    ret.z = v1.z + v2.z;
    return ret;
}

vec_float3 SubtractVectors(vec_float3 v1, vec_float3 v2) {
    vec_float3 ret;
    ret.x = v1.x - v2.x;
    ret.y = v1.y - v2.y;
    ret.z = v1.z - v2.z;
    return ret;
}

vec_float3 cross_product (vec_float3 p1, vec_float3 p2, vec_float3 p3) {
    vec_float3 u = vec_make_float3(p2.x - p1.x, p2.y - p1.y, p2.z - p1.z);
    vec_float3 v = vec_make_float3(p3.x - p1.x, p3.y - p1.y, p3.z - p1.z);
    
    return vec_make_float3(u.y*v.z - u.z*v.y, u.z*v.x - u.x*v.z, u.x*v.y - u.y*v.x);
}

vec_float3 cross_vectors(vec_float3 p1, vec_float3 p2) {
    vec_float3 cross;
    cross.x = p1.y*p2.z - p1.z*p2.y;
    cross.y = -(p1.x*p2.z - p1.z*p2.x);
    cross.z = p1.x*p2.y - p1.y*p2.x;
    return cross;
}

float projection (vec_float3 v1, vec_float3 v2) {
    float dot = v1.x*v2.x + v1.y*v2.y + v1.z*v2.z;
    float mag = sqrt(pow(v2.x, 2) + pow(v2.y, 2) + pow(v2.z, 2));
    return dot / mag;
}

vec_float3 unit_vector(vec_float3 v) {
    float mag = sqrt(pow(v.x, 2) + pow(v.y, 2) + pow(v.z, 2));
    v.x /= mag;
    v.y /= mag;
    v.z /= mag;
    return v;
}

vec_float3 TriAvg (vec_float3 p1, vec_float3 p2, vec_float3 p3) {
    float x = (p1.x + p2.x + p3.x)/3;
    float y = (p1.y + p2.y + p3.y)/3;
    float z = (p1.z + p2.z + p3.z)/3;
    
    return vec_make_float3(x, y, z);
}

float acos2(vec_float3 v1, vec_float3 v2) {
    float dot = v1.x*v2.x + v1.y*v2.y + v1.z*v2.z;
    vec_float3 cross = cross_vectors(v1, v2);
    float det = sqrt(pow(cross.x, 2) + pow(cross.y, 2) + pow(cross.z, 2));
    return atan2(det, dot);
}

float angle_between (vec_float3 v1, vec_float3 v2) {
    float mag1 = sqrt(pow(v1.x, 2) + pow(v1.y, 2) + pow(v1.z, 2));
    float mag2 = sqrt(pow(v2.x, 2) + pow(v2.y, 2) + pow(v2.z, 2));
    
    return acos((v1.x*v2.x + v1.y*v2.y + v1.z*v2.z) / (mag1 * mag2));
}

// TODO: make this not shit pls
vec_float3 PointToPixel (vec_float3 point, constant Camera *camera)  {
    //vector from camera position to object position
    vec_float4 toObject;
    toObject.x = (point.x-camera->pos.x);
    toObject.y = (point.y-camera->pos.y);
    toObject.z = (point.z-camera->pos.z);
    toObject.w = (sqrt(pow(toObject.x, 2)+pow(toObject.y, 2)+pow(toObject.z, 2)));
    
    //project camera vector onto object vector
    float dotProduct = (toObject.x*camera->vector.x)+(toObject.y*camera->vector.y)+(toObject.z*camera->vector.z);
    vec_float4 proj;
    proj.x = dotProduct*camera->vector.x;
    proj.y = dotProduct*camera->vector.y;
    proj.z = dotProduct*camera->vector.z;
    proj.w = sqrt(pow(proj.x, 2)+pow(proj.y, 2)+pow(proj.z, 2));
    
    //subtract projected vector from the object vector to get the "on screen" vector
    vec_float4 distTo;
    distTo.x = toObject.x-proj.x;
    distTo.y = toObject.y-proj.y;
    distTo.z = toObject.z-proj.z;
    distTo.w = sqrt(pow(distTo.x, 2)+pow(distTo.y, 2)+pow(distTo.z, 2));
    
    //angle from vertical on screen - 0 is straight up - counterclockwise
    //use the plane of the camera with normal vector being where the camera is pointing
    //some method to find the angle between 2 vectors in 2pi radians
    //https://stackoverflow.com/questions/14066933/direct-way-of-computing-clockwise-angle-between-2-vectors/16544330#16544330
    
    float dotProductDistToAndCamUp = (distTo.x*camera->upVector.x)+(distTo.y*camera->upVector.y)+(distTo.z*camera->upVector.z);
    float det = (camera->upVector.x*distTo.y*camera->vector.z) + (distTo.x*camera->vector.y*camera->upVector.z) + (camera->vector.x*camera->upVector.y*distTo.z) - (camera->upVector.z*distTo.y*camera->vector.x) - (distTo.z*camera->vector.y*camera->upVector.x) - (camera->vector.z*camera->upVector.y*distTo.x);
    float angleBetween = atan2(det, dotProductDistToAndCamUp);
    //TODO: add twist
    angleBetween = angleBetween/*-camera.vector.z*/;
    
    //find dimensions of the "screen rectangle" at the location of the object
    //FOV is the angle of the field of view - the whole screen
    float halfWidth = abs(proj.w*tan(camera->FOV.x/2));
    float halfHeight = abs(proj.w*tan(camera->FOV.y/2));
    
    //screen location of object
    float xLoc = -distTo.w*sin(angleBetween);
    float yLoc = distTo.w*cos(angleBetween);
    
    //get screen coordinates
    float screenX = 0;
    float screenY = 0;
    if (halfWidth != 0 && halfHeight != 0) {
        screenX = (xLoc)/(halfWidth);
        screenY = (yLoc)/(halfHeight);
    }
    
    // if dot product is negative then the vertex is behind
    if (dotProduct < 0) {
        return vec_make_float3(screenX, screenY, -proj.w/render_dist);
    }
    
    return vec_make_float3(screenX, screenY, proj.w/render_dist);
}

vec_float3 RotateAround (vec_float3 point, vec_float3 origin, vec_float3 angle) {
    vec_float3 vec;
    vec.x = point.x-origin.x;
    vec.y = point.y-origin.y;
    vec.z = point.z-origin.z;
    
    vec_float3 newvec;
    
    // gimbal locked
    
    // around z axis
    newvec.x = vec.x*cos(angle.z)-vec.y*sin(angle.z);
    newvec.y = vec.x*sin(angle.z)+vec.y*cos(angle.z);
    
    vec.x = newvec.x;
    vec.y = newvec.y;
    
    // around y axis
    newvec.x = vec.x*cos(angle.y)+vec.z*sin(angle.y);
    newvec.z = -vec.x*sin(angle.y)+vec.z*cos(angle.y);
    
    vec.x = newvec.x;
    vec.z = newvec.z;
    
    // around x axis
    newvec.y = vec.y*cos(angle.x)-vec.z*sin(angle.x);
    newvec.z = vec.y*sin(angle.x)+vec.z*cos(angle.x);
    
    vec.y = newvec.y;
    vec.z = newvec.z;
    
    point.x = origin.x+vec.x;
    point.y = origin.y+vec.y;
    point.z = origin.z+vec.z;
    
    return point;
}

vec_float3 TranslatePointToStandard(Basis b, vec_float3 point) {
    vec_float3 ret;
    // x component
    ret.x = point.x * b.x.x;
    ret.y = point.x * b.x.y;
    ret.z = point.x * b.x.z;
    // y component
    ret.x += point.y * b.y.x;
    ret.y += point.y * b.y.y;
    ret.z += point.y * b.y.z;
    // z component
    ret.x += point.z * b.z.x;
    ret.y += point.z * b.z.y;
    ret.z += point.z * b.z.z;
    
    ret.x += b.pos.x;
    ret.y += b.pos.y;
    ret.z += b.pos.z;
    
    return ret;
}

vec_float3 TranslatePointToBasis(Basis b, vec_float3 point) {
    vec_float3 ret;
    
    vec_float3 tobasis;
    tobasis.x = point.x - b.pos.x;
    tobasis.y = point.y - b.pos.y;
    tobasis.z = point.z - b.pos.z;
    
    ret.x = projection(tobasis, b.x);
    ret.y = projection(tobasis, b.y);
    ret.z = projection(tobasis, b.z);
    
    return ret;
}

vec_float3 RotatePointToStandard(Basis b, vec_float3 point) {
    vec_float3 ret;
    // x component
    ret.x = point.x * b.x.x;
    ret.y = point.x * b.x.y;
    ret.z = point.x * b.x.z;
    // y component
    ret.x += point.y * b.y.x;
    ret.y += point.y * b.y.y;
    ret.z += point.y * b.y.z;
    // z component
    ret.x += point.z * b.z.x;
    ret.y += point.z * b.z.y;
    ret.z += point.z * b.z.z;
    
    return ret;
}
