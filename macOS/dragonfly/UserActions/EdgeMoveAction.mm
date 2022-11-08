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
    v1_initial_location_ = model_->GetVertex(vid1_);

    recording_ = true;
}

void EdgeMoveAction::EndRecording() {
    simd_float3 v = model_->GetVertex(vid1_);
    movement_vector_.x = v.x - v1_initial_location_.x;
    movement_vector_.y = v.y - v1_initial_location_.y;
    movement_vector_.z = v.z - v1_initial_location_.z;

    recording_ = false;
}

void EdgeMoveAction::Do() {
    model_->MoveVertex(vid1_, movement_vector_.x, movement_vector_.y, movement_vector_.z);
    model_->MoveVertex(vid2_, movement_vector_.x, movement_vector_.y, movement_vector_.z);
}

void EdgeMoveAction::Undo() {
    model_->MoveVertex(vid1_, -movement_vector_.x, -movement_vector_.y, -movement_vector_.z);
    model_->MoveVertex(vid2_, -movement_vector_.x, -movement_vector_.y, -movement_vector_.z);
}

EdgeMoveAction::~EdgeMoveAction () {
    
}
