//
//  VertexMoveAction.m
//  dragonfly
//
//  Created by Thomas Liang on 5/30/22.
//

#include "FaceAddVertexAction.h"


FaceAddVertexAction::FaceAddVertexAction(Model *m, int vid, int fid) : model_(m), vid_(vid), fid_(fid) {
    type_ = "Face Add Vertex Action";
}

simd_float3 FaceAddVertexAction::TriAvg (simd_float3 p1, simd_float3 p2, simd_float3 p3) {
    float x = (p1.x + p2.x + p3.x)/3;
    float y = (p1.y + p2.y + p3.y)/3;
    float z = (p1.z + p2.z + p3.z)/3;
    
    return simd_make_float3(x, y, z);
}

void FaceAddVertexAction::BeginRecording() {
    Face *f = model_->GetFace(fid_);
    original_vertices_[0] = f->vertices[0];
    original_vertices_[1] = f->vertices[1];
    original_vertices_[2] = f->vertices[2];
    
    recording_ = true;
}

void FaceAddVertexAction::EndRecording() {
    new_fid1_ = model_->NumFaces()-2;
    new_fid2_ = model_->NumFaces()-1;
    
    recording_ = false;
}

void FaceAddVertexAction::Do() {
    /*Face *f = model_->GetFace(fid_);
    unsigned vid1 = original_vertices_[0];
    unsigned vid2 = original_vertices_[1];
    unsigned vid3 = original_vertices_[2];
    simd_float3 *v1 = model_->GetVertex(vid1);
    simd_float3 *v2 = model_->GetVertex(vid2);
    simd_float3 *v3 = model_->GetVertex(vid3);
    
    simd_float3 new_v = TriAvg(*v1, *v2, *v3);
    model_->InsertVertex(new_v, vid_);
    
    //1,2,new
    f->vertices[2] = vid_;
    
    //2,3,new
    Face f2 = Face();
    f2.vertices[0] = vid1;
    f2.vertices[1] = vid2;
    f2.vertices[2] = vid_;
    f2.color = f->color;
    model_->InsertFace(f2, new_fid1_);
    
    //1,3,new
    Face f3 = Face();
    f3.vertices[0] = vid1;
    f3.vertices[1] = vid3;
    f3.vertices[2] = vid_;
    f3.color = f->color;
    model_->InsertFace(f3, new_fid2_);*/
}

void FaceAddVertexAction::Undo() {
    Face *f = model_->GetFace(fid_);
    
    model_->RemoveVertex(vid_);
    model_->RemoveFace(new_fid2_);
    model_->RemoveFace(new_fid1_);
    
    f->vertices[0] = original_vertices_[0];
    f->vertices[1] = original_vertices_[1];
    f->vertices[2] = original_vertices_[2];
}

FaceAddVertexAction::~FaceAddVertexAction () {
    
}
