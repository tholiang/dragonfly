//
//  Processing.metal
//  dragonfly
//
//  Created by Thomas Liang on 5/27/21.
//

#include <metal_stdlib>
using namespace metal;

constant float pi = 3.14159265358979;
constant float render_dist = 50;

struct Camera {
    vector_float3 pos;
    vector_float3 vector;
    vector_float3 upVector;
    vector_float2 FOV;
};

struct VertexOut {
    vector_float4 pos [[position]];
    vector_float4 color;
};

struct Uniforms {
    unsigned int numFaces;
    unsigned int selectedFace;
};

//convert a 3d point to a pixel (vertex) value
vector_float3 PointToPixel (vector_float3 point, Camera camera)  {
    //vector from camera position to object position
    vector_float4 toObject;
    toObject.x = (point.x-camera.pos.x);
    toObject.y = (point.y-camera.pos.y);
    toObject.z = (point.z-camera.pos.z);
    toObject.w = (sqrt(pow(toObject.x, 2)+pow(toObject.y, 2)+pow(toObject.z, 2)));
    
    //project camera vector onto object vector
    float dotProduct = (toObject.x*camera.vector.x)+(toObject.y*camera.vector.y)+(toObject.z*camera.vector.z);
    vector_float4 proj;
    proj.x = dotProduct*camera.vector.x;
    proj.y = dotProduct*camera.vector.y;
    proj.z = dotProduct*camera.vector.z;
    proj.w = sqrt(pow(proj.x, 2)+pow(proj.y, 2)+pow(proj.z, 2));
    
    //subtract projected vector from the object vector to get the "on screen" vector
    vector_float4 distTo;
    distTo.x = toObject.x-proj.x;
    distTo.y = toObject.y-proj.y;
    distTo.z = toObject.z-proj.z;
    distTo.w = sqrt(pow(distTo.x, 2)+pow(distTo.y, 2)+pow(distTo.z, 2));
    
    //angle from vertical on screen - 0 is straight up - counterclockwise
    //use the plane of the camera with normal vector being where the camera is pointing
    //some method to find the angle between 2 vectors in 2pi radians
    //https://stackoverflow.com/questions/14066933/direct-way-of-computing-clockwise-angle-between-2-vectors/16544330#16544330
    
    float dotProductDistToAndCamUp = (distTo.x*camera.upVector.x)+(distTo.y*camera.upVector.y)+(distTo.z*camera.upVector.z);
    float det = (camera.upVector.x*distTo.y*camera.vector.z) + (distTo.x*camera.vector.y*camera.upVector.z) + (camera.vector.x*camera.upVector.y*distTo.z) - (camera.upVector.z*distTo.y*camera.vector.x) - (distTo.z*camera.vector.y*camera.upVector.x) - (camera.vector.z*camera.upVector.y*distTo.x);
    float angleBetween = atan2(det, dotProductDistToAndCamUp);
    //TODO: add twist
    angleBetween = angleBetween/*-camera.vector.z*/;
    
    //find dimensions of the "screen rectangle" at the location of the object
    //FOV is the angle of the field of view - the whole screen
    float halfWidth = abs(proj.w*tan(camera.FOV.x/2));
    float halfHeight = abs(proj.w*tan(camera.FOV.y/2));
    
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
        return vector_float3(screenX, screenY, -proj.w/render_dist);
    }
    
    return vector_float3(screenX, screenY, proj.w/render_dist);
}

kernel void CalculateProjectedVertices(device vector_float3 *vertices [[buffer(0)]], unsigned int vid [[thread_position_in_grid]], constant Camera &camera [[buffer(1)]]) {
    vertices[vid] = PointToPixel(vertices[vid], camera);
}

vertex VertexOut DefaultVertexShader (const constant vector_float3 *vertex_array [[buffer(0)]], const constant vector_float4 *color_array, unsigned int vid [[vertex_id]]) {
    vector_float3 currentVertex = vertex_array[vid];
    VertexOut output;
    output.pos = vector_float4(currentVertex.x, currentVertex.y, currentVertex.z, 1);
    output.color = color_array[vid/4];
    return output;
}

vertex VertexOut ProjectionCalculationVertexShader (const constant vector_float3 *vertex_array [[buffer(0)]], unsigned int vid [[vertex_id]], const constant vector_float4 *color_array [[buffer(1)]], constant Camera &camera [[buffer(2)]]/*, constant Uniforms &uniforms [[buffer(3)]]*/) {
    vector_float3 currentVertex = vertex_array[vid];
    VertexOut output;
    
    vector_float3 pixel = PointToPixel(currentVertex, camera);
    
    output.pos = vector_float4(pixel.x, pixel.y, pixel.z, 1.0);
    
    output.color = color_array[vid/4];
    
    return output;
}

vertex VertexOut VertexEdgeShader (const constant vector_float3 *vertex_array [[buffer(0)]], unsigned int vid [[vertex_id]]) {
    vector_float3 currentVertex = vertex_array[vid];
    VertexOut output;
    output.pos = vector_float4(currentVertex.x, currentVertex.y, currentVertex.z, 1);
    output.color = vector_float4(0, 0, 1, 1);
    return output;
}

fragment vector_float4 FragmentShader(VertexOut interpolated [[stage_in]]){
    return interpolated.color;
}
