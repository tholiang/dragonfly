//
//  VertexMoveAction.m
//  dragonfly
//
//  Created by Thomas Liang on 5/30/22.
//

#include "VertexMoveAction.h"

VertexMoveAction::VertexMoveAction(Model *m, int vid) : model_(m), vid_(vid) {
    type_ = "Vertex Move Action";
}

void VertexMoveAction::BeginRecording() {
    initial_location_ = model_->GetVertex(vid_);

    recording_ = true;
}

void VertexMoveAction::EndRecording() {
    simd_float3 v = model_->GetVertex(vid_);
    movement_vector_.x = v.x - initial_location_.x;
    movement_vector_.y = v.y - initial_location_.y;
    movement_vector_.z = v.z - initial_location_.z;

    recording_ = false;
}

void VertexMoveAction::Do() {
    model_->MoveVertex(vid_, movement_vector_.x, movement_vector_.y, movement_vector_.z);
}

void VertexMoveAction::Undo() {
    model_->MoveVertex(vid_, -movement_vector_.x, -movement_vector_.y, -movement_vector_.z);
}

VertexMoveAction::~VertexMoveAction () {
    
}
