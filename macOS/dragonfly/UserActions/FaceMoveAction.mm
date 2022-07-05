//
//  VertexMoveAction.m
//  dragonfly
//
//  Created by Thomas Liang on 5/30/22.
//

#include "FaceMoveAction.h"

FaceMoveAction::FaceMoveAction(Model *m, int fid) : model_(m), fid_(fid) {
    type_ = "Face Move Action";
}

void FaceMoveAction::BeginRecording() {
//    Face *f = model_->GetFace(fid_);
//    simd_float3 *v1 = model_->GetVertex(f->vertices[0]);
//    v1_initial_location_.x = v1->x;
//    v1_initial_location_.y = v1->y;
//    v1_initial_location_.z = v1->z;
//
//    recording_ = true;
}

void FaceMoveAction::EndRecording() {
//    Face *f = model_->GetFace(fid_);
//    simd_float3 *v1 = model_->GetVertex(f->vertices[0]);
//    movement_vector_.x = v1->x - v1_initial_location_.x;
//    movement_vector_.y = v1->y - v1_initial_location_.y;
//    movement_vector_.z = v1->z - v1_initial_location_.z;
//
//    recording_ = false;
}

void FaceMoveAction::Do() {
//    Face *f = model_->GetFace(fid_);
//    simd_float3 *v1 = model_->GetVertex(f->vertices[0]);
//    simd_float3 *v2 = model_->GetVertex(f->vertices[1]);
//    simd_float3 *v3 = model_->GetVertex(f->vertices[2]);
//    v1->x += movement_vector_.x;
//    v1->y += movement_vector_.y;
//    v1->z += movement_vector_.z;
//
//    v2->x += movement_vector_.x;
//    v2->y += movement_vector_.y;
//    v2->z += movement_vector_.z;
//
//    v3->x += movement_vector_.x;
//    v3->y += movement_vector_.y;
//    v3->z += movement_vector_.z;
}

void FaceMoveAction::Undo() {
//    Face *f = model_->GetFace(fid_);
//    simd_float3 *v1 = model_->GetVertex(f->vertices[0]);
//    simd_float3 *v2 = model_->GetVertex(f->vertices[1]);
//    simd_float3 *v3 = model_->GetVertex(f->vertices[2]);
//    v1->x -= movement_vector_.x;
//    v1->y -= movement_vector_.y;
//    v1->z -= movement_vector_.z;
//    
//    v2->x -= movement_vector_.x;
//    v2->y -= movement_vector_.y;
//    v2->z -= movement_vector_.z;
//    
//    v3->x -= movement_vector_.x;
//    v3->y -= movement_vector_.y;
//    v3->z -= movement_vector_.z;
}

FaceMoveAction::~FaceMoveAction () {
    
}
