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
//    simd_float3 *v = model_->GetVertex(vid_);
//    initial_location_.x = v->x;
//    initial_location_.y = v->y;
//    initial_location_.z = v->z;
//
//    recording_ = true;
}

void VertexMoveAction::EndRecording() {
//    simd_float3 *v = model_->GetVertex(vid_);
//    movement_vector_.x = v->x - initial_location_.x;
//    movement_vector_.y = v->y - initial_location_.y;
//    movement_vector_.z = v->z - initial_location_.z;
//
//    recording_ = false;
}

void VertexMoveAction::Do() {
//    simd_float3 *v = model_->GetVertex(vid_);
//    v->x += movement_vector_.x;
//    v->y += movement_vector_.y;
//    v->z += movement_vector_.z;
}

void VertexMoveAction::Undo() {
//    simd_float3 *v = model_->GetVertex(vid_);
//    v->x -= movement_vector_.x;
//    v->y -= movement_vector_.y;
//    v->z -= movement_vector_.z;
}

VertexMoveAction::~VertexMoveAction () {
    
}
