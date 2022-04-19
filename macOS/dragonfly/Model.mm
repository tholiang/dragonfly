//
//  Model.m
//  dragonfly
//
//  Created by Thomas Liang on 1/15/22.
//

#import <Foundation/Foundation.h>
#include "Model.h"
#include <cstddef>
#include <iostream>

Model::Model(uint32 mid) : modelID(mid) {
    
}

unsigned Model::MakeVertex(float x, float y, float z) {
    vertices.push_back(simd_make_float3(x, y, z));
    return vertices.size()-1;
}

unsigned Model::MakeFace(unsigned v0, unsigned v1, unsigned v2, simd_float4 color) {
    Face f = Face();
    f.vertices[0] = v0;
    f.vertices[1] = v1;
    f.vertices[2] = v2;
    f.color = color;
    faces.push_back(f);
    return faces.size()-1;
}

void Model::MakeCube() {
    MakeVertex(0, 0, 0);
    MakeVertex(1, 0, 0);
    MakeVertex(0, 1, 0);
    MakeVertex(1, 1, 0);
    MakeVertex(0, 0, 1);
    MakeVertex(1, 0, 1);
    MakeVertex(0, 1, 1);
    MakeVertex(1, 1, 1);
    
    MakeFace(1, 0, 2, {1, 1, 1, 1});
    MakeFace(2, 3, 1, {1, 1, 1, 1});
    
    MakeFace(1, 0, 4, {1, 1, 1, 1});
    MakeFace(4, 5, 1, {1, 1, 1, 1});
    
    MakeFace(2, 0, 4, {1, 1, 1, 1});
    MakeFace(2, 6, 4, {1, 1, 1, 1});
    
    MakeFace(3, 2, 6, {1, 1, 1, 1});
    MakeFace(3, 7, 6, {1, 1, 1, 1});
    
    MakeFace(3, 1, 5, {1, 1, 1, 1});
    MakeFace(5, 7, 3, {1, 1, 1, 1});
    
    MakeFace(5, 4, 6, {1, 1, 1, 1});
    MakeFace(5, 7, 6, {1, 1, 1, 1});
}

std::vector<simd_float3> &Model::GetVertices() {
    return vertices;
}

std::vector<Face> &Model::GetFaces() {
    return faces;
}

void Model::AddToBuffers(std::vector<simd_float3> &vertexBuffer, std::vector<Face> &faceBuffer, std::vector<uint32> &modelIDs, int vertexStart) {
    for (int i = 0; i < vertices.size(); i++) {
        vertexBuffer.push_back(vertices[i]);
        modelIDs.push_back(modelID);
    }
    
    for (int i = 0; i < faces.size(); i++) {
        Face og = faces[i];
        Face face;
        face.color = og.color;
        face.vertices[0] = og.vertices[0]+vertexStart;
        face.vertices[1] = og.vertices[1]+vertexStart;
        face.vertices[2] = og.vertices[2]+vertexStart;
        faceBuffer.push_back(face);
    }
}

uint32 Model::ModelID() {
    return modelID;
}

Model::~Model() {
}
