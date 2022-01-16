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

struct Vertex {
    simd_float3 position;
    std::vector<Vertex*> connected;
};

struct Face {
    Vertex *vertices[3];
    simd_float4 color;
};

class Model {
    std::vector<Face*> faces;
    std::vector<Vertex*> vertices;
    //std::vector<Vertex*> render_vertices;
    
public:
    Model();
    Vertex* MakeVertex(float x, float y, float z);
    Face* MakeFace(Vertex* v0, Vertex* v1, Vertex* v2, simd_float4 color);
    void MakeCube();
    
    std::vector<simd_float3> *GetRenderVertices();
    std::vector<simd_float4> *GetRenderColors();
    
    ~Model();
};

#endif /* Model_h */
