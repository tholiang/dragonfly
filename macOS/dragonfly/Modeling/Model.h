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
    uint32_t vertices[3];
    simd_float4 color;
};

class Model {
private:
    std::vector<Face> faces;
    std::vector<simd_float3> vertices;
    uint32_t modelID;
    unsigned long face_start;
    unsigned long vertex_start;
    
public:
    Model(uint32_t mid);
    unsigned MakeVertex(float x, float y, float z);
    unsigned MakeFace(unsigned v0, unsigned v1, unsigned v2, simd_float4 color);
    void MakeCube();
    
    void InsertVertex(simd_float3 vertex, int vid);
    void InsertFace(Face face, int fid);
    
    void RemoveVertex(int vid);
    void RemoveFace(int fid);
    
    Face *GetFace(unsigned long fid);
    simd_float3 *GetVertex(unsigned long vid);
    std::vector<unsigned long> GetEdgeFaces(unsigned long vid1, unsigned long vid2);
    
    std::vector<simd_float3> &GetVertices();
    std::vector<Face> &GetFaces();
    
    void AddToBuffers(std::vector<simd_float3> &vertexBuffer, std::vector<Face> &faceBuffer, std::vector<uint32_t> &modelIDs);
    uint32_t ModelID();
    unsigned long FaceStart();
    unsigned long VertexStart();
    
    unsigned long NumFaces();
    unsigned long NumVertices();
    
    ~Model();
};

#endif /* Model_h */
