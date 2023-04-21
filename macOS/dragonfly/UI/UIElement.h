//
//  UIElement.h
//  dragonfly
//
//  Created by Thomas Liang on 4/21/23.
//

#ifndef UIElement_h
#define UIElement_h

#include <stdio.h>
#include <vector>
#include <string>

#include <simd/SIMD.h>
#include <fstream>

#include "../Utils/Utils.h"

typedef simd_int3 UIVertex;

struct UIFace {
    uint32_t vertices[3];
    simd_float4 color;
};

class UIElement {
private:
    std::vector<UIFace *> faces;
    std::vector<UIVertex> vertices;
    
    uint32_t elementID;
    
    unsigned long face_start = 0;
    unsigned long vertex_start = 0;
    
public:
    UIElement(uint32_t eid);
    ~UIElement();
    
    int MakeVertex(int x, int y, int z);
    int MakeFace(int v0, int v1, int v2, simd_float4 color);
    
    UIVertex *GetVertex(int vid);
    UIFace *GetFace(int fid);
    
    void AddToBuffers(std::vector<UIFace> &faceBuffer, std::vector<UIVertex> &vertexBuffer);
    uint32_t ElementID();
    
    unsigned long FaceStart();
    unsigned long VertexStart();
    
    unsigned long NumFaces();
    unsigned long NumVertices();
};

#endif /* UIElement_h */
