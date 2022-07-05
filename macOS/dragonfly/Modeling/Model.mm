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
    face_start = 0;
    vertex_start = 0;
    num_vertices = 0;
    node_start = 0;
    
    Node node;
    node.pos = simd_make_float3(0, 0, 0);
    node.angle = simd_make_float3(0, 0, 0);
    nodes.push_back(node);
}

unsigned Model::MakeVertex(float x, float y, float z) {
    num_vertices++;
    
    NodeVertexLink nvlink;
    nvlink.nid = 0;
    nvlink.weight = 1;
    nvlink.vector.x = x;
    nvlink.vector.y = y;
    nvlink.vector.z = z;
    nvlinks.push_back(nvlink);
    nvlinks.push_back(NodeVertexLink()); // empty link
    
    return num_vertices-1;
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

unsigned Model::MakeNode(float x, float y, float z) {
    Node node;
    node.pos = simd_make_float3(x, y, z);
    node.angle = simd_make_float3(0, 0, 0);
    nodes.push_back(node);
    return nodes.size()-1;
}

void Model::LinkNodeAndVertex(unsigned long vid, unsigned long nid) {
    if (nid > nodes.size() || vid > num_vertices) {
        return;
    }
    
    Vertex vertex = GetVertex(vid);
    Node node = nodes.at(nid);
    
    NodeVertexLink link1 = nvlinks[vid*2];
    
    int setIndex = vid*2+1;
    
    if (link1.nid == -1) {
        setIndex = vid*2;
    }
    
    NodeVertexLink nvlink;
    nvlink.nid = nid;
    nvlink.vector.x = vertex.x - node.pos.x;
    nvlink.vector.y = vertex.y - node.pos.y;
    nvlink.vector.z = vertex.z- node.pos.z;
    
    simd_float3 reverse_angle = simd_make_float3(-node.angle.x, -node.angle.y, -node.angle.z);
    nvlink.vector = RotateAround(nvlink.vector, simd_make_float3(0, 0, 0), reverse_angle);
    nvlink.weight = 1;
    nvlinks[setIndex] = nvlink;
    
    DetermineLinkWeights(vertex, vid);
}

void Model::UnlinkNodeAndVertex(unsigned long vid, unsigned long nid) {
    Vertex v = GetVertex(vid);
    
    if (nvlinks[vid*2].nid == nid) {
        nvlinks[vid*2].nid = -1;
        DetermineLinkWeights(v, vid);
        return;
    } else if (nvlinks[vid*2 + 1].nid == nid) {
        nvlinks[vid*2 + 1].nid = -1;
        DetermineLinkWeights(v, vid);
        return;
    }
}

void Model::DetermineLinkWeights(Vertex loc, unsigned long vid) {
    std::vector<unsigned long> links;
    
    NodeVertexLink link1 = nvlinks.at(vid*2);
    NodeVertexLink link2 = nvlinks.at(vid*2 + 1);
    
    if (link1.nid == -1 && link2.nid == -1) {
        return;
    } else if (link1.nid == -1) {
        link2.weight = 1;
    } else if (link2.nid == -1) {
        link1.weight = 1;
    } else {
        float link1mag = sqrt(pow(link1.vector.x, 2) + pow(link1.vector.y, 2) + pow(link1.vector.z, 2));
        float link2mag = sqrt(pow(link2.vector.x, 2) + pow(link2.vector.y, 2) + pow(link2.vector.z, 2));
        
        float inverse_dist_sum = 1/link1mag + 1/link2mag;
        link1.weight = (1/link1mag) / inverse_dist_sum;
        link2.weight = (1/link2mag) / inverse_dist_sum;
    }
    
    nvlinks.at(vid*2) = link1;
    nvlinks.at(vid*2 + 1) = link2;
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

void Model::InsertVertex(float x, float y, float z, int vid) {
    if (vid >= num_vertices) {
        MakeVertex(x, y, z);
    } else {
        NodeVertexLink nvlink;
        num_vertices++;
        nvlink.nid = 0;
        nvlink.weight = 1;
        nvlink.vector.x = x;
        nvlink.vector.y = y;
        nvlink.vector.z = z;
        nvlinks.insert(nvlinks.begin()+vid*2, nvlink);
        nvlinks.insert(nvlinks.begin()+vid*2 + 1, NodeVertexLink());
    }
}

void Model::InsertFace(Face face, int fid) {
    if (fid >= faces.size()) {
        faces.push_back(face);
    } else {
        faces.insert(faces.begin()+fid, face);
    }
}

void Model::MoveVertex(unsigned vid, float dx, float dy, float dz) {
    nvlinks[vid*2].vector.x += dx;
    nvlinks[vid*2].vector.y += dy;
    nvlinks[vid*2].vector.z += dz;
    
    nvlinks[vid*2 + 1].vector.x += dx;
    nvlinks[vid*2 + 1].vector.y += dy;
    nvlinks[vid*2 + 1].vector.z += dz;
}

void Model::RemoveVertex(int vid) {
    nvlinks.erase(nvlinks.begin() + vid*2 + 1);
    nvlinks.erase(nvlinks.begin() + vid*2);
    num_vertices --;
}

void Model::RemoveFace(int fid) {
    if (fid < faces.size()) {
        faces.erase(faces.begin() + fid);
    }
}

Vertex Model::GetVertex(unsigned long vid) {
    Vertex ret = simd_make_float3(0, 0, 0);
    
    NodeVertexLink link1 = nvlinks[vid*2];
    NodeVertexLink link2 = nvlinks[vid*2 + 1];
    
    if (link1.nid != -1) {
        Node n = nodes[link1.nid];
        
        Vertex desired1 = simd_make_float3(n.pos.x + link1.vector.x, n.pos.y + link1.vector.y, n.pos.z + link1.vector.z);
        desired1 = RotateAround(desired1, n.pos, n.angle);
        
        ret.x += link1.weight*desired1.x;
        ret.y += link1.weight*desired1.y;
        ret.z += link1.weight*desired1.z;
    }
    
    if (link2.nid != -1) {
        Node n = nodes[link2.nid];
        
        Vertex desired2 = simd_make_float3(n.pos.x + link2.vector.x, n.pos.y + link2.vector.y, n.pos.z + link2.vector.z);
        desired2 = RotateAround(desired2, n.pos, n.angle);
        
        ret.x += link2.weight*desired2.x;
        ret.y += link2.weight*desired2.y;
        ret.z += link2.weight*desired2.z;
    }
    
    return ret;
}

Face *Model::GetFace(unsigned long fid) {
    return &faces.at(fid);
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


std::vector<unsigned long> Model::GetLinkedNodes(unsigned long vid) {
    std::vector<unsigned long> ret;
    
    NodeVertexLink link1 = nvlinks[vid*2];
    NodeVertexLink link2 = nvlinks[vid*2 + 1];
    
    if (link1.nid != -1) {
        ret.push_back(link1.nid);
    }
    
    if (link2.nid != -1) {
        ret.push_back(link2.nid);
    }
    
    return ret;
}

std::vector<unsigned long> Model::GetLinkedVertices(unsigned long nid) {
    std::vector<unsigned long> ret;
    for (int i = 0; i < nvlinks.size(); i++) {
        if (nvlinks[i].nid == nid) {
            ret.push_back(i/2);
        }
    }
    
    return ret;
}

Node *Model::GetNode(unsigned long nid) {
    return &nodes.at(nid);
}

std::vector<Face> &Model::GetFaces() {
    return faces;
}

std::vector<Node> &Model::GetNodes() {
    return nodes;
}

void Model::AddToBuffers(std::vector<Face> &faceBuffer, std::vector<Node> &nodeBuffer, std::vector<NodeVertexLink> &nvlinkBuffer, std::vector<uint32_t> &node_modelIDs, unsigned &total_vertices) {
    face_start = faceBuffer.size();
    vertex_start = total_vertices;
    
    total_vertices += num_vertices;
    
    for (int i = 0; i < faces.size(); i++) {
        Face og = faces[i];
        Face face;
        face.color = og.color;
        face.vertices[0] = og.vertices[0]+vertex_start;
        face.vertices[1] = og.vertices[1]+vertex_start;
        face.vertices[2] = og.vertices[2]+vertex_start;
        faceBuffer.push_back(face);
    }
    
    node_start = nodeBuffer.size();
    
    for (int i = 0; i < nodes.size(); i++) {
        nodeBuffer.push_back(nodes[i]);
        node_modelIDs.push_back(modelID);
    }
    
    for (int i = 0; i < nvlinks.size(); i++) {
        NodeVertexLink og = nvlinks[i];
        NodeVertexLink nvlink;
        if (og.nid != -1) {
            nvlink.nid = og.nid + node_start;
        }
        nvlink.vector = og.vector;
        nvlink.weight = og.weight;
        nvlinkBuffer.push_back(nvlink);
    }
}

void Model::UpdateNodeBuffers(std::vector<Node> &nodeBuffer) {
    for (int i = 0; i < nodes.size(); i++) {
        Node *node = &nodeBuffer.at(i+node_start);
        node->pos.x = nodes[i].pos.x;
        node->pos.y = nodes[i].pos.y;
        node->pos.z = nodes[i].pos.z;
        node->angle.x = nodes[i].angle.x;
        node->angle.y = nodes[i].angle.y;
        node->angle.z = nodes[i].angle.z;
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

unsigned long Model::NodeStart() {
    return node_start;
}

unsigned long Model::NumFaces() {
    return faces.size();
}

unsigned long Model::NumVertices() {
    return num_vertices;
}

unsigned long Model::NumNodes() {
    return nodes.size();
}

std::string Model::GetName() {
    return name;
}

Model::~Model() {
}

simd_float3 Model::RotateAround (simd_float3 point, simd_float3 origin, simd_float3 angle) {
    simd_float3 vec;
    vec.x = point.x-origin.x;
    vec.y = point.y-origin.y;
    vec.z = point.z-origin.z;
    
    simd_float3 newvec;
    
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
