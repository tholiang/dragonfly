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
#include <string>

#include <simd/SIMD.h>

typedef simd_float3 Vertex;

// vertex locations relative to joints
// joint 0 is the default joint - at the center of the model
// joint locations relative to model's uniform

struct ModelUniforms {
    simd_float3 position;
    simd_float3 rotate_origin;
    simd_float3 angle; // euler angles zyx
};

struct Face {
    uint32_t vertices[3];
    simd_float4 color;
};

struct Node {
    simd_float3 pos;
    simd_float3 angle; // euler angles zyx
};

struct NodeVertexLink {
    int nid = -1;
    simd_float3 vector;
    float weight;
};

class Model {
private:
    std::vector<Face> faces;
    std::vector<Node> nodes;
    
    // two links per vertex - index = vertex index * 2 (+ 1)
    std::vector<NodeVertexLink> nvlinks;
    
    uint32_t modelID;
    
    unsigned long face_start = 0;
    unsigned long vertex_start = 0;
    
    unsigned long num_vertices = 0;
    
    unsigned long node_start = 0;
    
    simd_float3 RotateAround (simd_float3 point, simd_float3 origin, simd_float3 angle);
protected:
    std::string name;
public:
    Model(uint32_t mid);
    // to default node
    unsigned MakeVertex(float x, float y, float z);
    // to specified node
    unsigned MakeVertex(float x, float y, float z, unsigned nid);
    unsigned MakeFace(unsigned v0, unsigned v1, unsigned v2, simd_float4 color);
    
    unsigned MakeNode(float x, float y, float z);
    void LinkNodeAndVertex(unsigned long vid, unsigned long nid);
    void UnlinkNodeAndVertex(unsigned long vid, unsigned long nid);
    
    void DetermineLinkWeights(Vertex loc, unsigned long vid);
    
    void MakeCube();
    
    void InsertVertex(float x, float y, float z, int vid);
    void InsertFace(Face face, int fid);
    
    void MoveVertex(unsigned vid, float dx, float dy, float dz);
    
    void RemoveVertex(int vid);
    void RemoveFace(int fid);
    
    Vertex GetVertex(unsigned long vid);
    Face *GetFace(unsigned long fid);
    std::vector<unsigned long> GetEdgeFaces(unsigned long vid1, unsigned long vid2);
    
    std::vector<unsigned long> GetLinkedNodes(unsigned long vid);
    std::vector<unsigned long> GetLinkedVertices(unsigned long nid);
    
    Node *GetNode(unsigned long nid);
    
    //std::vector<Vertex> &GetVertices();
    std::vector<Face> &GetFaces();
    
    std::vector<Node> &GetNodes();
    
    void AddToBuffers(std::vector<Face> &faceBuffer, std::vector<Node> &nodeBuffer, std::vector<NodeVertexLink> &nvlinkBuffer, std::vector<uint32_t> &node_modelIDs, unsigned &total_vertices);
    void UpdateNodeBuffers(std::vector<Node> &nodeBuffer);
    uint32_t ModelID();
    
    unsigned long FaceStart();
    unsigned long VertexStart();
    
    unsigned long NodeStart();
    
    unsigned long NumFaces();
    unsigned long NumVertices();
    
    unsigned long NumNodes();
    
    std::string GetName();
    
    ~Model();
};

#endif /* Model_h */
