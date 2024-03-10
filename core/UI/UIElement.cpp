//
//  UIElement.cpp
//  dragonfly
//
//  Created by Thomas Liang on 4/21/23.
//

#include "UIElement.h"

UIElement::UIElement() {
    
}

UIElement::~UIElement() {
    for (int i = 0; i < faces.size(); i++) {
        delete faces[i];
    }
}

int UIElement::MakeVertex(int x, int y, int z) {
    vertices.push_back(simd_make_int3(x, y, z));
    return vertices.size() - 1;
}

int UIElement::MakeFace(int v0, int v1, int v2, simd_float4 color) {
    UIFace *f = new UIFace();
    f->vertices[0] = v0;
    f->vertices[1] = v1;
    f->vertices[2] = v2;
    f->color = color;
    faces.push_back(f);
    
    return faces.size() - 1;
}

UIVertex *UIElement::GetVertex(int vid) {
    return &vertices.at(vid);
}

UIFace *UIElement::GetFace(int fid) {
    return faces.at(fid);
}

void UIElement::AddToBuffers(std::vector<UIFace> &faceBuffer, std::vector<UIVertex> &vertexBuffer) {
    face_start = faceBuffer.size();
    vertex_start = vertexBuffer.size();
    
    for (int i = 0; i < vertices.size(); i++) {
        vertexBuffer.push_back(vertices[i]);
    }
    
    for (int i = 0; i < faces.size(); i++) {
        UIFace f;
        UIFace *orig = faces[i];
        f.vertices[0] = orig->vertices[0]+vertex_start;
        f.vertices[1] = orig->vertices[1]+vertex_start;
        f.vertices[2] = orig->vertices[2]+vertex_start;
        f.color = orig->color;
        faceBuffer.push_back(f);
    }
}

uint32_t UIElement::ElementID() {
    return elementID;
}

unsigned long UIElement::FaceStart() {
    return face_start;
}

unsigned long UIElement::VertexStart() {
    return vertex_start;
}

unsigned long UIElement::NumFaces() {
    return faces.size();
}

unsigned long UIElement::NumVertices() {
    return vertices.size();
}
