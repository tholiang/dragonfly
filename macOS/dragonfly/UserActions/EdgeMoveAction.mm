//
//  VertexMoveAction.m
//  dragonfly
//
//  Created by Thomas Liang on 5/30/22.
//

#include "EdgeMoveAction.h"

EdgeMoveAction::EdgeMoveAction(Model *m, int vid1, int vid2) : model_(m), vid1_(vid1), vid2_(vid2) {
    type_ = "Edge Move Action";
}

void EdgeMoveAction::BeginRecording() {
    simd_float3 *v = model_->GetVertex(vid1_);
    v1_initial_location_.x = v->x;
    v1_initial_location_.y = v->y;
    v1_initial_location_.z = v->z;
    
    recording_ = true;
}

void EdgeMoveAction::EndRecording() {
    simd_float3 *v = model_->GetVertex(vid1_);
    movement_vector_.x = v->x - v1_initial_location_.x;
    movement_vector_.y = v->y - v1_initial_location_.y;
    movement_vector_.z = v->z - v1_initial_location_.z;
    
    recording_ = false;
}

void EdgeMoveAction::Do() {
    simd_float3 *v1 = model_->GetVertex(vid1_);
    simd_float3 *v2 = model_->GetVertex(vid2_);
    v1->x += movement_vector_.x;
    v1->y += movement_vector_.y;
    v1->z += movement_vector_.z;
    
    v2->x += movement_vector_.x;
    v2->y += movement_vector_.y;
    v2->z += movement_vector_.z;
}

void EdgeMoveAction::Undo() {
    simd_float3 *v1 = model_->GetVertex(vid1_);
    simd_float3 *v2 = model_->GetVertex(vid2_);
    v1->x -= movement_vector_.x;
    v1->y -= movement_vector_.y;
    v1->z -= movement_vector_.z;
    
    v2->x -= movement_vector_.x;
    v2->y -= movement_vector_.y;
    v2->z -= movement_vector_.z;
}

EdgeMoveAction::~EdgeMoveAction () {
    
}
