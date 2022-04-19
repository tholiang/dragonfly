//
//  Model.h
//  dragonfly
//
//  Created by Thomas Liang on 1/15/22.
//

#ifndef Model_h
#define Model_h
#include <stdio.h>
#include <vector>

#include <simd/SIMD.h>


struct Face {
    uint32 vertices[3];
    simd_float4 color;
};

class Model {
private:
    std::vector<Face> faces;
    std::vector<simd_float3> vertices;
    uint32 modelID;
    
public:
    Model(uint32 mid);
    unsigned MakeVertex(float x, float y, float z);
    unsigned MakeFace(unsigned v0, unsigned v1, unsigned v2, simd_float4 color);
    void MakeCube();
    
    std::vector<simd_float3> &GetVertices();
    std::vector<Face> &GetFaces();
    
    void AddToBuffers(std::vector<simd_float3> &vertexBuffer, std::vector<Face> &faceBuffer, std::vector<uint32> &modelIDs, int vertexStart);
    uint32 ModelID();
    
    ~Model();
};

#endif /* Model_h */
