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
    name = "model"+std::to_string(mid);
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

void Model::InsertVertex(simd_float3 vertex, int vid) {
    if (vid >= vertices.size()) {
        vertices.push_back(vertex);
    } else {
        vertices.insert(vertices.begin()+vid, vertex);
    }
}

void Model::InsertFace(Face face, int fid) {
    if (fid >= faces.size()) {
        faces.push_back(face);
    } else {
        faces.insert(faces.begin()+fid, face);
    }
}

void Model::RemoveVertex(int vid) {
    if (vid < vertices.size()) {
        vertices.erase(vertices.begin() + vid);
    }
}

void Model::RemoveFace(int fid) {
    if (fid < faces.size()) {
        faces.erase(faces.begin() + fid);
    }
}

Face *Model::GetFace(unsigned long fid) {
    return &faces.at(fid);
}

simd_float3 *Model::GetVertex(unsigned long vid) {
    return &vertices.at(vid);
}

std::vector<unsigned long> Model::GetEdgeFaces(unsigned long vid1, unsigned long vid2) {
    std::vector<unsigned long> ret;
    
    for (std::size_t fid = 0; fid < faces.size(); fid++) {
        Face f = faces[fid];
        if (f.vertices[0] == vid1 || f.vertices[1] == vid1 || f.vertices[2] == vid1) {
            if (f.vertices[0] == vid2 || f.vertices[1] == vid2 || f.vertices[2] == vid2) {
                ret.push_back(fid);
            }
        }
    }
    
    return ret;
}

std::vector<simd_float3> &Model::GetVertices() {
    return vertices;
}

std::vector<Face> &Model::GetFaces() {
    return faces;
}

void Model::AddToBuffers(std::vector<simd_float3> &vertexBuffer, std::vector<Face> &faceBuffer, std::vector<uint32> &modelIDs) {
    face_start = faceBuffer.size();
    vertex_start = vertexBuffer.size();
    
    for (int i = 0; i < vertices.size(); i++) {
        vertexBuffer.push_back(vertices[i]);
        modelIDs.push_back(modelID);
    }
    
    for (int i = 0; i < faces.size(); i++) {
        Face og = faces[i];
        Face face;
        face.color = og.color;
        face.vertices[0] = og.vertices[0]+vertex_start;
        face.vertices[1] = og.vertices[1]+vertex_start;
        face.vertices[2] = og.vertices[2]+vertex_start;
        faceBuffer.push_back(face);
    }
}

uint32 Model::ModelID() {
    return modelID;
}

unsigned long Model::FaceStart() {
    return face_start;
}

unsigned long Model::VertexStart() {
    return vertex_start;
}

unsigned long Model::NumFaces() {
    return faces.size();
}

unsigned long Model::NumVertices() {
    return vertices.size();
}

std::string Model::GetName() {
    return name;
}

Model::~Model() {
}
