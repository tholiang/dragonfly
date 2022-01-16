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

Model::Model() {
    
}

Vertex* Model::MakeVertex(float x, float y, float z) {
    Vertex *v = new Vertex();
    v->position = {x, y, z};
    return v;
}

Face* Model::MakeFace(Vertex* v0, Vertex* v1, Vertex* v2, simd_float4 color) {
    Face *f = new Face();
    f->vertices[0] = v0;
    f->vertices[1] = v1;
    f->vertices[2] = v2;
    f->color = color;
    return f;
}

void Model::MakeCube() {
    Vertex *v0 = MakeVertex(0, 0, 0);
    Vertex *v1 = MakeVertex(1, 0, 0);
    Vertex *v2 = MakeVertex(0, 1, 0);
    Vertex *v3 = MakeVertex(1, 1, 0);
    Vertex *v4 = MakeVertex(0, 0, 1);
    Vertex *v5 = MakeVertex(1, 0, 1);
    Vertex *v6 = MakeVertex(0, 1, 1);
    Vertex *v7 = MakeVertex(1, 1, 1);
    
    faces.push_back(MakeFace(v0, v1, v2, {1, 1, 1, 1}));
    faces.push_back(MakeFace(v1, v2, v3, {1, 1, 1, 1}));
    
    faces.push_back(MakeFace(v0, v4, v1, {1, 1, 1, 1}));
    faces.push_back(MakeFace(v4, v1, v5, {1, 1, 1, 1}));
    
    faces.push_back(MakeFace(v0, v4, v2, {1, 1, 1, 1}));
    faces.push_back(MakeFace(v2, v6, v4, {1, 1, 1, 1}));
    
    faces.push_back(MakeFace(v2, v6, v3, {1, 1, 1, 1}));
    faces.push_back(MakeFace(v6, v3, v7, {1, 1, 1, 1}));
    
    faces.push_back(MakeFace(v1, v5, v3, {1, 1, 1, 1}));
    faces.push_back(MakeFace(v5, v3, v7, {1, 1, 1, 1}));
    
    faces.push_back(MakeFace(v4, v5, v6, {1, 1, 1, 1}));
    faces.push_back(MakeFace(v5, v6, v7, {1, 1, 1, 1}));
    
    vertices.push_back(v0);
    vertices.push_back(v1);
    vertices.push_back(v2);
    vertices.push_back(v3);
    vertices.push_back(v4);
    vertices.push_back(v5);
    vertices.push_back(v6);
    vertices.push_back(v7);
}

std::vector<simd_float3> *Model::GetRenderVertices() {
    std::vector<simd_float3> *render_vertices = new std::vector<simd_float3>();
    
    for (std::size_t i = 0; i < faces.size(); i++) {
        render_vertices->push_back(faces.at(i)->vertices[0]->position);
        render_vertices->push_back(faces.at(i)->vertices[1]->position);
        render_vertices->push_back(faces.at(i)->vertices[2]->position);
    }
    return render_vertices;
}

std::vector<simd_float4> *Model::GetRenderColors() {
    std::vector<simd_float4> *color_vertices = new std::vector<simd_float4>();
    
    for (std::size_t i = 0; i < faces.size(); i++) {
        color_vertices->push_back(faces.at(i)->color);
    }
    
    return color_vertices;
}

Model::~Model() {
    for (std::size_t i = 0; i < faces.size(); i++) {
        delete faces.at(i);
    }
    
    for (std::size_t i = 0; i < vertices.size(); i++) {
        delete vertices.at(i);
    }
}
